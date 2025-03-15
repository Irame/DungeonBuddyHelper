---@class DBH_Private
local private = select(2, ...)

local function PartyChatFilter(self, event, msg, sender, ...)
    local mythicKeyData = msg:match("|Hkeystone:([^|]+)|h")
    if mythicKeyData then
        local clickableLink = "|HDungeonBuddyHelper:" .. mythicKeyData .. "|h|cfffce303[LFG NoP]|r|h"
        msg = msg .. " " .. clickableLink
    end
    return false, msg, sender, ...
end

ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY", PartyChatFilter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY_LEADER", PartyChatFilter)

local function CustomLinkClicked(_, link)
    local mythicKeyData = link:match("DungeonBuddyHelper:(.+)")
    if mythicKeyData then
        private.addon:ShowLFGFrameAndDiscordCommand("keystone:" .. mythicKeyData)
    end
end

hooksecurefunc(ItemRefTooltip, "SetHyperlink", CustomLinkClicked)
