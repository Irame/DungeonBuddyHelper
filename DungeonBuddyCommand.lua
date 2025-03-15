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

    -- Get the size of the group
    local groupSize = GetNumGroupMembers()

    -- Loop through all group members
    for i = 0, groupSize-1 do
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

---Generates a command string for the DungeonBuddy on the No Pressure Discord
---@param info KeystoneInfo The info of the keystone
local function GenerateCommand(info, completion)
    return string.format("/lfgquick quick_dungeon_string:%s %d%s %s %s", info.dungeonShorthand, info.level, completion and "c" or "t", GetPlayerRole(), GetMissingRoles())
end

---Creates a command used by the DungeonBuddy on the No Pressure Discord
---and shows a popup to the player where they can copy it
---@param info KeystoneInfo The info of the keystone
function private:ShowDungeonBuddyCommandToPlayer(info)
    local popupTextTemplate = "Copy the following command and paste it in the '%s' NoP discord channel:"
    StaticPopupDialogs["SHOW_DB_COMMAND"] = StaticPopupDialogs["SHOW_DB_COMMAND"] or {
        text = popupTextTemplate,
        button1 = OKAY,
        hasEditBox = 1,
        editBoxWidth = 275,
        OnShow = function(this, ...)
            local editBox = _G[this:GetName() .. "EditBox"]
            local updateCommand = function(keyInfo, completion)
                editBox:SetText(GenerateCommand(keyInfo, completion))
                editBox:SetFocus()
                editBox:HighlightText()
            end

            local updateText = function(keyInfo)
                this.text:SetFormattedText(popupTextTemplate, KeyLevelToDiscordChannel(keyInfo.level))
            end

            this.insertedFrame.OnChanged = function(keyInfo, completion)
                this.data = keyInfo
                private:ShowLFGFrameWithEntryCreationForActivity(keyInfo, completion)
                updateCommand(keyInfo, completion)
                updateText(keyInfo)
            end

            this.insertedFrame:Initialize(this.data)
        end,
        OnHide = function(this, ...)
            this.insertedFrame.OnChanged = nil
        end,
        OnAccept = function(this, ...)
            if LFGListFrame.EntryCreation.Name:IsVisible() then
                local helpTipInfo = {
                    text = ("Enter the name you listed you group as in the NoP discord (e.g. NoP %s XX)"):format(strupper(this.data.dungeonShorthand)),
                    buttonStyle = HelpTip.ButtonStyle.Close,
                    targetPoint = HelpTip.Point.RightEdgeCenter,
                }

                HelpTip:Show(LFGListFrame.EntryCreation.Name, helpTipInfo, LFGListFrame.EntryCreation.Name)
            end
        end,
        OnCancel = NOP,
        EditBoxOnEscapePressed = function(this, ...) this:GetParent():Hide() end,
        timeout = 0,
        whileDead = 1,
        hideOnEscape = 1
    }

    StaticPopup_Show("SHOW_DB_COMMAND", KeyLevelToDiscordChannel(info.level), nil, info, _G["DBH_PopupInsertedFrame"])
end
