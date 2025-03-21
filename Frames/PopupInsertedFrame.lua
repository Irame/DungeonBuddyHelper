---@class DBH_Private
local private = select(2, ...)

---@class DBH_RunTypeRadioButton : CheckButton
---@field LabelText string
---@field text FontString
DBH_RunTypeRadioButtonMixin = {}

function DBH_RunTypeRadioButtonMixin:OnClick()
    local parent = self:GetParent() --[[@as DBH_PopupInsertedFrame]];
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

local function AreKeystoneInfosEqual(info1, info2)
    return info1.activityId == info2.activityId
    and info1.level == info2.level
    and (not info1.unit or not info2.unit or info1.unit == info2.unit)
end

---Update the key dropdown
---@param keyInfoToSelect KeystoneInfo|UnitKeystoneInfo
function DBH_PopupInsertedFrameMixin:UpdateKeyDropdown(keyInfoToSelect)
    self.selectedKeyInfo = nil

    ---@type KeystoneInfo[]|UnitKeystoneInfo[]
    local partyKeyData = { self.initInfo }
    local initInfoRemoved = false
    for keyInfo in private:IterPartyKeys() do
        -- Select the key if it is the same as the one we want to select
        if keyInfoToSelect
            and AreKeystoneInfosEqual(keyInfo, keyInfoToSelect)
            and not self.selectedKeyInfo
        then
            self.selectedKeyInfo = keyInfo
        end

        -- Remove the initInfo from the dropdown
        -- if we would add the same key again
        if self.initInfo
            and AreKeystoneInfosEqual(keyInfo, self.initInfo)
            and not initInfoRemoved
        then
            tremove(partyKeyData, 1)
            initInfoRemoved = true
        end

        tinsert(partyKeyData, keyInfo)
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

function DBH_PopupInsertedFrameMixin:OnLoad()
    self.OnKeystoneUpdate = function(unitId, keystoneInfo, allKeystonesInfo)
        if self:IsShown() then
            self:UpdateKeyDropdown(self.selectedKeyInfo)
        end
    end
end

function DBH_PopupInsertedFrameMixin:OnShow()
    private.openRaidLib.RegisterCallback(self, "KeystoneUpdate", "OnKeystoneUpdate")
    private.openRaidLib:RequestKeystoneDataFromParty()
end

function DBH_PopupInsertedFrameMixin:OnHide()
    private.openRaidLib.UnregisterCallback(self, "KeystoneUpdate", "OnKeystoneUpdate")
end
