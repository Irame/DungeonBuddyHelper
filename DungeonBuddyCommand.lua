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
function private:GetPlayerRole()
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
function private:GetMissingRoles()
    if IsInRaid(LE_PARTY_CATEGORY_HOME) then
        return ""
    end

    local missingRoles = {"t", "h", "d", "d", "d"}

    -- Loop through all group members
    for unit in private:IterPartyMembers() do
        local role
        if unit == "player" then
            role = private:GetPlayerRole()
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
        return "lfg-m10-m11"
    end
end

local function NOP() end

---Checks if the key level is supported by the DungeonBuddy bot
---@param keyInfo KeystoneInfo The info of the keystone
function private:IsKeySupportedByDungeonBuddy(keyInfo)
    return keyInfo and keyInfo.level < 12
end

---@enum RunType
private.Enum.RunType = {
    TimeButComplete = "tbc",
    TimeOrAbandon = "toa",
    VaultCompletion = "vc",
}

---Generates a command string for the DungeonBuddy on the No Pressure Discord
---@param info KeystoneInfo The info of the keystone
---@param runType RunType The type of the run
---@param missingRoles string The roles that are missing to form a dungeon group
function private:GenerateCommand(info, runType, missingRoles)
    return string.format("/lfgquick quick_dungeon_string:%s %d%s %s %s", info.dungeonShorthand, info.level, runType, private:GetPlayerRole(), missingRoles)
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
    local insertedFrame = _G["DBH_PopupInsertedFrame"]
    insertedFrame:Show();

    local popupTextTemplate = L["Select key and playstyle and copy'n'paste the command in the '%s' NoP discord channel."]
    local notSupportedKeyLevelText = L["The DungeonBuddy bot only supports dungeons below level 12. Please use the 'Boiler Room' to look for people manually."]
    StaticPopupDialogs["SHOW_DB_COMMAND"] = StaticPopupDialogs["SHOW_DB_COMMAND"] or {
        text = popupTextTemplate,
        button1 = OKAY,
        OnShow = function(this, ...)
            this.insertedFrame.OnChanged = function(keyInfo, runType)
                this.data = keyInfo
                if private.db.global.openLfgFrame == private.Enum.OpenLfgFrame.OnDialog then
                    private:ShowLFGFrameWithEntryCreationForActivity(keyInfo, runType)
                end

                if private:IsKeySupportedByDungeonBuddy(keyInfo) then
                    this:GetTextFontString():SetFormattedText(popupTextTemplate, KeyLevelToDiscordChannel(keyInfo.level))
                else
                    this:GetTextFontString():SetText("|cffff3636" .. notSupportedKeyLevelText .. "|r")
                end
            end

            this.insertedFrame:Initialize(this.data)
        end,
        OnHide = function(this, ...)
            this.insertedFrame.OnChanged = nil
            this.insertedFrame:Hide();
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
        OnCancel = function(this, ...)
            this.insertedFrame.OnChanged = nil
            this.insertedFrame:Hide();
        end,
        timeout = 0,
        whileDead = 1,
        hideOnEscape = 1,
        editBoxWidth = 285,
    }

    StaticPopup_Show("SHOW_DB_COMMAND", KeyLevelToDiscordChannel(info.level), nil, info, insertedFrame)
end
