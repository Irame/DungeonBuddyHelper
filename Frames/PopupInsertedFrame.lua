---@class DBH_Private
local private = select(2, ...)

local L = private.L

---@class DBH_CommandInputBox : EditBox
DBH_CommandInputBoxMixin = {}

function DBH_CommandInputBoxMixin:OnEscapePressed()
    StaticPopup_Hide("SHOW_DB_COMMAND")
end

function DBH_CommandInputBoxMixin:OnMouseUp()
    self:HighlightText();
end

function DBH_CommandInputBoxMixin:OnChar()
    if self.command then
        self:SetText(self.command);
        self:HighlightText();
    end;
end

function DBH_CommandInputBoxMixin:SetCommand(command, setFocus)
    self.command = command;
    self:SetText(command);
    if setFocus then
        self:SetFocus();
    end
    if self:HasFocus() then
        self:HighlightText();
    end
end

---@class DBH_PopupInsertedFrame : Frame
---@field RunTypeDropdown WowStyle1DropdownTemplate
---@field KeySelectDropdown WowStyle1DropdownTemplate
---@field RefreshKeysButton IconButtonTemplate
---@field RoleSelect DBH_RoleSelect
---@field SingleLineInputBox DBH_CommandInputBox
---@field MultiLineInput Frame
---@field MultiLineInputBox DBH_CommandInputBox
---@field CustomGroupNameCheckBox CheckButton
---@field CustomGroupNameInputBox EditBox
---@field OnChanged fun(keyInfo: OwnedKeystoneInfo|KeystoneInfo, runType: RunType)
DBH_PopupInsertedFrameMixin = {}

local function AreKeystoneInfosEqual(info1, info2)
    return info1.activityId == info2.activityId
    and info1.level == info2.level
    and (not info1.owner or not info2.owner or info1.owner == info2.owner)
end

---Update the key dropdown
---@param keyInfoToSelect? KeystoneInfo|OwnedKeystoneInfo
function DBH_PopupInsertedFrameMixin:UpdateKeyDropdown(keyInfoToSelect)
    self.selectedKeyInfo = nil

    ---@type KeystoneInfo[]|OwnedKeystoneInfo[]
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
        self.selectedKeyInfo = partyKeyData[1]
    end

    -- selectedKeyInfo might have changed, so we need to invoke the onChanged callback
    self:InvokeOnChanged()

    local function IsSelected(data)
        return self.selectedKeyInfo == data
    end

    local function SetSelected(data)
        self.selectedKeyInfo = data
        self:InvokeOnChanged()
    end

    self.KeySelectDropdown:SetupMenu(function(dropdown, rootDescription)
		for k, keyInfo in ipairs(partyKeyData) do
            local text = strupper(keyInfo.dungeonShorthand) .. " +" .. keyInfo.level;
            if keyInfo.owner then
                text = text .. " (" .. private:NameFromFullName(keyInfo.owner) .. ")"
            end
            rootDescription:CreateRadio(text, IsSelected, SetSelected, keyInfo);
		end
	end);
end

function DBH_PopupInsertedFrameMixin:UpdateRunTypeDropdown()
    self.selectedRunType = self.selectedRunType or private.Enum.RunType.TimeButComplete

    local function IsSelected(data)
        return self.selectedRunType == data
    end

    local function SetSelected(data)
        self.selectedRunType = data
        self:InvokeOnChanged()
    end

    self.RunTypeDropdown:SetupMenu(function(dropdown, rootDescription)
        rootDescription:CreateRadio(L["Time but complete"], IsSelected, SetSelected, private.Enum.RunType.TimeButComplete);
        rootDescription:CreateRadio(L["Time or abandon"], IsSelected, SetSelected, private.Enum.RunType.TimeOrAbandon);
        rootDescription:CreateRadio(L["Vault completion"], IsSelected, SetSelected, private.Enum.RunType.VaultCompletion);
    end);
end

function DBH_PopupInsertedFrameMixin:InvokeOnChanged()
    if self.OnChanged then
        self.OnChanged(self.selectedKeyInfo, self.selectedRunType)
    end

    self:UpdateCommand()
end

function DBH_PopupInsertedFrameMixin:UpdateHeight()
    local height = 160
    if self.MultiLineInput:IsShown() then
        height = height + 80
    end
    if self.CustomGroupNameInputBox:IsShown() then
        height = height + 25
    end
    self:SetHeight(height)
    StaticPopup_ResizeShownDialogs()
end

