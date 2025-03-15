---@type string
local addonName = ...

---@class DBH_Private
local private = select(2, ...)

---@class DBH : AceAddon, AceConsole-3.0
local addon = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0")
private.addon = addon

function addon:OnInitialize()
    self:RegisterChatCommand("dbh", "ChatCommandHandler");
    self:RegisterChatCommand("lfg", "ChatCommandHandler");
end

function addon:ChatCommandHandler(args)
    self:ShowLFGFrameAndDiscordCommand(args)
end

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

    local info = private:GetKeystoneInfoForLink(keystoneLink)

    if not info then
        return
    end

    private:ShowDungeonBuddyCommandToPlayer(info)
end
