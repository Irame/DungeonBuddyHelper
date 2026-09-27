local private = select(2, ...)

-- LibKeystone (BigWigs) uses LibKS: R requests a reply; replies are level,map,rating.
-- Chat-only providers are handled separately; their messages may contain alts.
local keys = {}
local lifetime = 1800

local function IsPublicString(value)
    return not (issecretvalue and issecretvalue(value)) and type(value) == "string"
end

local function FullName(name)
    if not IsPublicString(name) then return end
    if not name:find("-", 1, true) then
        name = name .. "-" .. GetNormalizedRealmName()
    end
    return name:gsub("%s", "")
end

function private:FindPartyKeyOwner(sender)
    if not IsInGroup(LE_PARTY_CATEGORY_HOME) or IsInRaid(LE_PARTY_CATEGORY_HOME) then return end
    local owner = FullName(sender)
    if not owner then return end
    for unit in self:IterPartyMembers() do
        if unit ~= "player" and UnitExists(unit) and FullName(GetUnitName(unit, true)) == owner then
            return owner, unit
        end
    end
end

function private:GetSharedPartyKey(unit)
    local entry = keys[FullName(GetUnitName(unit, true))]
    if entry and GetTime() - entry.received < lifetime then
        return entry
    end
end

function private:StorePartyKey(sender, map, level, source)
    local owner = self:FindPartyKeyOwner(sender)
    if not owner or type(map) ~= "number" or type(level) ~= "number"
        or map < 0 or level < 0 or map % 1 ~= 0 or level % 1 ~= 0 then return end
    -- Keep explicit no-key responses too, so an old provider cache cannot revive a key.
    keys[owner] = { challengeMapID = map, level = level, source = source, received = GetTime() }
    self:NotifyPartyKeysChanged()
end

function private:NotifyPartyKeysChanged()
    local popup = _G.DBH_PopupInsertedFrame
    if popup and popup:IsShown() then
        popup:UpdateKeyDropdown(popup.selectedKeyInfo)
        popup:InvokeOnChanged()
    end
    local addon = self.addon
    if addon.WaitingForKeyUpdate and self:IterPartyKeys()() then
        addon.WaitingForKeyUpdate = false
        addon:ShowLFGFrameAndDiscordCommand()
    end
end

function private:ReceiveLibKeystone(prefix, message, channel, sender)
    if not IsPublicString(prefix) or not IsPublicString(message) or not IsPublicString(channel)
        or prefix ~= "LibKS" or channel ~= "PARTY" or #message > 100 then return end
    local level, map = message:match("^(%d+),(%d+),%d+$")
    if level then
        self:StorePartyKey(sender, tonumber(map), tonumber(level), "LibKeystone")
    end
end

function private:ReceivePartyKeyLink(message, sender)
    if not IsPublicString(message) or not self:FindPartyKeyOwner(sender) then return end
    -- Only one key, explicitly identified as the sender's current character.
    -- AlterEgo's compact/unnamed multi-alt output is deliberately not attributed.
    local start = message:find("|Hkeystone:", 1, true)
    if not start or message:find("|Hkeystone:", start + 1, true) then return end
    local label = message:sub(1, start - 1):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    label = label:match("^%s*(.-)%s*$")
    local source
    if label == "[KeystoneLoot]:" then
        source = "KeystoneLoot"
    else
        local character = label:match("^([^:]+):$")
        local _, unit = self:FindPartyKeyOwner(sender)
        local shortName = GetUnitName(unit, true):match("^[^-]+")
        if not character or (character ~= shortName and FullName(character) ~= FullName(sender)) then return end
        source = "Named link"
    end
    local info = self:GetKeystoneInfoForLink(message:sub(start))
    if info then
        self:StorePartyKey(sender, info.challengeMapID, info.level, source)
    end
end

function private:PrunePartyKeys()
    for owner in pairs(keys) do
        if not self:FindPartyKeyOwner(owner) then keys[owner] = nil end
    end
end

-- This sends a visible message only from the explicit button/slash command.
function private:RequestPartyKeysInChat()
    if not IsInGroup(LE_PARTY_CATEGORY_HOME) or IsInRaid(LE_PARTY_CATEGORY_HOME) then
        self.addon:Print(self.L["Join a party before requesting keys in chat."])
        return
    end
    local now = GetTime()
    if self.lastChatKeyRequest and now - self.lastChatKeyRequest < 10 then return end
    self.lastChatKeyRequest = now
    self:RequestPartyKeys()
    C_ChatInfo.SendChatMessage("!keys", "PARTY")
end

function private:InitializePartyKeystones()
    local frame = CreateFrame("Frame")
    self.partyKeystoneFrame = frame
    C_ChatInfo.RegisterAddonMessagePrefix("LibKS")
    frame:RegisterEvent("CHAT_MSG_ADDON")
    frame:RegisterEvent("CHAT_MSG_PARTY")
    frame:RegisterEvent("CHAT_MSG_PARTY_LEADER")
    frame:RegisterEvent("GROUP_ROSTER_UPDATE")
    frame:SetScript("OnEvent", function(_, event, ...)
        if event == "CHAT_MSG_ADDON" then
            self:ReceiveLibKeystone(...)
        elseif event == "GROUP_ROSTER_UPDATE" then
            self:PrunePartyKeys()
            self:RequestPartyKeys()
        else
            self:ReceivePartyKeyLink(...)
        end
    end)
end
