---@class DBH_Private
local private = select(2, ...)

-- This file contains copies of each function that is called in
-- in the call stack from LFGListEntryCreation_Show down to C_LFGList.SetEntryTitle()
-- to be able to remove it and to pass down a custom dungeonId

function LFGListEntryCreation_OnPlayStyleSelectedInternal(self, generalPlaystyle)
	-- local previousPlaystyle = self.generalPlaystyle;
	self.generalPlaystyle = generalPlaystyle;
	-- local legacyLFGEntryPlaystyle = Enum.LFGEntryPlaystyle.None;
	-- if(C_LFGList.DoesEntryTitleMatchPrebuiltTitle(self.selectedActivity, self.selectedGroup, legacyLFGEntryPlaystyle, previousPlaystyle)) then
	-- 	LFGListEntryCreation_SetTitleFromActivityInfo(self);  // prevent call of protected C_LFGList.SetEntryTitle()
	-- end

	LFGListEntryCreation_UpdateValidState(self);
end

local function LFGListEntryCreation_Select(self, filters, categoryID, groupID, activityID)
	filters, categoryID, groupID, activityID = LFGListUtil_AugmentWithBest(bit.bor(self.baseFilters or 0, filters or 0), categoryID, groupID, activityID);
	self.selectedCategory = categoryID;
	self.selectedGroup = groupID;
	self.selectedActivity = activityID;
	self.selectedFilters = filters;

	--Update the category dropdown
	local categoryInfo = C_LFGList.GetLfgCategoryInfo(categoryID);

	--Update the activity dropdown
	local activityInfo = C_LFGList.GetActivityInfoTable(activityID);
	if(not activityInfo) then
		return;
	end

	--Update the group dropdown. If the group dropdown is showing an activity, hide the activity dropdown
	local groupName = C_LFGList.GetActivityGroupInfo(groupID);
	self.ActivityDropdown.overrideName = activityInfo and activityInfo.shortName;
	self.GroupDropdown.overrideName = groupName or activityInfo.shortName;

	self.ActivityDropdown:SetShown(groupName and not categoryInfo.autoChooseActivity);
	self.ActivityDropdown:GenerateMenu();

	self.GroupDropdown:SetShown(not categoryInfo.autoChooseActivity);
	self.GroupDropdown:GenerateMenu();

	local shouldShowCrossFactionToggle = (categoryInfo.allowCrossFaction);
	local shouldDisableCrossFactionToggle = (categoryInfo.allowCrossFaction) and not (activityInfo.allowCrossFaction);

	local _, localizedFaction = UnitFactionGroup("player");
	self.CrossFactionGroup.Label:SetText(LFG_LIST_CROSS_FACTION:format(localizedFaction));
	self.CrossFactionGroup.tooltip = LFG_LIST_CROSS_FACTION_TOOLTIP:format(localizedFaction);
	self.CrossFactionGroup.disableTooltip = LFG_LIST_CROSS_FACTION_DISABLE_TOOLTIP:format(localizedFaction);
	self.CrossFactionGroup:SetShown(shouldShowCrossFactionToggle);
	self.CrossFactionGroup.CheckButton:SetEnabled(not shouldDisableCrossFactionToggle);
	self.CrossFactionGroup.CheckButton:SetChecked(shouldDisableCrossFactionToggle);
	if(shouldDisableCrossFactionToggle) then
		self.CrossFactionGroup.Label:SetTextColor(DISABLED_FONT_COLOR:GetRGB());
	else
		self.CrossFactionGroup.Label:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB());
	end

	self.MythicPlusRating:SetShown(activityInfo.isMythicPlusActivity);
	self.PVPRating:SetShown(activityInfo.isRatedPvpActivity);

	--Update the recommended item level box
	if ( activityInfo.ilvlSuggestion ~= 0 ) then
		self.ItemLevel.EditBox.Instructions:SetFormattedText(LFG_LIST_RECOMMENDED_ILVL, activityInfo.ilvlSuggestion);
	else
		self.ItemLevel.EditBox.Instructions:SetText(LFG_LIST_ITEM_LEVEL_INSTR_SHORT);
	end

	self.NameLabel:ClearAllPoints();
	if (not self.ActivityDropdown:IsShown() and not self.GroupDropdown:IsShown()) then
		self.NameLabel:SetPoint("TOPLEFT", 20, -82);
	else
		self.NameLabel:SetPoint("TOPLEFT", 20, -120);
	end

	self.ItemLevel:ClearAllPoints();
	self.PvpItemLevel:ClearAllPoints();

	self.ItemLevel:SetShown(not activityInfo.isPvpActivity);
	self.PvpItemLevel:SetShown(activityInfo.isPvpActivity);

	if (self.MythicPlusRating:IsShown()) then
		self.ItemLevel:SetPoint("TOPLEFT", self.MythicPlusRating, "BOTTOMLEFT", 0, -3);
		self.PvpItemLevel:SetPoint("TOPLEFT", self.MythicPlusRating, "BOTTOMLEFT", 0, -3);
	elseif (self.PVPRating:IsShown()) then
		self.ItemLevel:SetPoint("TOPLEFT", self.PVPRating, "BOTTOMLEFT", 0, -3);
		self.PvpItemLevel:SetPoint("TOPLEFT", self.PVPRating, "BOTTOMLEFT", 0, -3);
	else
		self.ItemLevel:SetPoint("TOPLEFT", self.PlayStyleDropdown, "BOTTOMLEFT", -1, -15);
		self.PvpItemLevel:SetPoint("TOPLEFT", self.PlayStyleDropdown, "BOTTOMLEFT", -1, -15);
	end
	if(self.ItemLevel:IsShown()) then
		LFGListRequirement_Validate(self.ItemLevel, self.ItemLevel.EditBox:GetText());
	else
		LFGListRequirement_Validate(self.PvpItemLevel, self.PvpItemLevel.EditBox:GetText());
	end

	LFGListEntryCreation_UpdateValidState(self);
	-- LFGListEntryCreation_SetTitleFromActivityInfo(self);  -- this contains the call to C_LFGList.SetEntryTitle()
