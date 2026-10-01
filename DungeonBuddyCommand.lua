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

local KeyLevelPartitions = {3, 6, 9, 11, 13, 16}
local DungeonBuddyMaxKeyLevel = 13

---@class NopKeyLevelInfo
---@field minLevel integer
---@field maxLevel? integer
---@field supportedByDungeonBuddy boolean

---Returns information about the No Pressure Discord key level categories
---@param level integer
---@return NopKeyLevelInfo
local function GetNopKeyLevelInfo(level)
    for i, maxLevel in ipairs(KeyLevelPartitions) do
        if level <= maxLevel then
            return {
                minLevel = (i == 1) and 2 or (KeyLevelPartitions[i - 1] + 1),
                maxLevel = maxLevel,
                supportedByDungeonBuddy = level <= DungeonBuddyMaxKeyLevel,
            }
        end
    end

    return {
        minLevel = KeyLevelPartitions[#KeyLevelPartitions] + 1,
        supportedByDungeonBuddy = false,
    }
end

---Returns the No Pressure Discord channel apropriate for the key level
---@param levelInfo NopKeyLevelInfo
---@return string
local function KeyLevelInfoToDiscordChannel(levelInfo)
    if levelInfo.maxLevel then
        return ("lfg-m%d-m%d"):format(levelInfo.minLevel, levelInfo.maxLevel)
    else
        return ("lfg-m%d-and-up"):format(levelInfo.minLevel)
    end
end

---Checks if the key level is supported by the DungeonBuddy bot
---@param keyInfo KeystoneInfo The info of the keystone
function private:IsKeySupportedByDungeonBuddy(keyInfo)
    return keyInfo and keyInfo.level <= DungeonBuddyMaxKeyLevel
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
---@param groupName? string The optional name of the group
---@return string command The lfgquick command for the dungeon buddy
function private:GenerateDungeonBuddyCommand(info, runType, missingRoles, groupName)
    local command = string.format("/lfgquick quick_dungeon_string:%s %d%s %s %s", info.dungeonShorthand, info.level, runType, private:GetPlayerRole(), missingRoles)
    if groupName and groupName ~= "" then
        command = command .. " listed_as:" .. groupName
    end
    return command
end

--- Generates a text to mention the missing roles in a Discord message
--- eg. @Tank-M12-14, 2 @DPS-M12-14 or @Tank-M15+, @Healer-M15+, @DPS-M15+
---@param keyInfo KeystoneInfo
---@param missingRoles string
---@return string
local function GenerateDiscordRolesText(keyInfo, missingRoles)
    local keyLevelInfo = GetNopKeyLevelInfo(keyInfo.level)
    local levelRange
    if keyLevelInfo.maxLevel then
        levelRange = string.format("%d-%d", keyLevelInfo.minLevel, keyLevelInfo.maxLevel)
    else
        levelRange = string.format("%d+", keyLevelInfo.minLevel)
    end

    local roleCounts = { t = 0, h = 0, d = 0 }
    for i = 1, #missingRoles do
        local role = missingRoles:sub(i, i)
        if roleCounts[role] then
            roleCounts[role] = roleCounts[role] + 1
        end
    end

    local roleOrder = { "t", "h", "d" }

    local mentions = {}
    for _, role in ipairs(roleOrder) do
        local count = roleCounts[role]
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

--- Checks if your party/raid has at least one class (or pet) with a Lust-like ability
---@param ignoreHunters boolean
---@return boolean
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

--- Checks if your party/raid has at least one combat resurrection provider
---@param ignoreHunters boolean
---@return boolean
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

---@param keyInfo KeystoneInfo
---@return string
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

local discordRunTypeNames = {
    [private.Enum.RunType.TimeButComplete] = "Time but complete",
    [private.Enum.RunType.TimeOrAbandon] = "Time or abandon",
    [private.Enum.RunType.VaultCompletion] = "Vault completion",
}

---@param info KeystoneInfo
---@param runType RunType
---@param missingRoles string
---@param randomSeed number
---@return string
function private:GenerateBoilerRoomText(info, runType, missingRoles, randomSeed, groupName)
    local runTypeText = discordRunTypeNames[runType] or discordRunTypeNames[private.Enum.RunType.TimeButComplete]
    local dungeonShorthand = strupper(info.dungeonShorthand)
    local password = self:GeneratePassphrase(3, randomSeed)
    local missingRolesMentions = GenerateDiscordRolesText(info, missingRoles)
    local specificRequirements = GenerateSpecificRequirementsText(info)

    if not groupName then
        local groupPostfix = self:GenerateRandomUppercaseString(3, randomSeed)
        groupName = string.format("NOP %s %s", dungeonShorthand, groupPostfix)
    end

    return string.format([[
- `Group Name:` %s
- `Dungeon & difficulty:` %s +%d
- `Timing expectations:` %s
- `Looking for:` %s
- `Specific Requirements:` %s
- `Password:` %s]],
        groupName,
        dungeonShorthand, info.level,
        runTypeText,
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
---@param info KeystoneInfo The info of the keystone (no OwnedKeystoneInfo should be passed here)
function private:ShowDungeonBuddyCommandToPlayer(info)
    local insertedFrame = _G["DBH_PopupInsertedFrame"]
    insertedFrame:Show();

    local dungeonBuddyTextTemplate = L["Select key and playstyle and copy'n'paste the command in the '%s' NoP discord channel."]
    local boilerRoomTextTemplate = "|cffff3636" .. L["The DungeonBuddy bot only supports dungeons below level %d."] .. "|r\n"
        .. L["Please use the chat message below to look for people manually in the 'Boiler Room' channel %s."]

    StaticPopupDialogs["SHOW_DB_COMMAND"] = StaticPopupDialogs["SHOW_DB_COMMAND"] or {
        text = L["No party keys available. Refresh or paste a keystone link with /dbh."],
        button1 = OKAY,
        OnShow = function(this, ...)
            this.insertedFrame.OnChanged = function(keyInfo, runType)
                this.data.keyInfo = keyInfo
                this.data.runType = runType
                local text = this:GetTextFontString()
                if keyInfo then
                    this.insertedFrame:Show()
                    if private.db.global.general.openLfgFrame == private.Enum.OpenLfgFrame.OnDialog then
                        private:ShowLFGFrameWithEntryCreationForActivity(keyInfo, runType)
                    end

                    local nopKeyLevelInfo = GetNopKeyLevelInfo(keyInfo.level)
                    if nopKeyLevelInfo.supportedByDungeonBuddy then
                        text:SetFormattedText(dungeonBuddyTextTemplate, KeyLevelInfoToDiscordChannel(nopKeyLevelInfo))
                    else
                        text:SetFormattedText(boilerRoomTextTemplate, DungeonBuddyMaxKeyLevel+1, KeyLevelInfoToDiscordChannel(nopKeyLevelInfo))
                    end
                else
                    text:SetText("|cffff3636" .. L["No party keys available. Refresh or paste a keystone link with /dbh."] .. "|r")
                end
            end

            this.insertedFrame:Initialize(this.data.keyInfo)
        end,
        OnHide = function(this, ...)
            -- Reusing a StaticPopup hides it and releases insertedFrame before
            -- calling OnCancel. Keep cleanup here, while the frame is attached.
            if this.insertedFrame then
                this.insertedFrame.OnChanged = nil
                this.insertedFrame:Hide();
            end
        end,
        OnAccept = function(this, ...)
            if this.data.keyInfo then
                if private.db.global.general.openLfgFrame == private.Enum.OpenLfgFrame.OnOkay then
                    private:ShowLFGFrameWithEntryCreationForActivity(this.data.keyInfo, this.data.runType)
                end
                if LFGListFrame.EntryCreation.Name:IsVisible() then
                    local groupName = private:GetCustomGroupName()
                    local helpText
                    if groupName then
                        helpText = L['Enter the name of you group "%s" here']:format(groupName)
                    else
                        helpText = L["Enter the name you listed you group as in the NoP discord (e.g. NoP %s XX)"]:format(strupper(this.data.keyInfo.dungeonShorthand))
                    end
                    local helpTipInfo = {
                        text = helpText,
                        buttonStyle = HelpTip.ButtonStyle.Close,
                        targetPoint = HelpTip.Point.RightEdgeCenter,
                    }

                    HelpTip:Show(LFGListFrame.EntryCreation.Name, helpTipInfo, LFGListFrame.EntryCreation.Name)
                    LFGListFrame.EntryCreation.Name:SetFocus()
                end
            end
        end,
        timeout = 0,
        whileDead = 1,
        hideOnEscape = 1,
        editBoxWidth = 285,
    }

    local data = {
        keyInfo = info
    }

    StaticPopup_Show("SHOW_DB_COMMAND", nil, nil, data, insertedFrame)
end
