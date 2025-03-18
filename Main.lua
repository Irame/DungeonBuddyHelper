---@type string
local addonName = ...

---@class DBH_Private
local private = select(2, ...)

---@class DBH : AceAddon, AceConsole-3.0
local addon = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0")
private.addon = addon

private.openRaidLib = LibStub:GetLibrary("LibOpenRaid-1.0")

function addon:OnInitialize()
    self:RegisterChatCommand("dbh", "ChatCommandHandler");
    self:RegisterChatCommand("lfg", "ChatCommandHandler");

    CreateFrame("Button", "DBH_LFGFrameButton", LFGListFrame.CategorySelection, "DBH_LFGFrameButtonTemplate")
end

function addon:ChatCommandHandler(args)
    self:ShowLFGFrameAndDiscordCommand(args)
end

---Shows the Dungeon Buddy command to the player and opens the LFG frame.
---@param keystoneLink? string
function addon:ShowLFGFrameAndDiscordCommand(keystoneLink)
    if IsInRaid(LE_PARTY_CATEGORY_HOME) then
        addon:Print("You are in a raid.")
        return
    end

    if IsInGroup(LE_PARTY_CATEGORY_HOME) then
        if not UnitIsGroupLeader("player", LE_PARTY_CATEGORY_HOME) then
            addon:Print("You are not the party leader.")
            return
        end

        if GetNumGroupMembers(LE_PARTY_CATEGORY_HOME) == 5 then
            addon:Print("Your party is full.")
            return
        end
    end

    local info
    if keystoneLink and keystoneLink:trim() ~= "" then
        info = private:GetKeystoneInfoForLink(keystoneLink)
        if not info then
            addon:Print("Invalid Keystone link.")
            return
        end
    end

    if not info then
        -- Get the first keystone in the party
        info = private:IterPartyKeys()()
        if not info then
            self:Print("No Keystone found in the party.")
            return
        end
    end

    private:ShowDungeonBuddyCommandToPlayer(info)
end
