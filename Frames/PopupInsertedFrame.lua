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

function DBH_CommandInputBoxMixin:SetCommand(command, focus)
    self.command = command;
    self:SetText(command);
    if focus ~= false then
        self:SetFocus();
        self:HighlightText();
    end
end

---@class DBH_PopupInsertedFrame : Frame
---@field RunTypeDropdown WowStyle1DropdownTemplate
---@field KeySelectDropdown WowStyle1DropdownTemplate
---@field RoleSelect DBH_RoleSelect
---@field SingleLineInputBox DBH_CommandInputBox
---@field MultiLineInput Frame
---@field MultiLineInputBox DBH_CommandInputBox
---@field OnChanged fun(keyInfo: UnitKeystoneInfo|KeystoneInfo, runType: RunType)
DBH_PopupInsertedFrameMixin = {}

local function AreKeystoneInfosEqual(info1, info2)
    return info1.activityId == info2.activityId
    and info1.level == info2.level
    and (not info1.unit or not info2.unit or info1.owner == info2.owner)
end

---Update the key dropdown
---@param keyInfoToSelect KeystoneInfo|UnitKeystoneInfo
function DBH_PopupInsertedFrameMixin:UpdateKeyDropdown(keyInfoToSelect)
    self.selectedKeyInfo = nil

    ---@type KeystoneInfo[]|UnitKeystoneInfo[]
    -- Only a manually pasted key survives independently of the current roster.
    local partyKeyData = {}
    if self.initInfo and not self.initInfo.unit then
        tinsert(partyKeyData, self.initInfo)
    end
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
            and not self.initInfo.unit
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

    local function IsSelected(data)
        return self.selectedKeyInfo == data
    end

    local function SetSelected(data)
        self.selectedKeyInfo = data
        self:InvokeOnChanged()
    end

    self.KeySelectDropdown:SetupMenu(function(dropdown, rootDescription)
		for k, keyInfo in ipairs(partyKeyData) do
            if not keyInfo.unit or UnitExists(keyInfo.unit) then
                local text = strupper(keyInfo.dungeonShorthand) .. " +" .. keyInfo.level;
                if keyInfo.unit then
                    text = text .. " (" .. (keyInfo.owner or GetUnitName(keyInfo.unit, true)) .. ")"
                end
                rootDescription:CreateRadio(text, IsSelected, SetSelected, keyInfo);
            end
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
    if not self.selectedKeyInfo then
        local dialog = self:GetParent()
        if dialog and dialog.GetTextFontString then
            dialog.data = nil
            dialog:GetTextFontString():SetText(L["No party keys available. Refresh or paste a keystone link with /dbh."])
        end
    end
    if self.OnChanged and self.selectedKeyInfo then
        self.OnChanged(self.selectedKeyInfo, self.selectedRunType)
    end

    self:UpdateCommand()
end

function DBH_PopupInsertedFrameMixin:SetCommand(command)
    local editingName = self.GroupNameInput:HasFocus()
    if command:find("\n") then
        self.MultiLineInput:Show()
        self.SingleLineInputBox:Hide()
        self:SetHeight(350)
        self.MultiLineInputBox:SetCommand(command, not editingName)
    else
        self.MultiLineInput:Hide()
        self.SingleLineInputBox:Show()
        self:SetHeight(270)
        self.SingleLineInputBox:SetCommand(command, not editingName)
    end
    -- Keep focus in the name field: reacquiring it triggers InputBoxTemplate's
    -- select-all handler, which would replace the name on the next keystroke.
    StaticPopup_ResizeShownDialogs()
end

---Update the command
function DBH_PopupInsertedFrameMixin:UpdateCommand()
    if not self.selectedKeyInfo then
        self:SetCommand(L["No party keys available. Refresh or paste a keystone link with /dbh."])
        return
    end
    local command = ""
    if private:IsKeySupportedByDungeonBuddy(self.selectedKeyInfo) then
        command = private:GenerateDungeonBuddyCommand(self.selectedKeyInfo, self.selectedRunType, self.RoleSelect:GetShortRolesString(), self:GetCustomGroupName())
    else
        command = private:GenerateBoilerRoomText(self.selectedKeyInfo, self.selectedRunType, self.RoleSelect:GetShortRolesString(), self.randomSeed, self:GetCustomGroupName())
    end
    self:SetCommand(command)
end

---Initialize the popup inserted frame
---@param info KeystoneInfo
function DBH_PopupInsertedFrameMixin:Initialize(info)
    self.initInfo = info
    self.randomSeed = math.random(1, 1000000)
    self.GroupNameInput:SetText(private.db.global.general.customGroupName or "")

    self:UpdateRunTypeDropdown()
    self:UpdateKeyDropdown(info)

    self:InvokeOnChanged()
end

function DBH_PopupInsertedFrameMixin:OnLoad()
    self.GroupNameInput:SetMaxLetters(80)
    self.OnKeystoneUpdate = function(unitId, keystoneInfo, allKeystonesInfo)
        if self:IsShown() then
            self:UpdateKeyDropdown(self.selectedKeyInfo)
            self:InvokeOnChanged()
        end
    end

    self.RoleSelect.OnChanged = function()
        self:InvokeOnChanged()
    end
    self.GroupNameInput:SetScript("OnTextChanged", function(input, userInput)
        if userInput then
            private.db.global.general.customGroupName = private:NormalizeGroupName(input:GetText())
            self:InvokeOnChanged()
        end
    end)
    self.RefreshKeysButton:SetText(L["Refresh keys"])
    self.ChatKeysButton:SetText(L["Request keys in chat (!keys)"])
    self.ChatKeysButton:SetScript("OnClick", function()
        private:RequestPartyKeysInChat()
    end)
    self.RefreshKeysButton:SetScript("OnClick", function()
        private:RequestPartyKeys()
        self:UpdateKeyDropdown(self.selectedKeyInfo)
        self:InvokeOnChanged()
    end)
end

function DBH_PopupInsertedFrameMixin:GetCustomGroupName()
    return private:NormalizeGroupName(self.GroupNameInput:GetText())
end

function DBH_PopupInsertedFrameMixin:UpdateRoleSelect()
    local missingRoles = private:GetMissingRoles()
    self.RoleSelect:SetRolesByString(missingRoles)
    self.RoleSelect:SetLockedRole(private:GetPlayerRole())
end

function DBH_PopupInsertedFrameMixin:OnShow()
    private.openRaidLib.RegisterCallback(self, "KeystoneUpdate", "OnKeystoneUpdate")
    private:RequestPartyKeys()

    self.randomSeed = math.random(1, 1000000)

    self:UpdateRoleSelect()

    self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    self:RegisterEvent("PLAYER_ROLES_ASSIGNED")
    self:RegisterEvent("GROUP_ROSTER_UPDATE")
end

function DBH_PopupInsertedFrameMixin:OnHide()
    private.openRaidLib.UnregisterCallback(self, "KeystoneUpdate", "OnKeystoneUpdate")

    self:UnregisterAllEvents();
end

function DBH_PopupInsertedFrameMixin:OnEvent(event)
    if event == "GROUP_ROSTER_UPDATE" then
        self:UpdateKeyDropdown(self.selectedKeyInfo)
        private:RequestPartyKeys()
    end
    self:UpdateRoleSelect()
    self:InvokeOnChanged()
end