end

local function LFGListEntryCreation_SetEditMode(self, activityID)  -- changed
	local activeEntryInfo = C_LFGList.GetActiveEntryInfo()  --added
	self.editMode = activeEntryInfo ~= nil;  -- changed

	local descInstructions = nil;
	local isAccountSecured = C_LFGList.IsPlayerAuthenticatedForLFG(self:GetParent().selectedCategory);
	if (not isAccountSecured) then
		descInstructions = LFG_AUTHENTICATOR_DESCRIPTION_BOX;
	end

	if ( self.editMode ) then  -- changed
		-- local activeEntryInfo = C_LFGList.GetActiveEntryInfo();  -- moved
		assert(activeEntryInfo);

		--Update the dropdowns
		LFGListEntryCreation_Select(self, nil, nil, nil, activeEntryInfo.activityIDs[1]);

		self.GroupDropdown:Disable();
		self.ActivityDropdown:Disable();

		--Update edit boxes
		C_LFGList.CopyActiveEntryInfoToCreationFields();
		self.Name:SetEnabled(activeEntryInfo.questID == nil and isAccountSecured);
		if ( activeEntryInfo.questID ) then
			self.Description.EditBox.Instructions:SetText(LFGListUtil_GetQuestDescription(activeEntryInfo.questID));
		else
			self.Description.EditBox.Instructions:SetText(descInstructions or DESCRIPTION_OF_YOUR_GROUP);
		end

		if (self.ItemLevel:IsShown()) then
			self.ItemLevel.EditBox:SetText(activeEntryInfo.requiredItemLevel ~= 0 and activeEntryInfo.requiredItemLevel or "");
		else
			self.PvpItemLevel.EditBox:SetText(activeEntryInfo.requiredItemLevel ~= 0 and activeEntryInfo.requiredItemLevel or "");
		end
		self.MythicPlusRating.EditBox:SetText(activeEntryInfo.requiredDungeonScore or "" );
		self.PVPRating.EditBox:SetText(activeEntryInfo.requiredPvpRating or "" )
		self.PrivateGroup.CheckButton:SetChecked(activeEntryInfo.privateGroup);
		self.CrossFactionGroup.CheckButton:SetChecked(not activeEntryInfo.isCrossFactionListing);
		LFGListEntryCreation_OnPlayStyleSelectedInternal(self, activeEntryInfo.generalPlaystyle);

		self.ListGroupButton:SetText(DONE_EDITING);
	else
		self.GroupDropdown:Enable();
		self.ActivityDropdown:Enable();
		self.ListGroupButton:SetText(LIST_GROUP);
		self.Name:SetEnabled(isAccountSecured);
		self.Description.EditBox.Instructions:SetText(descInstructions or DESCRIPTION_OF_YOUR_GROUP);
		-- local activityInfo = C_LFGList.GetActivityInfoTable(self.selectedActivity);

		-- if(activityInfo and self.selectedCategory == GROUP_FINDER_CATEGORY_ID_DUNGEONS) then
		-- 	local activityID, groupID = C_LFGList.GetOwnedKeystoneActivityAndGroupAndLevel(); --Prioritize regular keystones
		-- 	if(activityID) then
		-- 		LFGListEntryCreation_Select(self, self.selectedFilters, self.selectedCategory, groupID, activityID);
		-- 	else
		-- 		activityID, groupID = C_LFGList.GetOwnedKeystoneActivityAndGroupAndLevel(true);  -- Check for a timewalking keystone.
		-- 		if(activityID) then
		-- 			LFGListEntryCreation_Select(self, self.selectedFilters, self.selectedCategory, groupID, activityID);
		-- 		end
		-- 	end
		-- end

		LFGListEntryCreation_Select(self, self.selectedFilters, self.selectedCategory, nil, activityID);  -- added
	end;
