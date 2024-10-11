---@class DBH_Private
local private = select(2, ...)

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
        role = UnitGroupRolesAssigned("plyer")
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

    -- Get the size of the group
    local groupSize = GetNumGroupMembers()

    -- Loop through all group members
    for i = 0, groupSize do
        local role
        if i == 0 then
            role = GetPlayerRole()
        else
            role = GetShortRole(UnitGroupRolesAssigned("party"..i))
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

local function StaticPopupCommand(command, discordChannel)
    StaticPopupDialogs["SHOW_DB_COMMAND"] = StaticPopupDialogs["SHOW_DB_COMMAND"] or {
        text = "Copy the following command and paste it in the '%s' NoP discord channel:",
        button2 = ACCEPT,
        hasEditBox = 1,
        hasWideEditBox = 1,
        editBoxWidth = 180,
        preferredIndex = 3,
        OnShow = function(this, ...)
            local editBox = _G[this:GetName() .. "WideEditBox"] or _G[this:GetName() .. "EditBox"]

            editBox:SetText(StaticPopupDialogs["SHOW_DB_COMMAND"].command)
            editBox:SetFocus()
            editBox:HighlightText()

            local button = _G[this:GetName() .. "Button2"]
            button:ClearAllPoints()
            button:SetWidth(200)
            button:SetPoint("CENTER", editBox, "CENTER", 0, -30)
        end,
        OnHide = NOP,
        OnAccept = NOP,
        OnCancel = NOP,
        EditBoxOnEscapePressed = function(this, ...) this:GetParent():Hide() end,
        timeout = 0,
        whileDead = 1,
        hideOnEscape = 1
    }

    StaticPopupDialogs["SHOW_DB_COMMAND"].command = command
    StaticPopup_Show("SHOW_DB_COMMAND", discordChannel)
end

---Creates a command used by the DungeonBuddy on the No Pressure Discord
---and shows a popup to the player where they can copy it
---@param shorthand string The short form name of the dungeon
---@param level integer The level of the keystone
function private:CreateDungeonBuddyCommandAndShowToPlayer(shorthand, level)
    local command = string.format("/lfgquick %s %dt %s %s", shorthand, level, GetPlayerRole(), GetMissingRoles())
    StaticPopupCommand(command, KeyLevelToDiscordChannel(level))
end