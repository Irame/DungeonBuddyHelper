---@class DBH_Private
local private = select(2, ...)

---@class LFGFrameButton
DBH_LFGFrameButtonMixin = {}

function DBH_LFGFrameButtonMixin:OnClick()
    private.addon:ShowLFGFrameAndDiscordCommand()
end
