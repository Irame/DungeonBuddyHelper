---@class DBH_Private
local private = select(2, ...)

local L = private.L

---Convert a role to the single char format
---@param role "TANK" | "HEALER" | "DAMAGER" | "NONE"
---@return "t" | "h" | "d" | ""
local function GetShortRole(role)
    -- Convert role to the appropriate letter
    if role == "TANK" then
        return "t"
    elseif role == "HEALER" then
        return "h"
    elseif role == "DAMAGER" then
        return "d"
    else
        return ""
    end
end

---Gets the player role in the single char format
---@return "t" | "h" | "d" | ""
local function GetPlayerRole()
    local role
    if IsInGroup(LE_PARTY_CATEGORY_HOME) then
        role = UnitGroupRolesAssigned("player")
    else
        role = GetSpecializationRole(GetSpecialization())
    end
    return GetShortRole(role)
end

--- Function to get the roles that are missing to form a dungeon group
---@return string
local function GetMissingRoles()
    if IsInRaid(LE_PARTY_CATEGORY_HOME) then
        return ""
    end

    local missingRoles = {"t", "h", "d", "d", "d"}

    -- Loop through all group members
    for unit in private:IterPartyMembers() do
        local role
        if unit == "player" then
            role = GetPlayerRole()
        else
            role = GetShortRole(UnitGroupRolesAssigned(unit))
        end

        for j, r in ipairs(missingRoles) do
            if r == role then
                tremove(missingRoles, j)
                break
            end
        end
    end

    return table.concat(missingRoles, "")
end

---Returns the No Pressure Discord channel apropriate for the key level
---@param level integer
---@return string
local function KeyLevelToDiscordChannel(level)
    if level <= 3 then
        return "lfg-m2-m3"
    elseif level <= 6 then
        return "lfg-m4-m6"
    elseif level <= 9 then
        return "lfg-m7-m9"
    else
        return "lfg-m10"
    end
end

local function NOP() end

---Generates a command string for the DungeonBuddy on the No Pressure Discord
---@param info KeystoneInfo The info of the keystone
function private:GenerateCommand(info, completion)
    return string.format("/lfgquick quick_dungeon_string:%s %d%s %s %s", info.dungeonShorthand, info.level, completion and "c" or "t", GetPlayerRole(), GetMissingRoles())
end

private.Enum.OpenLfgFrame = {
    Never = 0,
    OnDialog = 1,
    OnOkay = 2,
}

---Creates a command used by the DungeonBuddy on the No Pressure Discord
---and shows a popup to the player where they can copy it
---@param info KeystoneInfo The info of the keystone
function private:ShowDungeonBuddyCommandToPlayer(info)
    local popupTextTemplate = L["Select key and playstyle and copy'n'paste the command in the '%s' NoP discord channel."]
    StaticPopupDialogs["SHOW_DB_COMMAND"] = StaticPopupDialogs["SHOW_DB_COMMAND"] or {
        text = popupTextTemplate,
        button1 = OKAY,
        OnShow = function(this, ...)
            local updateText = function(keyInfo)
                this.text:SetFormattedText(popupTextTemplate, KeyLevelToDiscordChannel(keyInfo.level))
            end

            this.insertedFrame.OnChanged = function(keyInfo, completion)
                this.data = keyInfo
                if private.db.global.openLfgFrame == private.Enum.OpenLfgFrame.OnDialog then
                    private:ShowLFGFrameWithEntryCreationForActivity(keyInfo, completion)
                end
                updateText(keyInfo)
            end

            this.insertedFrame:Initialize(this.data)
        end,
        OnHide = function(this, ...)
            this.insertedFrame.OnChanged = nil
        end,
        OnAccept = function(this, ...)
            if private.db.global.openLfgFrame == private.Enum.OpenLfgFrame.OnOkay then
                private:ShowLFGFrameWithEntryCreationForActivity(this.data, this.insertedFrame:IsCompletionChecked())
            end
            if LFGListFrame.EntryCreation.Name:IsVisible() and this.data then
                local helpTipInfo = {
                    text = L["Enter the name you listed you group as in the NoP discord (e.g. NoP %s XX)"]:format(strupper(this.data.dungeonShorthand)),
                    buttonStyle = HelpTip.ButtonStyle.Close,
                    targetPoint = HelpTip.Point.RightEdgeCenter,
                }

                HelpTip:Show(LFGListFrame.EntryCreation.Name, helpTipInfo, LFGListFrame.EntryCreation.Name)
            end
        end,
        OnCancel = NOP,
        timeout = 0,
        whileDead = 1,
        hideOnEscape = 1
    }

    StaticPopup_Show("SHOW_DB_COMMAND", KeyLevelToDiscordChannel(info.level), nil, info, _G["DBH_PopupInsertedFrame"])
end
