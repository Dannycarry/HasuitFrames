


local function danGenericClassFile() --todo figure out how to get relevant spells for each class/spec from spellbook and make everything. this function could exist as a backup/to use on new xpac or something
	
	local common = {["controller"]=danBottomLeft_BottomLeft,["size"]=15,	["frameLevel"]=20,	["hideCooldownText"]=true,	["alpha"]=1,	}
	local commonOptionsHarmful = {auraSourceIsPlayerAndHarmful,	["priority"]=1,	["arena"]=common, ["loadOn"]=danLoadOnArenaOnly}
	
	local common = {["controller"]=danBottomRight_BottomRight,["size"]=15,	["frameLevel"]=20,	["hideCooldownText"]=true,	["alpha"]=1,	}
	local commonOptionsHelpful = {auraSourceIsPlayerAndHelpful,	["priority"]=1,	["group"]=common}
	
	local GetSpellName = C_Spell.GetSpellName
	
	
	local initializedHarmfulPlayerSpells = {}
	local hasuitSpellManualListHarmful = hasuitSpellManualListHarmful
	if hasuitSpellManualListHarmful then
		hasuitFramesCenterSetEventType("aura")
		hasuitSetupFrameOptions = commonOptionsHarmful
		for i=1,#hasuitSpellManualListHarmful do
			hasuitFramesInitialize(hasuitSpellManualListHarmful[i])
			initializedHarmfulPlayerSpells[hasuitSpellManualListHarmful[i]] = true
		end
	end
	
	local initializedHelpfulPlayerSpells = {}
	local hasuitSpellManualListHelpful = hasuitSpellManualListHelpful
	if hasuitSpellManualListHelpful then
		hasuitFramesCenterSetEventType("aura")
		hasuitSetupFrameOptions = commonOptionsHelpful
		for i=1,#hasuitSpellManualListHelpful do
			hasuitFramesInitialize(hasuitSpellManualListHelpful[i])
			initializedHelpfulPlayerSpells[hasuitSpellManualListHelpful[i]] = true
		end
	end
	
	
	
	local isHarmful = C_Spell.IsSpellHarmful
	local isHelpful = C_Spell.IsSpellHelpful
	
	local ignoreList = {
		[GetSpellName(216339)]=true, --Drink
		[GetSpellName(167152)]=true, --Refreshment
		[GetSpellName(216338)]=true, --Food
		[GetSpellName(308433)]=true, --Food & Drink
	}
	
	do
		local hasuitGenericClassFileIgnoreList = hasuitGenericClassFileIgnoreList
		if hasuitGenericClassFileIgnoreList then
			for i=1,#hasuitGenericClassFileIgnoreList do
				ignoreList[hasuitGenericClassFileIgnoreList[i]] = true
			end
		end
	end
	
	
	
	
	
	local danPlayerSpellTrackerFrame = CreateFrame("Frame") -- FindSpellOverrideByID, FindBaseSpellByID?
	danPlayerSpellTrackerFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player") --maybe sent instead? actually could pair sent with registering unit_aura for an onupdate check to see if that was a spell that should be tracked, can keep track of what spells have been sent so only 1 short register per player spellid
	danPlayerSpellTrackerFrame:SetScript("OnEvent", function(_, _, _, _, spellId)
		if not ignoreList[spellId] and not ignoreList[spellName] then
			if isHarmful(spellId) then
				if not initializedHarmfulPlayerSpells[spellId] then
					initializedHarmfulPlayerSpells[spellId] = true
					local spellName = GetSpellName(spellId)
					hasuitFramesCenterSetEventType("aura") --todo make these things go away everywhere?, todo fix things like zen spheres in a better way?
					hasuitSetupFrameOptions = commonOptionsHarmful
					hasuitFramesInitialize(spellId)
				end
			elseif isHelpful(spellId) then
				if not initializedHelpfulPlayerSpells[spellId] then
					initializedHelpfulPlayerSpells[spellId] = true
					local spellName = GetSpellName(spellId)
					hasuitFramesCenterSetEventType("aura")
					hasuitSetupFrameOptions = commonOptionsHelpful
					hasuitFramesInitialize(spellId)
				end
			end
		end
	end)
end








local danAddonLoadedFrame = CreateFrame("Frame")
danAddonLoadedFrame:RegisterEvent("ADDON_LOADED")
danAddonLoadedFrame:SetScript("OnEvent", function(_, _, addonName)
	if addonName=="HasuitFrames" then
		if not hasuitUsingSpecialClassProfile then
			danGenericClassFile()
		end
		danGenericClassFile = nil
		danAddonLoadedFrame:SetScript("OnEvent", nil)
		danAddonLoadedFrame:UnregisterAllEvents()
		danAddonLoadedFrame = nil
	end
end)