function DBH_PopupInsertedFrameMixin:UpdateCustomGroupNameInputBox()
    self.CustomGroupNameInputBox:SetShown(private.db.global.general.useCustomGroupName)
    self.CustomGroupNameInputBox:SetText(private.db.global.general.customGroupName or "")
    self:UpdateHeight()
end

function DBH_PopupInsertedFrameMixin:SetCommand(command)
    local setFocusToCommand = not self.CustomGroupNameInputBox:HasFocus()
    if command:find("\n") then
        self.MultiLineInput:Show()
        self.SingleLineInputBox:Hide()
        self.MultiLineInputBox:SetCommand(command, setFocusToCommand)
    else
        self.MultiLineInput:Hide()
        self.SingleLineInputBox:Show()
        self.SingleLineInputBox:SetCommand(command, setFocusToCommand)
    end
    self:UpdateHeight()
end

---Update the command
function DBH_PopupInsertedFrameMixin:UpdateCommand()
    local command = ""
    if self.selectedKeyInfo then
        if private:IsKeySupportedByDungeonBuddy(self.selectedKeyInfo) then
            command = private:GenerateDungeonBuddyCommand(self.selectedKeyInfo, self.selectedRunType, self.RoleSelect:GetShortRolesString(), private:GetCustomGroupName())
        else
            command = private:GenerateBoilerRoomText(self.selectedKeyInfo, self.selectedRunType, self.RoleSelect:GetShortRolesString(), self.randomSeed, private:GetCustomGroupName())
        end
    end
    self:SetCommand(command)
end

---Initialize the popup inserted frame
---@param info? KeystoneInfo
function DBH_PopupInsertedFrameMixin:Initialize(info)
    self.initInfo = info

    self:UpdateRunTypeDropdown()
    self:UpdateKeyDropdown(info)

    self:InvokeOnChanged()
end

function DBH_PopupInsertedFrameMixin:OnLoad()
    self.OnKeystoneUpdate = function(unitId, keystoneInfo, allKeystonesInfo)
        if self:IsShown() then
            self:UpdateKeyDropdown(self.selectedKeyInfo)
        end
    end

    self.RoleSelect.OnChanged = function()
        self:InvokeOnChanged()
    end

    local function RefreshKeys()
        private:RequestPartyKeys()
        self.RefreshKeysButton:SetEnabledState(false)
        C_Timer.NewTimer(5, function()
            self.RefreshKeysButton:SetEnabledState(true)
        end);
    end

    self.RefreshKeysButton:SetOnClickHandler(RefreshKeys);
    self.RefreshKeysButton:SetTooltipInfo(nil, L["Request keys from party members."]);

    self.CustomGroupNameCheckBox:SetScript("OnClick", function(checkbox)
        private.db.global.general.useCustomGroupName = checkbox:GetChecked()
        self:UpdateCustomGroupNameInputBox()
        self:InvokeOnChanged()
        if checkbox:GetChecked() then
            self.CustomGroupNameInputBox:SetFocus()
        end
    end)

    self.CustomGroupNameInputBox:SetScript("OnTextChanged", function(input, userInput)
        if userInput then
            private.db.global.general.customGroupName = input:GetText()
            self:InvokeOnChanged()
        end
    end)
end

function DBH_PopupInsertedFrameMixin:UpdateRoleSelect()
    local missingRoles = private:GetMissingRoles()
    self.RoleSelect:SetRolesByString(missingRoles)
    self.RoleSelect:SetLockedRole(private:GetPlayerRole())
end

function DBH_PopupInsertedFrameMixin:OnShow()
    private.RegisterKeystoneUpdate(self, "OnKeystoneUpdate")
    private:RequestPartyKeys()

    self.randomSeed = math.random(1, 1000000)

    self:UpdateRoleSelect()

    self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    self:RegisterEvent("PLAYER_ROLES_ASSIGNED")
    self:RegisterEvent("GROUP_ROSTER_UPDATE")

    self.RefreshKeysButton:SetShown(IsInGroup(LE_PARTY_CATEGORY_HOME))

    self.CustomGroupNameCheckBox:SetChecked(private.db.global.general.useCustomGroupName)
    self:UpdateCustomGroupNameInputBox()
end

function DBH_PopupInsertedFrameMixin:OnHide()
    private.UnregisterKeystoneUpdate(self)

    self:UnregisterAllEvents();
end

function DBH_PopupInsertedFrameMixin:OnEvent(event, ...)
    self:UpdateRoleSelect()
    self:UpdateCommand()

    if event == "GROUP_ROSTER_UPDATE" then
        self.RefreshKeysButton:SetShown(IsInGroup(LE_PARTY_CATEGORY_HOME))
    end
end
