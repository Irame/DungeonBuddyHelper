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
    if IsInRaid(LE_PARTY_CATEGORY_HOME) then
        addon:Print("You are in a raid.")
        return
    end

    if not UnitIsGroupLeader("player", LE_PARTY_CATEGORY_HOME) then
        addon:Print("You are not the party leader.")
        return
    end

    self:CreateGroupAndShowDiscordCommand(args)
end

function addon:CreateGroupAndShowDiscordCommand(keystoneLink)
    local info, level = private:GetKeystoneInfo(keystoneLink)

    if not level then
        addon:Print("No keystone found")
        return
    elseif not info then
        addon:Print("Keystone found but dungeon not supported")
        return
    end

    private:ShowLFGFrameWithEntryCreationForActivity(info.activityId)
    private:CreateDungeonBuddyCommandAndShowToPlayer(info.dungeonShorthand, level)
end
