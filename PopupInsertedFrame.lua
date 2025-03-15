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
---@field KeySelectDropdown any
---@field OnChanged fun(keyInfo: UnitKeystoneInfo|KeystoneInfo, completion: boolean)
DBH_PopupInsertedFrameMixin = {}

function PartyMembers()
    local i = -1
    return function()
        i = i + 1

        if i == 0 then
            return "player"
        end

        if i >= GetNumGroupMembers(LE_PARTY_CATEGORY_HOME) then
            return
        end

        return "party" .. i
    end
end

---Update the key dropdown
---@param keyInfoToSelect KeystoneInfo|UnitKeystoneInfo
function DBH_PopupInsertedFrameMixin:UpdateKeyDropdown(keyInfoToSelect)
    self.selectedKeyInfo = nil

    ---@type KeystoneInfo[]|UnitKeystoneInfo[]
    local partyKeyData = {self.initInfo}
    for unit in PartyMembers() do
        local keyInfo = private:GetKeystoneInfoForUnit(unit)

        if keyInfo then
            if keyInfoToSelect
                and keyInfo.activityId == keyInfoToSelect.activityId
                and keyInfo.level == keyInfoToSelect.level
                and (not keyInfoToSelect.unit or keyInfoToSelect.unit == keyInfo.unit)
                and not self.selectedKeyInfo
            then
                tremove(partyKeyData, 1)
                self.selectedKeyInfo = keyInfo
            end

            tinsert(partyKeyData, keyInfo)
        end
    end

    if not self.selectedKeyInfo then
        self.selectedKeyInfo = self.initInfo
    end

    function IsSelected(data)
        return self.selectedKeyInfo == data
    end

    function SetSelected(data)
        self.selectedKeyInfo = data
        self:InvokeOnChanged()
    end

    self.KeySelectDropdown:SetupMenu(function(dropdown, rootDescription)
		for k, keyInfo in ipairs(partyKeyData) do
            if not keyInfo.unit or UnitExists(keyInfo.unit) then
                local text = strupper(keyInfo.dungeonShorthand) .. " +" .. keyInfo.level;
                if keyInfo.unit then
                    text = text .. " (" .. UnitName(keyInfo.unit) .. ")"
                end
                rootDescription:CreateRadio(text, IsSelected, SetSelected, keyInfo);
            end
		end
	end);
end

function DBH_PopupInsertedFrameMixin:RunTypeRadioButtonClicked(id)
    if (id == 1) then
        self.TimeRadioButton:SetChecked(true)
        self.CompletionRadioButton:SetChecked(false)
    else
        self.TimeRadioButton:SetChecked(false)
        self.CompletionRadioButton:SetChecked(true)
    end

    self:InvokeOnChanged()
end

function DBH_PopupInsertedFrameMixin:InvokeOnChanged()
    if self.OnChanged then
        self.OnChanged(self.selectedKeyInfo, self.CompletionRadioButton:GetChecked())
    end
end

---Initialize the popup inserted frame
---@param info KeystoneInfo
function DBH_PopupInsertedFrameMixin:Initialize(info)
    self.initInfo = info

    self:ResetRadioButtons()
    self:UpdateKeyDropdown(info)

    self:InvokeOnChanged()
end

function DBH_PopupInsertedFrameMixin:ResetRadioButtons()
    self.TimeRadioButton:SetChecked(true)
    self.CompletionRadioButton:SetChecked(false)
end

local openRaidLib = LibStub:GetLibrary("LibOpenRaid-1.0")

function DBH_PopupInsertedFrameMixin:OnLoad()
    self.OnKeystoneUpdate = function(unitId, keystoneInfo, allKeystonesInfo)
        if self:IsShown() then
            self:UpdateKeyDropdown(self.selectedKeyInfo)
        end
    end
end

function DBH_PopupInsertedFrameMixin:OnShow()
    openRaidLib.RegisterCallback(self, "KeystoneUpdate", "OnKeystoneUpdate")
    openRaidLib:RequestKeystoneDataFromParty()
end

function DBH_PopupInsertedFrameMixin:OnHide()
    openRaidLib.UnregisterCallback(self, "KeystoneUpdate", "OnKeystoneUpdate")
end