end

local function LFGListEntryCreation_Show(self, baseFilters, selectedCategory, selectedFilters, activityID, playstyle)
	--If this was what the player selected last time, just leave it filled out with the same info.
	--Also don't save it for categories that try to set it to the current area.
	local categoryInfo = C_LFGList.GetLfgCategoryInfo(selectedCategory);
	-- local keepOldData = not categoryInfo.preferCurrentArea and self.selectedCategory == selectedCategory and baseFilters == self.baseFilters and self.selectedFilters == selectedFilters;
	LFGListEntryCreation_SetBaseFilters(self, baseFilters);
	-- if ( not keepOldData ) then
		LFGListEntryCreation_Clear(self);
		LFGListEntryCreation_Select(self, selectedFilters, selectedCategory);
	-- end
	LFGListEntryCreation_OnPlayStyleSelectedInternal(self, playstyle or Enum.LFGEntryPlaystyle.Standard);  -- added
	LFGListEntryCreation_SetEditMode(self, activityID);  -- changed

	LFGListEntryCreation_UpdateValidState(self);

	LFGListFrame_SetActivePanel(self:GetParent(), self);
	self.Name:SetFocus();
	self.Label:SetText(categoryInfo.name);

	LFGListEntryCreation_CheckAutoCreate(self);
end

---Shows the LFG frame with the entry creation for the activity passed
---@param keyInfo KeystoneInfo
---@param runType RunType
function private:ShowLFGFrameWithEntryCreationForActivity(keyInfo, runType)
    HelpTip:Hide(LFGListFrame.EntryCreation.Name)
    PVEFrame_ShowFrame("GroupFinderFrame", "LFGListPVEStub");

	local playstyle = Enum.LFGEntryPlaystyle.Standard
	if runType == private.Enum.RunType.TimeOrAbandon then
		playstyle = Enum.LFGEntryPlaystyle.Hardcore
	elseif runType == private.Enum.RunType.VaultCompletion then
		playstyle = Enum.LFGEntryPlaystyle.Casual
	end

    LFGListEntryCreation_Show(LFGListFrame.EntryCreation, Enum.LFGListFilter.PvE, GROUP_FINDER_CATEGORY_ID_DUNGEONS, 0, keyInfo.activityId, playstyle);
end
