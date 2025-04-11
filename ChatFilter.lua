---@class DBH_Private
local private = select(2, ...)

local function PartyChatFilter(self, event, msg, sender, ...)
    if private.db.global.chatKeyLinks then
        local mythicKeyData = msg:match("|Hkeystone:([^|]+)|h")
        if mythicKeyData then
            local clickableLink = "|HDungeonBuddyHelper:" .. mythicKeyData .. "|h|cfffce303[LFG NoP]|r|h"
            msg = msg .. " " .. clickableLink
        end
    end
    return false, msg, sender, ...
end

local function CustomLinkClicked(_, link)
    local mythicKeyData = link:match("DungeonBuddyHelper:(.+)")
    if mythicKeyData then
        private.addon:ShowLFGFrameAndDiscordCommand("keystone:" .. mythicKeyData)
    end
end

function private:InitChatLinks()
    ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY", PartyChatFilter)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY_LEADER", PartyChatFilter)
    hooksecurefunc(ItemRefTooltip, "SetHyperlink", CustomLinkClicked)
end
