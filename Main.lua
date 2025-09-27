---@type string
local addonName = ...

---@class DBH_Private
local private = select(2, ...)

local L = private.L

---@class DBH : AceAddon, AceConsole-3.0
local addon = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0")
private.addon = addon

private.openRaidLib = LibStub:GetLibrary("LibOpenRaid-1.0")

local helpHeader = L["Commands (%s or %s)"]:format("|cfff4d512/dbh|r", "|cfff4d512/lfg|r")

local helpLines = {
    "|cfff4d512/dbh help|r - " .. L["Shows this help message."],
    "|cfff4d512/dbh opt|r - " .. L["Opens the addon options."],
    "|cfff4d512/dbh|r - " .. L["Shows the Dungeon Buddy command for the key in your inventory."],
    "|cfff4d512/dbh <keystoneLink>|r - " .. L["Shows the Dungeon Buddy command for the given keystone."],
}

function addon:OnInitialize()
    private:InitializeDb()
    self.optionsFrame, self.optionsFrameId = private:InitializeOptions(helpHeader, helpLines)

    self:RegisterChatCommand("dbh", "ChatCommandHandler");
    self:RegisterChatCommand("lfg", "ChatCommandHandler");

    private.lfgFrameButton = CreateFrame("Button", "DBH_LFGFrameButton", LFGListFrame.CategorySelection, "DBH_LFGFrameButtonTemplate")
    private.lfgFrameButton:SetShown(private.db.global.general.lfgFrameButton)

    private:InitChatLinks()

    self.WaitingForKeyUpdate = false
    self.OnKeystoneUpdate = function(unitName, keystoneInfo, allKeystonesInfo)
        if self.WaitingForKeyUpdate and private:IterPartyKeys()() then
            self.WaitingForKeyUpdate = false
            self:Print(L["Keystone info received from at least one party member. Try '/lfg' again!"])
        end
    end

    private.openRaidLib.RegisterCallback(self, "KeystoneUpdate", "OnKeystoneUpdate")
end

function DBH_OnAddonCompartmentClick(self, button)
    if button == "RightButton" then
        Settings.OpenToCategory(addon.optionsFrameId)
    else
        addon:ShowLFGFrameAndDiscordCommand()
    end
end

function addon:ChatCommandHandler(args)
    if args == "help" or args == "?" then
        self:ShowHelpMessage()
        return
    end

    if args == "opt" or args == "options" then
        Settings.OpenToCategory(self.optionsFrameId)
        return
    end

    self:ShowLFGFrameAndDiscordCommand(args)
end

function addon:ShowHelpMessage()
    self:Print(helpHeader)
    for i, line in ipairs(helpLines) do
        DEFAULT_CHAT_FRAME:AddMessage(line)
    end
end

---Shows the Dungeon Buddy command to the player and opens the LFG frame.
---@param keystoneLink? string
function addon:ShowLFGFrameAndDiscordCommand(keystoneLink)
    if IsInRaid(LE_PARTY_CATEGORY_HOME) then
        addon:Print(L["You are in a raid."])
        return
    end

    if IsInGroup(LE_PARTY_CATEGORY_HOME) then
        if not UnitIsGroupLeader("player", LE_PARTY_CATEGORY_HOME) then
            addon:Print(L["You are not the party leader."])
            return
        end

        if GetNumGroupMembers(LE_PARTY_CATEGORY_HOME) == 5 then
            addon:Print(L["Your party is full."])
            return
        end
    end

    local info
    if keystoneLink and keystoneLink:trim() ~= "" then
        info = private:GetKeystoneInfoForLink(keystoneLink)
        if not info then
            addon:Print(L["Invalid Keystone link."])
            return
        end
    end

    if not info then
        -- Get the first keystone in the party
        info = private:IterPartyKeys()()
        if not info then
            if IsInGroup(LE_PARTY_CATEGORY_HOME) then
                self:Print(L["No Keystone found in the party. Waiting for keystone info from party members..."])
                if not self.WaitingForKeyUpdate then
                    self.WaitingForKeyUpdate = true
                    private.openRaidLib:RequestKeystoneDataFromParty()
                    C_Timer.After(5, function()
                        if self.WaitingForKeyUpdate then
                            self.WaitingForKeyUpdate = false
                            self:Print(L["No keystone info received from party members in the last 5 seconds."])
                        end
                    end)
                end
            else
                self:Print(L["No Keystone found in your inventory."])
            end
            return
        end
    end

    private:ShowDungeonBuddyCommandToPlayer(info)
end
