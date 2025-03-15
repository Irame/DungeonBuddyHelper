---@class DBH_Private
local private = select(2, ...)

-- This file contains copies of each function that is called in
-- in the call stack from LFGListEntryCreation_Show down to C_LFGList.SetEntryTitle()
-- to be able to remove it and to pass down a custom dungeonId

local function LFGListEntryCreation_OnPlayStyleSelected(self, playstyle)
	--LFGListEntryCreation_OnPlayStyleSelectedInternal(self, playstyle); -- this contains the call to C_LFGList.SetEntryTitle()
	self.selectedPlaystyle = playstyle; -- added to mimic the behavior of LFGListEntryCreation_OnPlayStyleSelectedInternal
	self.PlayStyleDropdown:GenerateMenu();
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

	local shouldShowPlayStyleDropdown = (categoryInfo.showPlaystyleDropdown) and (activityInfo.isMythicPlusActivity or activityInfo.isRatedPvpActivity or activityInfo.isCurrentRaidActivity or activityInfo.isMythicActivity);
	local shouldShowCrossFactionToggle = (categoryInfo.allowCrossFaction);
	local shouldDisableCrossFactionToggle = (categoryInfo.allowCrossFaction) and not (activityInfo.allowCrossFaction);
	if(shouldShowPlayStyleDropdown) then
		LFGListEntryCreation_OnPlayStyleSelected(self, self.selectedPlaystyle or Enum.LFGEntryPlaystyle.Standard);
	end

	self.PlayStyleDropdown:SetShown(shouldShowPlayStyleDropdown);
	self.PlayStyleLabel:SetShown(shouldShowPlayStyleDropdown);

	if(not shouldShowPlayStyleDropdown)  then
		self.selectedPlaystyle = nil
	end
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
	elseif(self.PlayStyleDropdown:IsShown()) then
		self.ItemLevel:SetPoint("TOPLEFT", self.PlayStyleLabel, "BOTTOMLEFT", -1, -15);
		self.PvpItemLevel:SetPoint("TOPLEFT", self.PlayStyleLabel, "BOTTOMLEFT", -1, -15);
	else
		self.ItemLevel:SetPoint("TOPLEFT", self.Description, "BOTTOMLEFT", -6, -19);
		self.PvpItemLevel:SetPoint("TOPLEFT", self.Description, "BOTTOMLEFT", -6, -19);
	end
	if(self.ItemLevel:IsShown()) then
		LFGListRequirement_Validate(self.ItemLevel, self.ItemLevel.EditBox:GetText());
	else
		LFGListRequirement_Validate(self.PvpItemLevel, self.PvpItemLevel.EditBox:GetText());
	end

	LFGListEntryCreation_SetPlaystyleLabelTextFromActivityInfo(self, activityInfo);
	LFGListEntryCreation_UpdateValidState(self);
	--LFGListEntryCreation_SetTitleFromActivityInfo(self);  -- this contains the call to C_LFGList.SetEntryTitle()
end

local function LFGListEntryCreation_SetEditMode(self, activityID)
	local activeEntryInfo = C_LFGList.GetActiveEntryInfo()
	self.editMode = activeEntryInfo ~= nil;

	local descInstructions = nil;
	local isAccountSecured = C_LFGList.IsPlayerAuthenticatedForLFG(self:GetParent().selectedActivity);
	if (not isAccountSecured) then
		descInstructions = LFG_AUTHENTICATOR_DESCRIPTION_BOX;
	end

	if ( self.editMode ) then
		assert(activeEntryInfo);

		--Update the dropdowns
		LFGListEntryCreation_Select(self, nil, nil, nil, activeEntryInfo.activityID);

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
		if(self.PlayStyleDropdown:IsShown()) then
			LFGListEntryCreation_OnPlayStyleSelected(self, activeEntryInfo.playstyle);
		end

		self.ListGroupButton:SetText(DONE_EDITING);
	else
		self.GroupDropdown:Enable();
		self.ActivityDropdown:Enable();
		self.ListGroupButton:SetText(LIST_GROUP);
		self.Name:SetEnabled(isAccountSecured);
		self.Description.EditBox.Instructions:SetText(descInstructions or DESCRIPTION_OF_YOUR_GROUP);

		LFGListEntryCreation_Select(self, self.selectedFilters, self.selectedCategory, nil, activityID);
	end;
end

local function LFGListEntryCreation_Show(self, baseFilters, selectedCategory, selectedFilters, activityID, playstyle)
	--If this was what the player selected last time, just leave it filled out with the same info.
	--Also don't save it for categories that try to set it to the current area.
	local categoryInfo = C_LFGList.GetLfgCategoryInfo(selectedCategory);
	LFGListEntryCreation_SetBaseFilters(self, baseFilters);
	LFGListEntryCreation_Clear(self);
	LFGListEntryCreation_Select(self, selectedFilters, selectedCategory);
	LFGListEntryCreation_OnPlayStyleSelected(self, playstyle or Enum.LFGEntryPlaystyle.Standard);
	LFGListEntryCreation_SetEditMode(self, activityID);

	LFGListEntryCreation_UpdateValidState(self);

	LFGListFrame_SetActivePanel(self:GetParent(), self);
	self.Name:SetFocus();
	self.Label:SetText(categoryInfo.name);

	LFGListEntryCreation_CheckAutoCreate(self);
end

---Shows the LFG frame with the entry creation for the activity passed
---@param activityID number
---@param completion boolean
function private:ShowLFGFrameWithEntryCreationForActivity(activityID, completion)
    PVEFrame_ShowFrame("GroupFinderFrame", "LFGListPVEStub");
    LFGListEntryCreation_Show(LFGListFrame.EntryCreation, Enum.LFGListFilter.PvE, GROUP_FINDER_CATEGORY_ID_DUNGEONS, 0, activityID, completion and Enum.LFGEntryPlaystyle.Casual or Enum.LFGEntryPlaystyle.Hardcore);
end
