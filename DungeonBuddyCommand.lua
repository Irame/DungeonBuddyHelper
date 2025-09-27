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
function private:GenerateDungeonBuddyCommand(info, runType, missingRoles)
    return string.format("/lfgquick quick_dungeon_string:%s %d%s %s %s", info.dungeonShorthand, info.level, runType, private:GetPlayerRole(), missingRoles)
end

--- Generates a text to mention the missing roles in a Discord message
--- eg. @Tank-M12-14, 2 @DPS-M12-14 or @Tank-M15+, @Healer-M15+, @DPS-M15+
local function GenerateDiscordRolesText(keyInfo, missingRoles)
    local levelRange
    if keyInfo.level >= 15 then
        levelRange = "15+"
    elseif keyInfo.level >= 12 then
        levelRange = "12-14"
    else
        return ""
    end

    local roleCounts = { t = 0, h = 0, d = 0 }
    for i = 1, #missingRoles do
        local role = missingRoles:sub(i, i)
        if roleCounts[role] then
            roleCounts[role] = roleCounts[role] + 1
        end
    end

    local mentions = {}
    for role, count in pairs(roleCounts) do
        if count > 0 then
            local roleName = (role == "t" and "Tank") or (role == "h" and "Healer") or (role == "d" and "DPS")
            if count > 1 then
                table.insert(mentions, string.format("%d @%s-M%s", count, roleName, levelRange))
            else
                table.insert(mentions, string.format("@%s-M%s", roleName, levelRange))
            end
        end
    end

    return table.concat(mentions, ", ")
end

-- Checks if your party/raid has at least one class (or pet) with a Lust-like ability
local function PartyHasBloodlust(ignoreHunters)
    local lustClasses = {
        ["SHAMAN"] = true,
        ["MAGE"] = true,
        ["EVOKER"] = true,
        ["HUNTER"] = not ignoreHunters,
    }

    for unit in private:IterPartyMembers() do
        local _, class = UnitClass(unit)
        if lustClasses[class] then
            return true
        end
    end

    return false
end

-- Checks if your party/raid has at least one combat resurrection provider
function PartyHasCombatRes(ignoreHunters)
    local brezClasses = {
        ["DRUID"] = true,
        ["WARLOCK"] = true,
        ["DEATHKNIGHT"] = true,
        ["PALADIN"] = true,
        ["HUNTER"] = not ignoreHunters,
    }

    for unit in private:IterPartyMembers() do
        local _, class = UnitClass(unit)
        if brezClasses[class] then
            return true
        end
    end

    return false
end

local function GenerateSpecificRequirementsText(keyInfo)
    local cfg = private.db.global.boilerRoom.specificRequirements

    if not cfg.enabled then
        return ""
    end

    local requirements = {}

    if cfg.bloodlust.include and not PartyHasBloodlust(cfg.bloodlust.ignoreHunters) then
        table.insert(requirements, "Need BL")
    end

    if cfg.combatRes.include and not PartyHasCombatRes(cfg.combatRes.ignoreHunters) then
        table.insert(requirements, "Need CR")
    end

    if cfg.keyCompletion.include then
        table.insert(requirements, ("Have it timed on +%d"):format(keyInfo.level - cfg.keyCompletion.keyOffset))
    end

    return table.concat(requirements, ", ")
end

function private:GenerateBoilerRoolText(info, runType, missingRoles)
    local runTypeLong = "TimeButComplete"
    for key, value in pairs(private.Enum.RunType) do
        if value == runType then
            runTypeLong = key
            break
        end
    end

    local groupPostfix = self:GenerateRandomUppercaseString(3)
    local dungeonShorthand = strupper(info.dungeonShorthand)
    local password = self:GeneratePassphrase(3)
    local missingRolesMentions = GenerateDiscordRolesText(info, missingRoles)
    local specificRequirements = GenerateSpecificRequirementsText(info)

    return string.format([[
- `Group Name:` NOP %s %s
- `Dungeon & difficulty:` %s +%d
- `Timing expectations:` %s
- `Looking for:` %s
- `Specific Requirements:` %s
- `Password:` %s]],
        dungeonShorthand, groupPostfix,
        dungeonShorthand, info.level,
        runTypeLong,
        missingRolesMentions,
        specificRequirements,
        password)
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
                if private.db.global.general.openLfgFrame == private.Enum.OpenLfgFrame.OnDialog then
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
            if private.db.global.general.openLfgFrame == private.Enum.OpenLfgFrame.OnOkay then
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
