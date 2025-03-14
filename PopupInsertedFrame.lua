---@class DBH_Private
local private = select(2, ...)

---@class DBH_RunTypeRadioButton : CheckButton
---@field LabelText string
DBH_RunTypeRadioButtonMixin = {}

function DBH_RunTypeRadioButtonMixin:OnClick()
    ---@type DBH_PopupInsertedFrame
    local parent = self:GetParent();
    parent:RunTypeRadioButtonClicked(self:GetID());
end

function DBH_RunTypeRadioButtonMixin:OnLoad()
    self.text:SetText(self.LabelText);
end

---@class DBH_PopupInsertedFrame : Frame
---@field TimeRadioButton DBH_RunTypeRadioButton
---@field CompletionRadioButton DBH_RunTypeRadioButton
---@field OnRunTypeChanged fun(id: number)
DBH_PopupInsertedFrameMixin = {}

function DBH_PopupInsertedFrameMixin:RunTypeRadioButtonClicked(id)
    if (id == 1) then
        self.TimeRadioButton:SetChecked(true)
        self.CompletionRadioButton:SetChecked(false)
    else
        self.TimeRadioButton:SetChecked(false)
        self.CompletionRadioButton:SetChecked(true)
    end

    if self.OnRunTypeChanged then
        self.OnRunTypeChanged(id)
    end
end

function DBH_PopupInsertedFrameMixin:Reset()
    self.TimeRadioButton:SetChecked(true)
    self.CompletionRadioButton:SetChecked(false)

    if self.OnRunTypeChanged then
        self.OnRunTypeChanged(self.TimeRadioButton:GetID())
    end
end