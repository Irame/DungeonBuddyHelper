---@class DBH_RoleButton : CheckButton
---@field role string
---@field isGreyed boolean
DBH_RoleButtonMixin = {}

function DBH_RoleButtonMixin:OnLoad()
    local atlas = nil
    if self.role == "t" then
        atlas = "UI-LFG-RoleIcon-Tank"
    elseif self.role == "h" then
        atlas = "UI-LFG-RoleIcon-Healer"
    elseif self.role == "d" then
        atlas = "UI-LFG-RoleIcon-DPS"
    end

    if not atlas then
        return
    end

    self:GetNormalTexture():SetAtlas(atlas .. "-Disabled")
    self:GetCheckedTexture():SetAtlas(atlas)
end

function DBH_RoleButtonMixin:OnClick()
    self:GetParent()--[[@as DBH_RoleSelect]]:InvokeOnChanged()
end

---@class DBH_RoleSelect : Frame
---@field TankButton DBH_RoleButton
---@field HealButton DBH_RoleButton
---@field Damage1Button DBH_RoleButton
---@field Damage2Button DBH_RoleButton
---@field Damage3Button DBH_RoleButton
---@field Buttons DBH_RoleButton[]
---@field OnChanged? fun()
DBH_RoleSelectMixin = {}

function DBH_RoleSelectMixin:SetLockedRole(role)
    local buttonDisabled = false
    for i = #self.Buttons, 1, -1 do
        local button = self.Buttons[i]
        if button.role == role and not buttonDisabled then
            button:Disable()
            button:SetChecked(false)
            buttonDisabled = true
        else
            button:Enable()
        end
    end
end

function DBH_RoleSelectMixin:SetRolesByString(roles)
    for _, button in ipairs(self.Buttons) do
        button:SetChecked(false)
    end

    local dpsCount = 0
    for i = 1, #roles do
        local roleShort = roles:sub(i, i)
        if roleShort == "t" then
            self.TankButton:SetChecked(true)
        elseif roleShort == "h" then
            self.HealButton:SetChecked(true)
        elseif roleShort == "d" then
            dpsCount = dpsCount + 1
            if dpsCount == 1 then
                self.Damage1Button:SetChecked(true)
            elseif dpsCount == 2 then
                self.Damage2Button:SetChecked(true)
            elseif dpsCount == 3 then
                self.Damage3Button:SetChecked(true)
            end
        end
    end
end

function DBH_RoleSelectMixin:GetShortRolesString()
    local roles = ""
    for _, button in ipairs(self.Buttons) do
        if button:GetChecked() then
            roles = roles .. button.role
        end
    end

    return roles
end

function DBH_RoleSelectMixin:InvokeOnChanged()
    if self.OnChanged then
        self.OnChanged()
    end
end