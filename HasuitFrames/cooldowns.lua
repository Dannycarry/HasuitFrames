

local danFileName = "cooldowns.lua"
local danPrint = function()end
local danPrintPurple = danPrint
local danPrintPurple2 = danPrint
local danPrintTeal = danPrint
local danPrintTeal2 = danPrint

-- C_Timer.After(0, function()
	-- danPrint = hasuitTraceGetDanPrintFunction(hasuitGreen2, hasuitGreen2, false, danFileName)
	-- danPrintPurple = hasuitTraceGetDanPrintFunction(hasuitPurple, hasuitPurple, false, danFileName)
	-- danPrintPurple2 = hasuitTraceGetDanPrintFunction(hasuitPurple2, hasuitPurple2, false, danFileName)
	-- danPrintTeal = hasuitTraceGetDanPrintFunction(hasuitTeal, hasuitTeal, false, danFileName)
	-- danPrintTeal2 = hasuitTraceGetDanPrintFunction(hasuitTeal2, hasuitTeal2, false, danFileName)
-- end)


hasuitBlessingOfAutumnIgnoreList = { --how would this interact with time stop? or other cd reduction like aug thing? if multiply then should combine on unitframe, if not then probably nothing needs to be done?
	[336126]=true, --Gladiator's Medallion
	[42292]=true, --PvP Trinket, heirloom
	[336135]=true, --Adaptation
	[336139]=true, --Adaptation?
	
	[107079]=true, --Quaking Palm
	[59752]=true, --Every Man For Himself
	[273104]=true, --Fireblood
	[65116]=true, --Stoneblood
	[7744]=true, --Will of the Forsaken
	[58984]=true, --Shadowmeld
	
	[382912]=true, --Well-Honed Instincts?
	[404381]=true, --Defy Fate?
	[87023]=true, --Cauterize? shouldn't need to do for debuff cds actually if it were made right
	[45182]=true, --Cheating Death?
	
	[31616]=true, --Nature's Guardian?, what about warlock spell lock vs actual pet cd?
}


local tinsert = tinsert

local danCooldownDisplayLoadOn
do
	local danRestoreCooldowns1
	tinsert(hasuitDoThisAddon_Loaded, function()
		danRestoreCooldowns1 = hasuitRestoreCooldowns
		hasuitRestoreCooldowns = nil
	end)
	
	local function danRestoreCooldowns2()
		for unitType, unitTable in pairs(hasuitUnitFramesForUnitType) do
			for i=#unitTable,1,-1 do
				danRestoreCooldowns1(unitTable[i])
			end
		end
	end
	
	local danDoThisOnUpdate = hasuitDoThisOnUpdate
	local arenaCrowdControlSpellUpdateFrame = hasuitArenaCrowdControlSpellUpdateFrame
	hasuitArenaCrowdControlSpellUpdateFrame = nil

	danCooldownDisplayLoadOn = hasuitFramesCenterAddLoadingProfile({
		["instanceType"]={["none"]=true,["arena"]=true,["party"]=true,["scenario"]=true},
		["groupSize"]=5,
		
		
		["loadedFunction"]=function()
			arenaCrowdControlSpellUpdateFrame:RegisterEvent("ARENA_CROWD_CONTROL_SPELL_UPDATE")
			arenaCrowdControlSpellUpdateFrame:RegisterEvent("ARENA_COOLDOWNS_UPDATE")
			if hasuitCooldownDisplayActiveGroup==false then
				danDoThisOnUpdate(danRestoreCooldowns2)
				-- C_Timer.After(0, danRestoreCooldowns2)
			end
			hasuitCooldownDisplayActiveGroup = true
		end,
		["unloadedFunction"]=function()
			if hasuitCooldownDisplayActiveGroup then
				arenaCrowdControlSpellUpdateFrame:UnregisterAllEvents()
				for unitType, unitTable in pairs(hasuitUnitFramesForUnitType) do --bored todo make hasuitUnitFramesForUnitType an array? with a pairs table as well
					for i=#unitTable,1,-1 do
						local frame = unitTable[i]
						if frame.cooldownPriorities then
							for _, icon in pairs(frame.cooldownPriorities) do
								hasuitRecycleCooldownIcon(icon)
							end
							frame.cooldowns = {}
							frame.cooldownOptions = {}
							frame.cooldownPriorities = {}
							frame.cooldownsDisabled = true
						end
					end
				end
			end
			hasuitCooldownDisplayActiveGroup = false
		end,
	})
end





local initialize = hasuitFramesInitialize
local hasuitFramesCenterSetEventType = hasuitFramesCenterSetEventType

do
	local function danSortCooldowns(a,b)
		if a==b then --? definitely need this but why
			-- danPrint("a==b", "a: "..a.priority, a.spellName, a.spellId, a.expirationTime, "b: "..b.priority, b.spellName, b.spellId, b.expirationTime)
			return
		elseif a.priority<b.priority then
			-- danPrint("a.priority<b.priority", "a: "..a.priority, a.spellName, a.spellId, a.expirationTime, "b: "..b.priority, b.spellName, b.spellId, b.expirationTime)
			return true
		elseif a.priority==b.priority then
			local expirationA
			if a.isPrimary then
				expirationA = a.hypoExpirationTime or a.expirationTime
				if a.expirationTime and a.expirationTime>expirationA then
					expirationA = a.expirationTime
				end
			else
				expirationA = a.expirationTime
			end
			local expirationB
			if b.isPrimary then
				expirationB = b.hypoExpirationTime or b.expirationTime
				if b.expirationTime and b.expirationTime>expirationB then
					expirationB = b.expirationTime
				end
			else
				expirationB = b.expirationTime
			end
			-- if expirationA and expirationB then
				if expirationA<expirationB then
					-- danPrint("a.expirationTime<b.expirationTime", "a: "..a.priority, a.spellName, a.spellId, a.expirationTime, "b: "..b.priority, b.spellName, b.spellId, b.expirationTime)
					return true
				end
			-- else
				-- if not expirationA then
					-- return expirationB and true
					-- danPrintBig("danA", a, a.spellId)
				-- else
					-- danPrintBig("danB", b, b.spellId)
				-- end
			-- end
		end
		-- danPrint("no return", "a: "..a.priority, a.spellName, a.spellId, a.expirationTime, "b: "..b.priority, b.spellName, b.spellId, b.expirationTime)
	end
	
	local function danSortCooldownsStationaryish(a,b)
		local aPriority = a.priority~=256 and a.priority or a.basePriority
		local bPriority = b.priority~=256 and b.priority or b.basePriority
		return aPriority<bPriority
	end
	
	
	
	
	local function cooldownGrow(controller)
		local u = controller.unitTypeStuff
		local xDirection = u["xDirection"]
		local yOffset = u["yOffset"]
		local currentXPlacement = (xDirection+u["xOffset"])*xDirection
		
		local ownPoint = u["ownPoint"]
		local setPointOn = controller.setPointOn
		local targetPoint = u["targetPoint"]
		
		local frames = controller.frames
		sort(frames, controller.options["sort"])
		for i=1, #frames do 
			local icon = frames[i]
			icon:SetPoint(ownPoint, setPointOn, targetPoint, currentXPlacement*xDirection, yOffset)
			currentXPlacement = currentXPlacement+1+icon.size
		end
	end

	local function cooldownGrowLimited(controller)
		local u = controller.unitTypeStuff
		local xDirection = u["xDirection"]
		local yOffset = u["yOffset"]
		local currentXPlacement = (xDirection+u["xOffset"])*xDirection
		
		local ownPoint = u["ownPoint"]
		local setPointOn = controller.setPointOn
		local targetPoint = u["targetPoint"]
		
		local limit = u["limit"]
		
		local frames = controller.frames
		sort(frames, controller.options["sort"])
		for i=1, #frames do 
			local icon = frames[i]
			if i<=limit then
				icon:SetPoint(ownPoint, setPointOn, targetPoint, currentXPlacement*xDirection, yOffset)
				currentXPlacement = currentXPlacement+1+icon.size
			else
				icon:SetPoint(ownPoint, setPointOn, targetPoint, 0, -10000) --a lot easier than hiding cooldown text/managing icon opacity when showing it again/whatever else
			end
		end
	end


	local defaultCdSize = 28
	local yOffsets = (defaultCdSize-hasuitRaidFrameHeightForGroupSize[3])/2-1 --doing it like this with TOPRIGHT/TOPLEFT instead of RIGHT/LEFT because it'll be better if i make some cooldowns different sizes? will need to change something if frame size stuff for under groupsize 6 is ever different --which should be possible in useroptions, todo
	
	hasuitTrinketCooldowns={}
	hasuitInterruptCooldowns={}
	hasuitDefensiveCooldowns={}
	hasuitCooldownsControllers = {
		{
			["grow"]=cooldownGrowLimited,
			["sort"]=danSortCooldowns,
			["setPointOnBorder"]=true,
			["group"]={["specCooldowns"]=hasuitTrinketCooldowns,	["size"]=defaultCdSize,["xDirection"]=-1,["ownPoint"]="TOPRIGHT",["targetPoint"]="TOPLEFT",["xOffset"]=-44,["yOffset"]=yOffsets,["limit"]=1}, --could have like a half grow upward when trinket is about to come up and go back to limit 1 when it's off cd, some way of showing trinket is about to come up would be nice?
			["arena"]={["specCooldowns"]=hasuitTrinketCooldowns,	["size"]=defaultCdSize,["xDirection"]=1, ["ownPoint"]="TOPLEFT",["targetPoint"]="TOPRIGHT",["xOffset"]=44,["yOffset"]=yOffsets,["limit"]=1},
		},
		
		{
			["grow"]=cooldownGrowLimited,
			["sort"]=danSortCooldowns,
			["setPointOnBorder"]=true,
			["group"]={["specCooldowns"]=hasuitDefensiveCooldowns,	["size"]=defaultCdSize,["xDirection"]=-1,["ownPoint"]="TOPRIGHT",["targetPoint"]="TOPLEFT",["xOffset"]=-73,["yOffset"]=yOffsets,["limit"]=7},
			["arena"]={["specCooldowns"]=hasuitDefensiveCooldowns,	["size"]=defaultCdSize,["xDirection"]=1, ["ownPoint"]="TOPLEFT", ["targetPoint"]="TOPRIGHT",["xOffset"]=73,["yOffset"]=yOffsets,["limit"]=7},
		},
		
		{
			["grow"]=cooldownGrow,
			["sort"]=danSortCooldownsStationaryish,
			["setPointOnBorder"]=true,
			["group"]={["specCooldowns"]=hasuitInterruptCooldowns,	["size"]=defaultCdSize,["xDirection"]=-1,["ownPoint"]="TOPRIGHT",["targetPoint"]="TOPLEFT",["xOffset"]=-305,["yOffset"]=yOffsets},
			["arena"]={["specCooldowns"]=hasuitInterruptCooldowns,	["size"]=defaultCdSize,["xDirection"]=1, ["ownPoint"]="TOPLEFT", ["targetPoint"]="TOPRIGHT",["xOffset"]=305,["yOffset"]=yOffsets},
		},
	}
end

hasuitFramesCenterSetEventType("cleu")



do
	local cdCle1=danCleuSuccessCooldownStart1
	local cdCle2=danCleuSuccessCooldownStart2
	local cdCleT=danCleuSuccessCooldownStartPvPTrinket
	local cdCleR=danCleuAppliedCooldownStartRacial
	local cdCast=danUnitCastSucceededCooldownStart
	local cdPet=danCleuCooldownStartPet
	local cdHeal=danCleuHealCooldownStart
	local cdCleE=danCleuSpellEmpowerStartCooldownStart2
	local cleAura=danCleuAppliedCooldownStart
	local cleAurR=danCleuRemovedCooldownStart
	local cleAurP=danCleuAppliedCooldownStartPreventMultiple
	
	local shiftingPowerAffectedSpells = {}
	local coldSnapAffectedSpells = {}
	local vanishAffectedSpells = {}
	local timeSkipAffectedSpells = {}
	
	local lowStartAlpha = 0.67
	
	do
		local trinketCooldowns = hasuitTrinketCooldowns
		
		local dan3090 = {["minimumDuration"]=30,["differenceFromNormalDuration"]=-90}
		local sharedTrinketCooldowns = {
			[59752]={["minimumDuration"]=90,["differenceFromNormalDuration"]=-90},--Every Man For Himself/will to survive
			[273104]=dan3090,--Fireblood
			[65116]=dan3090,--Stoneblood
			[7744]=dan3090,--Will of the Forsaken
		}
		
		
		trinketCooldowns["general"]={
			{cdCleT,["spellId"]=336126,	["priority"]=-10,	["duration"]=120,--Gladiator's Medallion
				["pvpTrinket"]=true, ["sharedCd"]=sharedTrinketCooldowns},
			{cdCleT,["spellId"]=42292,	["priority"]=-10,	["duration"]=120,--PvP Trinket, oh 283167 is from hunter pets probably? don't think i let comp stomp data in
				["pvpTrinket"]=true, ["sharedCd"]=sharedTrinketCooldowns},
			{cdCle2,["spellId"]=336135,	["priority"]=-10,	["duration"]=60,--Adaptation? --todo
				["pvpTrinket"]=true},
			{cleAura,["spellId"]=336139,["priority"]=-10,	["duration"]=60,--Adaptation? debuff
				["pvpTrinket"]=true},
		}
		
		
		hasuitTrackedRaceCooldowns["Human"] = true
		trinketCooldowns["Human"]={
			{cdCleR, ["spellId"]=59752,["priority"]=-9,		["duration"]=180,--Every Man For Himself/will to survive
				["minimumDuration"]=90,["differenceFromNormalDuration"]=-30},
		}
		
		
		do --shouldTrackUndead
			local playerClass = hasuitPlayerClass
			if playerClass=="PRIEST" or playerClass=="WARLOCK" or playerClass=="EVOKER" or playerClass=="WARRIOR" or playerClass=="DEMONHUNTER" then --todo or playerClass=="MONK" if playing sleep
				hasuitTrackedRaceCooldowns["Scourge"] = true --undead
				trinketCooldowns["Scourge"]={
					{cdCleR, ["spellId"]=7744,["priority"]=-9,	["duration"]=120,--Will of the Forsaken
						["minimumDuration"]=30,["differenceFromNormalDuration"]=-90},
				}
				
			else
				hasuitSetupFrameOptions = {danCleuAppliedRacialNotTrackedAffectingPvpTrinket,["loadOn"]=danCooldownDisplayLoadOn, --Will of the Forsaken
					["minimumDuration"]=30,["differenceFromNormalDuration"]=-90}
				initialize(7744) --Will of the Forsaken
				
			end
		end
	end
	

	do
		local interruptCooldowns = hasuitInterruptCooldowns
		
		
		hasuitTrackedRaceCooldowns["Pandaren"] = true
		interruptCooldowns["Pandaren"]={
			{cdCle2,["spellId"]=107079,	["priority"]=40,["duration"]=120},--Quaking Palm
		}
		
		
		-- interruptCooldowns["general"]={
		-- }
		
		
		
		do
			local cdCleSB=danCleuSuccessCooldownStartSolarBeam
			
			local skullBashTableHidden=
				{cdCle2,["spellId"]=106839,	["priority"]=2,["duration"]=15,  --Skull Bash hidden
					["startAlpha"]=0}
			local skullBashTable=
				{cdCle2,["spellId"]=106839,	["priority"]=2,["duration"]=15}  --Skull Bash normal
			local maimTable=
				{cdCle2,["spellId"]=22570,	["priority"]=4,["duration"]=20,  --Maim hidden
					["startAlpha"]=0}
			local typhoonTable=
				{cdCle2,["spellId"]=61391,	["priority"]=5,["duration"]=30,  --Typhoon hidden
					["startAlpha"]=0}
			
			interruptCooldowns["DRUID"]={
				{cdCle2,["spellId"]=5211,	["priority"]=3,	["duration"]=60},--Mighty Bash
				{cdCle2,["spellId"]=99,		["priority"]=3,	["duration"]=30},--Incapacitating Roar
			}
			interruptCooldowns[102]={--Balance
				{cdCleSB,["spellId"]=78675,	["priority"]=1,	["duration"]=60},--Solar Beam
				skullBashTableHidden,
				{cdCle2,["spellId"]=61391,	["priority"]=5,	["duration"]=30, --Typhoon low opacity
					["startAlpha"]=lowStartAlpha},
			}
			interruptCooldowns[103]={--Feral
				skullBashTable,
				{cdCle2,["spellId"]=22570,	["priority"]=4,	["duration"]=20},--Maim
				typhoonTable,
			}
			interruptCooldowns[104]={--Guardian
				skullBashTable,
				maimTable,
				typhoonTable,
			}
			interruptCooldowns[105]={--Restoration
				skullBashTableHidden,
				maimTable,
				typhoonTable,
			}
			
			
			hasuitSetupFrameOptions = {danCleuInterruptCooldownReductionSolarBeam,["CDr"]=15,["affectedSpells"]={78675},["loadOn"]=danCooldownDisplayLoadOn}--Solar Beam
			initialize(97547) --Solar Beam interrupt
			
		end


		interruptCooldowns["DEATHKNIGHT"]={ --todo pet stuff
			{cdCle2,["spellId"]=47528,	["priority"]=1,	["duration"]=15},--Mind Freeze
			{cdCle2,["spellId"]=77606,	["priority"]=2,	["duration"]=20, --Dark Simulacrum hidden
				["startAlpha"]=0},
			{cdCle2,["spellId"]=47476,	["priority"]=3,	["duration"]=45},--Strangulate
			{cdCle2,["spellId"]=221562,	["priority"]=3,	["duration"]=45},--Asphyxiate
			{cdCle2,["spellId"]=108194,	["priority"]=3,	["duration"]=45},--Asphyxiate?
			{cdCle2,["spellId"]=207167,	["priority"]=5,	["duration"]=60},--Blinding Sleet
		}
		-- interruptCooldowns[250]={--Blood
		-- }
		interruptCooldowns[251]={--Frost --todo remorseless winter?
			{cleAurP,["spellId"]=377048,	["priority"]=4,	["duration"]=90,--Absolute Zero (from Frostwyrm's Fury), should maybe be 89 or something? probably not worth making a whole thing to make the cd based on actual spellcast and then only show once they're confirmed playing the stun. --todo hide if not playing the stun? or change icon to the dragon?
				["startAlpha"]=lowStartAlpha},
		}
		-- interruptCooldowns[252]={--Unholy
		-- }
		hasuitSetupFrameOptions = {danCleuEnergizeCooldownReduction,["CDr"]=3,["affectedSpells"]={47528},["loadOn"]=danCooldownDisplayLoadOn}--Mind Freeze
		initialize(378849) --Coldthirst
		
		


		interruptCooldowns["DEMONHUNTER"]={
			{cdCle2,["spellId"]=183752,	["priority"]=1,	["duration"]=15},--Disrupt
			{cdCle2,["spellId"]=179057,	["priority"]=2,	["duration"]=45},--Chaos Nova, there'sa tongues talent [Wave of Debilitation] new duration was 60
			{cdCle2,["spellId"]=217832,	["priority"]=4,	["duration"]=45},--Imprison
			{cdCle2,["spellId"]=221527,	["priority"]=4,	["duration"]=45},--Imprison immune
			{cdCle2,["spellId"]=207684,	["priority"]=5,	["duration"]=90},--Sigil of Misery base 120, not sure if they take -25% honor talent
		}
		-- interruptCooldowns[577]={--Havoc
			-- {cdCle2,["spellId"]=211881,	["priority"]=3,	["duration"]=30},--Fel Eruption
		-- }
		-- interruptCooldowns[581]={--Vengeance
		-- }


		do
			local quell20=
				{cdCle2,["spellId"]=351338,	["priority"]=1,	["duration"]=20}--Quell 20
			
			interruptCooldowns["EVOKER"]={ --todo wing buffet, tail swipe?
				{cdCleE,["spellId"]=382266,	["priority"]=5,	["duration"]=30}, --Fire Breath
				{cdCleE,["spellId"]=357208,	["priority"]=5,	["duration"]=30}, --Fire Breath
			}
			interruptCooldowns[1467]={--Devastation
				quell20,
				{cdCle2,["spellId"]=357210,	["priority"]=3,	["duration"]=60},--Deep Breath 60, base 120
				{cdCle2,["spellId"]=433874,	["priority"]=3,	["duration"]=60},--Deep Breath 60, base 120
			}
			interruptCooldowns[1468]={--Preservation
				{cdCle2,["spellId"]=351338,	["priority"]=1,	["duration"]=40},--Quell 40
				{cdCle2,["spellId"]=357210,	["priority"]=3,	["duration"]=120},--Deep Breath, todo [Wingleader] and [Onyx Legacy]
				{cdCle2,["spellId"]=433874,	["priority"]=3,	["duration"]=120},--Deep Breath 120, this one is 3.75 sec duration and more common, other one is 6 sec, can't tell where the difference comes from but maybe one is devastation and the other is pres, or maybe one is the one that can fly around and be controlled but idk where the extra duration is coming from if that's the case. the 3.75 second one is an entirely different spellid but also adds like 5 random points and moves some around from the old spellid. none of the points ever change so like what? what's the point of points in an aura that look like this ["0, 0, -200, 0, 0, -100"]/["0, 0, 0, -200, -200, 200, 0, 100, 70, 70, -100, 0"] and not a single one ever changes? maybe just supposed to be used internally by blizzard and a way to tune stuff easily like how fast you can turn while it's active? speed and stuff. not actually inefficient probably i guess maybe, just weird because there are definitely ways to do that without it showing up in an aura's points. also why does the first -200 change from [3] to [4]? what's the extra 0 lol, or maybe it moved to [5]
				{cdCle2,["spellId"]=359816,	["priority"]=4,	["duration"]=120, --Dream Flight
					["startAlpha"]=0},
			}
			interruptCooldowns[1473]={--Augmentation
				quell20,
				{cdCle2,["spellId"]=403631,	["priority"]=3,	["duration"]=120},--Breath of Eons, same thing as deep breath? spellid must be based on whether talent is taken that makes you able to steer but too low lvl to test
				{cdCle2,["spellId"]=442204,	["priority"]=3,	["duration"]=120},--Breath of Eons
				{cdCle2,["spellId"]=404977,	["priority"]=2,	["duration"]=180},--Time Skip
			}
			
			tinsert(timeSkipAffectedSpells, 382266) --Fire Breath
			tinsert(timeSkipAffectedSpells, 357208) --Fire Breath
			tinsert(timeSkipAffectedSpells, 351338) --Quell
			tinsert(timeSkipAffectedSpells, 403631) --Breath of Eons
			tinsert(timeSkipAffectedSpells, 442204) --Breath of Eons
			
			hasuitSetupFrameOptions = {danCleuSpellEmpowerInterruptCooldownReduction,["CDr"]="reset",["affectedSpells"]={382266, 357208},["loadOn"]=danCooldownDisplayLoadOn} --Fire Breath, could have just done like 10000 for cdr instead of having "reset" be a thing?
			initialize(382266) --Fire Breath
			initialize(357208) --Fire Breath
			hasuitSetupFrameOptions = {danCleuAppliedCooldownReduction,["CDr"]=3,["affectedSpells"]={357210, 433874, 442204},["loadOn"]=danCooldownDisplayLoadOn} --Deep Breath, bored todo 3 sec cap? might not get reached every time, assuming i understand how this works from reading the tooltip
			initialize(434473) --Bombardments
		end

		interruptCooldowns["MONK"]={
			{cdCle2,["spellId"]=116705,	["priority"]=1,	["duration"]=15},--Spear Hand Strike
			{cdCle2,["spellId"]=119381,	["priority"]=2,	["duration"]=50},--Leg Sweep base 60
			{cdCle2,["spellId"]=115078,	["priority"]=3,	["duration"]=30},--Paralysis base 45
			{cdCle2,["spellId"]=116844,	["priority"]=4,	["duration"]=40},--Ring of Peace base 45, do people take the -5 sec?
		}
		-- interruptCooldowns[268]={--Brewmaster
		-- }
		-- interruptCooldowns[269]={--Windwalker
		-- }
		-- interruptCooldowns[270]={--Mistweaver
		-- }
		hasuitSetupFrameOptions = {danCleuInterruptCooldownReduction,["CDr"]=5,["affectedSpells"]={115078},["loadOn"]=danCooldownDisplayLoadOn} --paralysis, do people take [Energy Transfer]?
		initialize(116705) --spear hand strike
		
		


		interruptCooldowns["WARRIOR"]={
			{cdCle2,["spellId"]=6552,	["priority"]=1,	["duration"]=13.3},--Pummel --base 15, 382461 1 sec off pummel, 5% from another
			{cdCle2,["spellId"]=107570,	["priority"]=2,	["duration"]=28.5},--Storm Bolt
			{cdCle2,["spellId"]=46968,	["priority"]=3,	["duration"]=25, --Shockwave --todo 15 sec reduction if it hit 3 targets,40 baseline, todo -5 sec from [Earthquaker] probably has an event
				["startAlpha"]=lowStartAlpha},
			{cdCle2,["spellId"]=5246,	["priority"]=4,	["duration"]=90},--Intimidating Shout
		}
		interruptCooldowns[71]={--Arms
			{cdCle2,["spellId"]=236320,	["priority"]=6,	["duration"]=90, --War Banner
				["startAlpha"]=lowStartAlpha},
		
		}
		-- interruptCooldowns[72]={--Fury
		-- }
		-- interruptCooldowns[73]={--Protection
			-- {cdCle2,["spellId"]="Disrupting Shout",	["priority"]=1,	["duration"]=75},--Disrupting Shout todo?
		-- }


		interruptCooldowns["HUNTER"]={
			{cdCle2,["spellId"]=19577,	["priority"]=2,	["duration"]=55},--Intimidation base 60, do people take -5?
			{cdCle2,["spellId"]=187650,	["priority"]=3,	["duration"]=25},--Freezing Trap, 30 base, do people take -5?
			{cdCle2,["spellId"]=213691,	["priority"]=4,	["duration"]=30},--Scatter Shot, doesn't share with binding anymore, shares with bursting now todo
			{cdCle2,["spellId"]=109248,	["priority"]=5,	["duration"]=45},--Binding Shot
			{cdCle2,["spellId"]=236776,	["priority"]=6,	["duration"]=35},--High Explosive Trap, 40 base, do people take -5? doesn't replace intim anymore, worth to track?
		}
		interruptCooldowns[253]={--Beast Mastery
			{cdCle2,["spellId"]=147362,	["priority"]=1,	["duration"]=22},--Counter Shot base 24, people prob take this talent
		}
		interruptCooldowns[254]={--Marksmanship
			{cdCle2,["spellId"]=147362,	["priority"]=1,	["duration"]=22},--Counter Shot base 24
		}
		interruptCooldowns[255]={--Survival
			{cdCle2,["spellId"]=187707,	["priority"]=1,	["duration"]=13},--Muzzle base 15
		}
		
		hasuitSetupFrameOptions = {danCleuSuccessCooldownReduction,["CDr"]=0.5,["affectedSpells"]={19577, 109248},["loadOn"]=danCooldownDisplayLoadOn} --intimidation and binding shot
		initialize(259495) --wildfire bomb
		initialize(19434) --Aimed Shot
		initialize(34026) --bm kill command
		
		hasuitSetupFrameOptions = {danCleuAppliedCooldownReductionSourceIsDest,["CDr"]="reset",["affectedSpells"]={213691},["loadOn"]=danCooldownDisplayLoadOn} --Scatter Shot
		initialize(385646) --Quick Load from health 40%
		
		
		
		

		interruptCooldowns["WARLOCK"]={
			{cdCle2,["spellId"]=132409,	["priority"]=1,	["duration"]=24},--Spell Lock?
			
			{cdCast,["spellId"]=119910,	["priority"]=1,	["duration"]=24},--Spell Lock (command demon) --seems 100% impossible to track these properly if they press command demon while out of range
			{cdCast,["spellId"]=119905,	["priority"]=1,	["duration"]=15},--Singe Magic (command demon)
			{cdCast,["spellId"]=119907,	["priority"]=1,	["duration"]=120},--Shadow Bulwark (command demon)
			{cdCast,["spellId"]=119909,	["priority"]=1,	["duration"]=0.5},--Seduction (command demon)
			{cdPet,	["spellId"]=19647,	["priority"]=1,	["duration"]=24},--Spell Lock (pet)
			{cdPet,	["spellId"]=89808,	["priority"]=1,	["duration"]=15},--Singe Magic (pet)
			{cdPet,	["spellId"]=17767,	["priority"]=1,	["duration"]=120},--Shadow Bulwark (pet)
			{cdPet,	["spellId"]=6358,	["priority"]=1,	["duration"]=0.5},--Seduction (pet)
			{cdCle2,["spellId"]=6789,	["priority"]=3,	["duration"]=45},--Mortal Coil
			{cdCle2,["spellId"]=5484,	["priority"]=3,	["duration"]=40},--Howl of Terror
		}
		-- interruptCooldowns[265]={--Affliction
		-- }
		interruptCooldowns[266]={--Demonology
			{cdCast,["spellId"]=119914,	["priority"]=1,	["duration"]=30},--Axe Toss (command demon)
			{cdPet,	["spellId"]=89766,	["priority"]=1,	["duration"]=30},--Axe Toss (pet)
			
			{cdCle2,["spellId"]=111898,	["priority"]=2,	["duration"]=120},--Grimoire: Felguard
		}
		interruptCooldowns[267]={--Destruction
			{cdCle2,["spellId"]=1122,	["priority"]=4,	["duration"]=120},--Summon Infernal --todo check for buff after infernal cast to determine whether they took -60 sec cd talent, sometimes they take it sometimes they don't. 180 base
		}

		interruptCooldowns["MAGE"]={
			{cdCle2,["spellId"]=2139,	["priority"]=1,	["duration"]=24},--Counterspell
			{cdCle2,["spellId"]=382440,	["priority"]=2,	["duration"]=60},--Shifting Power
			{cdCle2,["spellId"]=31661,	["priority"]=3,	["duration"]=45},--Dragon's Breath --todo all specs 387807 Casting Ice Lance on Frozen targets reduces the cooldown of your loss of control abilities by 2 sec.
		}
		-- interruptCooldowns[62]={--Arcane
		-- }
		-- interruptCooldowns[63]={--Fire
		-- }
		-- interruptCooldowns[64]={--Frost
		-- }
		
		-- if hasuitPlayerClass=="DRUID" then
			-- tinsert(interruptCooldowns["MAGE"], --actually just re-enable this after making the ice lance cd reduction
				-- {cdCle2,["spellId"]=113724,	["priority"]=4,	["duration"]=45}--Ring of Frost, nice to call out "only ring" sometimes if in form, could add this only for resto when that gets made, maybe this should be tracked for any dps spec if they have a resto druid or just always tracked
				-- tinsert(shiftingPowerAffectedSpells, 113724) --Ring of Frost
				-- tinsert(coldSnapAffectedSpells, 113724) --Ring of Frost
			-- ) 
		-- end
		
		tinsert(shiftingPowerAffectedSpells, 2139) --counterspell
		tinsert(shiftingPowerAffectedSpells, 31661) --dragon's breath
		
		hasuitSetupFrameOptions = {danCleuInterruptCooldownReduction,["CDr"]=4,["affectedSpells"]={2139},["loadOn"]=danCooldownDisplayLoadOn}
		initialize(2139) --counterspell 4 sec reduction


		interruptCooldowns["SHAMAN"]={ --todo track earth ele stun, maybe like earth ele cd that gets replaced by the stun when earth ele is out, todo static field?
			{cdCle2,["spellId"]=57994,	["priority"]=1,	["duration"]=12},--Wind Shear
			{cdCle2,["spellId"]=204336,	["priority"]=3,	["duration"]=24},--Grounding Totem
			{cdCle2,["spellId"]=51490,	["priority"]=4,	["duration"]=30, --Thunderstorm, todo can be -5 sec if talented with knockup
				["startAlpha"]=lowStartAlpha},
		}
		-- interruptCooldowns[262]={--Elemental
		-- }
		interruptCooldowns[263]={--Enhancement
			{cdCle2,["spellId"]=197214,	["priority"]=2,	["duration"]=40},--Sundering todo -12 sec from [Whirling Elements]
		}
		-- interruptCooldowns[264]={--Restoration
		-- }
		
		
		do
			local blind120 = 
				{cdCle2,["spellId"]=2094,	["priority"]=4,	["duration"]=120} --Blind 120
			
			
			interruptCooldowns["ROGUE"]={
				{cdCle2,["spellId"]=1766,	["priority"]=1,	["duration"]=15},--Kick
				{cdCle2,["spellId"]=408,	["priority"]=2,	["duration"]=30},--Kidney Shot
				{cdCle2,["spellId"]=1776,	["priority"]=3,	["duration"]=25},--Gouge new duration was 20
			}
			interruptCooldowns[259]={--Assassination
				blind120,
			}
			interruptCooldowns[260]={--Outlaw
				{cdCle2,["spellId"]=2094,	["priority"]=4,	["duration"]=81}, --Blind 90 base 120, -30 outlaw and -10% outlaw hero talent, not sure if 10% taken
			}
			interruptCooldowns[261]={--Subtlety
				blind120,
			}
			tinsert(vanishAffectedSpells, 1766) --Kick
			tinsert(vanishAffectedSpells, 408) --Kidney Shot
			tinsert(vanishAffectedSpells, 1776) --Gouge
			tinsert(vanishAffectedSpells, 2094) --Blind
		end



		interruptCooldowns["PRIEST"]={
			{cdCle2,["spellId"]=8122,	["priority"]=3,	["duration"]=30},--Psychic Scream, 45 base
		}
		-- interruptCooldowns[256]={--Discipline
		-- }
		interruptCooldowns[257]={--Holy
			{cdCle2,["spellId"]=88625,	["priority"]=1,	["duration"]=30},--Holy Word: Chastise, base 60 --todo accurate cd, smite + divine word? + talent reductions etc
		}
		interruptCooldowns[258]={--Shadow
			{cdCle2,["spellId"]=15487,	["priority"]=1,	["duration"]=30},--Silence base 45
			{cdCle2,["spellId"]=64044,	["priority"]=2,	["duration"]=45},--Psychic Horror
		}


		interruptCooldowns["PALADIN"]={
			{cdCle2,["spellId"]=96231,	["priority"]=1,	["duration"]=15},--Rebuke
			{cdCle2,["spellId"]=853,	["priority"]=3,	["duration"]=60},--Hammer of Justice
			{cdCle2,["spellId"]=115750,	["priority"]=4,	["duration"]=90},--Blinding Light
			{cdCle2,["spellId"]=20066,	["priority"]=4,	["duration"]=15},--Repentance
		}
		-- interruptCooldowns[65]={--Holy
		-- }
		interruptCooldowns[66]={--Protection
			{cdCle2,["spellId"]=215652,	["priority"]=2,	["duration"]=45},--Shield of Virtue pvp talent
		}
		-- interruptCooldowns[70]={--Retribution
		-- }
		
		local hoj = {853}
		hasuitSetupFrameOptions = {danCleuSuccessCooldownReduction,["CDr"]=6,["affectedSpells"]=hoj,["loadOn"]=danCooldownDisplayLoadOn} --Hammer of Justice
		initialize(53600) --Shield of the Righteous
		initialize(415091) --Shield of the Righteous?
		initialize(2812) --Denounce
		initialize(53385) --Divine Storm
		initialize(383328) --Final Verdict
		initialize(215661) --Justicar's Vengeance
		initialize(85222) --Light of Dawn
		initialize(85673) --Word of Glory --tested and free procs still give the -2 per holy power spent, Divine Purpose and Shining Light, same with divine storm proc
		initialize(156322) --Eternal Flame
		initialize(85256) --Templar's Verdict
		
		hasuitSetupFrameOptions = {danCleuSuccessCooldownReduction,["CDr"]=10,["affectedSpells"]=hoj,["loadOn"]=danCooldownDisplayLoadOn} --Hammer of Justice
		initialize(427453) --Hammer of Light, untested, seemed like maybe this was breaking vs a ret paladin?
		initialize(429826) --Hammer of Light ^
		
		hasuitSetupFrameOptions = {danCleuSuccessCooldownReduction,["CDr"]=16,["affectedSpells"]=hoj,["loadOn"]=danCooldownDisplayLoadOn} --Hammer of Justice
		initialize(198034) --Divine Hammer, todo 1 Holy Power per sec
		initialize(198137) --Divine Hammer ^
		
	end














	do 
		local defensiveCooldowns = hasuitDefensiveCooldowns
		
		
		
		
		-- defensiveCooldowns["general"]={
		-- }
		
		
		hasuitTrackedRaceCooldowns["NightElf"] = true
		hasuitTrackedRaceCooldowns["DarkIronDwarf"] = true
		hasuitTrackedRaceCooldowns["Dwarf"] = true --todo shouldn't always show?
		
		defensiveCooldowns["NightElf"]={
			{cdCle2,["spellId"]=58984,	["priority"]=40,["duration"]=120},--Shadowmeld
		}
		defensiveCooldowns["DarkIronDwarf"]={
			{cdCleR,["spellId"]=273104,["priority"]=40,	["duration"]=120,--Fireblood
				["minimumDuration"]=30,["differenceFromNormalDuration"]=-90},
		}
		defensiveCooldowns["Dwarf"]={
			{cdCleR,["spellId"]=65116,["priority"]=40,	["duration"]=120,--Stoneform
				["minimumDuration"]=30,["differenceFromNormalDuration"]=-90},
		}
		
		
		
		do
			local barkskin60 = 
				{cdCle1,["spellId"]=22812,	["priority"]=20,	["duration"]=60} --Barkskin
			local barkskin31 = 
				{cdCle1,["spellId"]=22812,	["priority"]=20,	["duration"]=34}--Barkskin, base 45 for guardian, 60 for other specs, reduced to 34 by guardian-only talents that might not get taken, new duration from 31.5
			
			
			defensiveCooldowns["DRUID"]={
				{cdCle1,["spellId"]=108238,	["priority"]=26,	["duration"]=90},--Renewal
				{cleAura,["spellId"]=382912,["priority"]=27,	["duration"]=120,--Well-Honed Instincts
					["specialText"]="proc"},
			}
			defensiveCooldowns[102]={--Balance
				barkskin60,
			}
			defensiveCooldowns[103]={--Feral
				barkskin60,
				{cdCle2,["spellId"]=61336,	["priority"]=21,	["duration"]=180,--Survival Instincts --todo 205673 savage momentum pvp talent check for -10 sec interrupt
					["charges"]=1},
			}
			defensiveCooldowns[104]={--Guardian
				barkskin31,
				{cdCle2,["spellId"]=61336,	["priority"]=21,	["duration"]=136.8, --Survival Instincts 2 charges new duration from 126
					["charges"]=2},
			}
			defensiveCooldowns[105]={--Restoration
				barkskin60,
				{cdCle2,["spellId"]=740,	["priority"]=21,	["duration"]=180},--Tranquility, todo -20 sec cd talent, seems like there's no way to tell someone's playing it other than watching for cultivation/verdancy/treant wildgrowth/points from -30 sec cd talent, could do something like the blackCheck system for it, once everything is seen release the cd reduction that they would have had etc
				{cdCle2,["spellId"]=203651,	["priority"]=22,	["duration"]=60},--Overgrowth
				-- {cleAurR,["spellId"]=132158,["priority"]=23,	["duration"]=60},--Nature's Swiftness, todo -12 sec? can tell if 35% talent is taken from points
				-- {cdCle2,["spellId"]=18562,	["priority"]=24,	["duration"]=15},--Swiftmend
				{cdCle2,["spellId"]=102693,	["priority"]=25,	["duration"]=20, --Grove Guardians, todo? there's a -3 sec talent
					["charges"]=3},
				{cdCle1,["spellId"]=102342,	["priority"]=28,	["duration"]=90},--Ironbark
			}
			
			
			hasuitFramesCenterSetEventType("aura")
			hasuitSetupFrameOptions = {danAuraPoints2CooldownReductionExternal,["CDr"]=20,["affectedSpells"]={102342},["loadOn"]=danCooldownDisplayLoadOn,["points2"]=0} --Ironbark
			initialize(102342) --Ironbark
			
		end


		defensiveCooldowns["DEATHKNIGHT"]={
			{cdCle2,["spellId"]=48792,	["priority"]=20,	["duration"]=120},--Icebound Fortitude
			{cdCle2,["spellId"]=48707,	["priority"]=21,	["duration"]=40},--Anti-Magic Shell, 60 base, talent for -20, different talent for +20
			{cdCle2,["spellId"]=410358,	["priority"]=21,	["duration"]=30},--Anti-Magic Shell, external? todo dispel magic means +20 sec cd, there's another one 444740 that idk what's going on with it or whether it's something that should be tracked, categorized as guardian and seen way more times than this one or normal ams, maybe horsemen's aid
			{cdCle2,["spellId"]=51052,	["priority"]=22,	["duration"]=90},--Anti-Magic Zone, 120 base
		}
		-- defensiveCooldowns[250]={--Blood
		-- }
		-- defensiveCooldowns[251]={--Frost
		-- }
		-- defensiveCooldowns[252]={--Unholy
		-- }


		defensiveCooldowns["DEMONHUNTER"]={
			{cdCle2,["spellId"]=198589,	["priority"]=20,	["duration"]=60},--Blur
			{cleAura,["spellId"]=212800,["priority"]=20,	["duration"]=30},--Blur aura applied, happens before cast success so this works for tracking auto blur, could tell from aura duration too
			{cdCle2,["spellId"]=196555,	["priority"]=22,	["duration"]=180},--Netherwalk
			{cdCle2,["spellId"]=196718,	["priority"]=23,	["duration"]=180},--Darkness, base 300 sec
			{cleAura,["spellId"]=354610,["priority"]=24,	["duration"]=25, --Glimpse --25 sec?, low opacity
				["startAlpha"]=lowStartAlpha}, --?
			{cleAura,["spellId"]=206803,["priority"]=25,	["duration"]=90, --Rain From Above hidden new duration from 60
				["startAlpha"]=0},
			{cdCle2,["spellId"]=205604,	   ["group"]=26,	["duration"]=60, --Reverse Magic
				["startAlpha"]=0},
			
		}
		-- defensiveCooldowns[577]={--Havoc
		-- }
		-- defensiveCooldowns[581]={--Vengeance
		-- }
		
		


		defensiveCooldowns["EVOKER"]={
			{cdCle2,["spellId"]=363916,	["priority"]=21,	["duration"]=90, --Obsidian Scales
				["charges"]=2},
			{cdCle2,["spellId"]=374348,	["priority"]=22,	["duration"]=60},--Renewing Blaze, 90 base
			{cdCle2,["spellId"]=378441,	["priority"]=23,	["duration"]=45, --Time Stop, todo cooldown mod rate from this
				["startAlpha"]=0},
			{cleAurP,["spellId"]=370889,["priority"]=24,	["duration"]=60, --Twin Guardian (Rescue absorb), low opacity, todo hide if seen without absorb?
				["startAlpha"]=lowStartAlpha},
			-- {cdCle2,["spellId"]=370665,	["priority"]=24,	["duration"]=60, --Rescue?
		}
		-- defensiveCooldowns[1467]={--Devastation
		-- }
		defensiveCooldowns[1468]={--Preservation, todo track bleed dispel?
			{cdCle2,["spellId"]=370960,	["priority"]=20,	["duration"]=180},--Emerald Communion
		}
		defensiveCooldowns[1473]={--Augmentation
			{cleAura,["spellId"]=404381,["priority"]=25,	["duration"]=360},--Defy Fate --proc
		}
		tinsert(timeSkipAffectedSpells, 363916) --Obsidian Scales
		tinsert(timeSkipAffectedSpells, 374348) --Renewing Blaze
		tinsert(timeSkipAffectedSpells, 378441) --Time Stop
		tinsert(timeSkipAffectedSpells, 370889) --Twin Guardian


		defensiveCooldowns["MONK"]={
			{cdCle2,["spellId"]=115203,	["priority"]=22,	["duration"]=120},--Fortifying Brew new duration was 360, todo maybe -30 sec from talent?
			{cdCle2,["spellId"]=122783,	["priority"]=23,	["duration"]=90, --Diffuse Magic low opacity
				["startAlpha"]=lowStartAlpha},
		}
		defensiveCooldowns[268]={--Brewmaster
			{cdCle2,["spellId"]=122278,	["priority"]=24,	["duration"]=120, --Dampen Harm low opacity, was all specs
				["startAlpha"]=lowStartAlpha},
		}
		defensiveCooldowns[269]={--Windwalker
			{cdCle2,["spellId"]=122470,	["priority"]=21,	["duration"]=90},--Touch of Karma --125174 alt spellid?
		}
		defensiveCooldowns[270]={--Mistweaver
			{cdCle2,["spellId"]=388615,	["priority"]=19,	["duration"]=180},--Restoral, todo -1sec from vivify crits
			{cdCle2,["spellId"]=115310,	["priority"]=19,	["duration"]=180},--Revival
			{cdCle2,["spellId"]=116849,	["priority"]=20,	["duration"]=75},--Life Cocoon, base 120, todo -75% from heart of the jade serpent
		}
		hasuitFramesCenterSetEventType("cleu")
		-- hasuitSetupFrameOptions = {danCleuAppliedCooldownReductionSourceIsDest,["CDr"]=60,["affectedSpells"]={388615, 115310},["loadOn"]=danCooldownDisplayLoadOn} --peaceweaver
		hasuitSetupFrameOptions = {danCleuAppliedCooldownReductionSourceIsDest,["CDr"]=30,["affectedSpells"]={388615, 115310},["loadOn"]=danCooldownDisplayLoadOn} --peaceweaver?
		initialize(353319) --peaceweaver
		


		defensiveCooldowns["WARRIOR"]={ --todo track rallying cry if [Master and Commander]?
			{cdCle2,["spellId"]=383762,	["priority"]=22,	["duration"]=180, --Bitter Immunity
				["startAlpha"]=lowStartAlpha},
			{cdCle2,["spellId"]=23920,	["priority"]=23,	["duration"]=23.75},--Spell Reflection, there's a talent that reduces by 5%? base 25
			{cdCle2,["spellId"]=202168,	["priority"]=24,	["duration"]=25},--Impending Victory, todo this can reset?
			{cdCle2,["spellId"]=384100,	["priority"]=25,	["duration"]=60, --Berserker Shout? aoe fear break/immunity
				["startAlpha"]=lowStartAlpha,["size"]=22}, --not sure about tracking this
		}
		defensiveCooldowns[71]={--Arms
			{cdCle2,["spellId"]=118038,	["priority"]=21,	["duration"]=85.5},--Die by the Sword, base 120, 5% and -30
		}
		defensiveCooldowns[72]={--Fury
			{cdCle2,["spellId"]=184364,	["priority"]=21,	["duration"]=114},--Enraged Regeneration, base 120
		}
		-- defensiveCooldowns[73]={--Protection
		-- }


		defensiveCooldowns["HUNTER"]={ --todo roar of sac?
			{cdCle2,["spellId"]=186265,	["priority"]=22,	["duration"]=150},--Aspect of the Turtle, 180 base, new duration was 124, todo do people take that 30 talent?
			{cdCle2,["spellId"]=264735,	["priority"]=23,	["duration"]=90,--Survival of the Fittest, 120 base, new duration was 144 1 charge
				["charges"]=2},
			{cdCle2,["spellId"]=109304,	["priority"]=24,	["duration"]=102},--Exhilaration, 120 base, todo 10 focus spent is -1 sec
			{cleAura,["spellId"]=202748,["priority"]=25,	["duration"]=31},--Survival Tactics --30 base, there's only UNIT_AURA removed for this, no cleu, gets affected by function hasuitFeignDeath
		}
		-- defensiveCooldowns[253]={--Beast Mastery
		-- }
		-- defensiveCooldowns[254]={--Marksmanship
		-- }
		defensiveCooldowns[255]={--Survival
			{cdCle2,["spellId"]=212640,	["priority"]=26,	["duration"]=25},--Mending Bandage
		}

		defensiveCooldowns["WARLOCK"]={
			{cdCle2,["spellId"]=104773,	["priority"]=22,	["duration"]=180},--Unending Resolve, 180 base, -45 sec or 55% damage reduction instead of 40%, todo check points
			{cdCle2,["spellId"]=108416,	["priority"]=23,	["duration"]=45},--Dark Pact --do people take the -15 sec? base 60
			{cdCle2,["spellId"]=452930,	["priority"]=24,	["duration"]=60},--Demonic Healthstone
			{cdCle2,["spellId"]=6262,	["priority"]=24,	["duration"]=600},--Healthstone --todo
			{cdCle2,["spellId"]=212295,	["priority"]=25,	["duration"]=45, --Nether Ward
				["startAlpha"]=lowStartAlpha},
			{cdCle2,["spellId"]=48020,	["priority"]=26,	["duration"]=30} --Demonic Circle: Teleport
		}
		-- defensiveCooldowns[265]={--Affliction
		-- }
		-- defensiveCooldowns[266]={--Demonology
		-- }
		-- defensiveCooldowns[267]={--Destruction
		-- }

		defensiveCooldowns["MAGE"]={
			{cdCle2,["spellId"]=45438,	["priority"]=21,	["duration"]=180, --Ice Block --base 240, do people take the -60 sec cd talent 2/2?
				["isPrimary"]=true},
			{cdCle2,["spellId"]=414658,	["priority"]=21,	["duration"]=180},--Ice Cold ^
			{cdCle2,["spellId"]=110960,	["priority"]=23,	["duration"]=120},--Greater Invisibility do people take the -45 sec pvp talent?
			{cdCle2,["spellId"]=414660,	["priority"]=24,	["duration"]=180, --Mass Barrier --todo hides when mass invis is seen?, new duration was 120
				["startAlpha"]=0},
			{cleAura,["spellId"]=342246,["priority"]=26,	["duration"]=50},--Alter Time, base 60
		}
		defensiveCooldowns[62]={--Arcane
			{cdCle2,["spellId"]=198111,	["priority"]=22,	["duration"]=45},--Temporal Shield
			{cdCle2,["spellId"]=235450,	["priority"]=25,	["duration"]=25},--Prismatic Barrier
		}
		defensiveCooldowns[63]={--Fire
			{cleAura,["spellId"]=87023,	["priority"]=22,	["duration"]=300},--Cauterize, new talent that resets frost cds except for ice block or others 240 or greater base cd
			{cdCle2,["spellId"]=235313,	["priority"]=25,	["duration"]=25},--Blazing Barrier
		}
		defensiveCooldowns[64]={--Frost
			{cdCle2,["spellId"]=235219,	["priority"]=22,	["duration"]=300},--Cold Snap, new talent that resets fire spells <240, todo no way to tell someone's playing it other than talents but that talent seems bad
			{cdCle2,["spellId"]=11426,	["priority"]=25,	["duration"]=25},--Ice Barrier --todo 30% faster recharg while shield persists on all barriers, not sure about mass barrier
		}
		
		tinsert(shiftingPowerAffectedSpells, 45438)
		tinsert(shiftingPowerAffectedSpells, 414658)
		tinsert(shiftingPowerAffectedSpells, 110960)
		tinsert(shiftingPowerAffectedSpells, 414660)
		tinsert(shiftingPowerAffectedSpells, 342246)
		tinsert(shiftingPowerAffectedSpells, 198111)
		tinsert(shiftingPowerAffectedSpells, 235450)
		tinsert(shiftingPowerAffectedSpells, 87023)
		tinsert(shiftingPowerAffectedSpells, 235313)
		tinsert(shiftingPowerAffectedSpells, 235219)
		tinsert(shiftingPowerAffectedSpells, 11426) --todo separate and only do stuff for appropriate unit type -- not relevant anymore/maybe ever
		
		tinsert(coldSnapAffectedSpells, 45438) --apparently you can snap while cced now, just rmp things
		tinsert(coldSnapAffectedSpells, 414658)
		tinsert(coldSnapAffectedSpells, 11426)
		
		hasuitFramesCenterSetEventType("aura")
		hasuitSetupFrameOptions = {danAuraHypoCooldownFunction,["affectedSpells"]={45438,414658,235219},["affectedSpellsPairs"]={[45438]=true,[414658]=true,[235219]=true},["unitClass"]="MAGE",["loadOn"]=danCooldownDisplayLoadOn}
		initialize(41425) --Hypothermia
		
		
		defensiveCooldowns["SHAMAN"]={ --todo [Stone Bulwark Totem]?
			{cdCle2,["spellId"]=108271,	["priority"]=22,	["duration"]=120},--Astral Shift
			{cdCle2,["spellId"]=409293,	["priority"]=23,	["duration"]=120, --Burrow
				["startAlpha"]=lowStartAlpha},
			{cdHeal,["spellId"]=31616,	["priority"]=25,	["duration"]=30},--Nature's Guardian, base 45, todo if it heals for 30% instead of 20% the cd is 30 instead of 45, could tell for sure if it's 45 if they have 3 charges higher on earth shield but they could go other tree too
			-- {cdCle2,["spellId"]=8143,	   ["group"]=26,	["duration"]=54},--Tremor Totem --base 60, todo totemic recall, todo hide tremor if it's irrelevant?, todo [Swift Recall]
			{cdCle2,["spellId"]=8143,	["priority"]=26,	["duration"]=54, --Tremor Totem
				["size"]=22},
		}
		-- defensiveCooldowns[262]={--Elemental
		-- }
		-- defensiveCooldowns[263]={--Enhancement
		-- }
		defensiveCooldowns[264]={--Restoration
			{cdCle2,["spellId"]=98008,	["priority"]=24,	["duration"]=174},--Spirit Link Totem
		}
		hasuitSetupFrameOptions = {danAuraPoints1CooldownReduction,["CDr"]=30,["affectedSpells"]={108271},["loadOn"]=danCooldownDisplayLoadOn,["points1"]=-40} --Astral Shift
		initialize(108271) --Astral Shift

		
		do
			hasuitVanish120 = {cleAura,["spellId"]=11327,	["priority"]=22,	["duration"]=120, --Vanish 120
				["charges"]=2}
			hasuitVanish96 = {cleAura,["spellId"]=11327,	["priority"]=22,	["duration"]=96, --Vanish 96
				["charges"]=2}
				
				
			defensiveCooldowns["ROGUE"]={
				{cdCle2,["spellId"]=31224,	["priority"]=21,	["duration"]=120},--Cloak of Shadows, todo [Bait and Switch]
				hasuitVanish120, --Vanish, todo if they don't have subterfuge make it 1 charge for that rogue, todo make it possible to show same spellid twice? maybe this should be in offensive too for sub rogue because of the cd reduction
				{cdCle2,["spellId"]=5277,	["priority"]=23,	["duration"]=120},--Evasion, elusiveness also reduces damage by 20%
				{cleAura,["spellId"]=45182,	["priority"]=24,	["duration"]=360},--Cheating Death
			}
			-- defensiveCooldowns[259]={--Assassination
			-- }
			-- defensiveCooldowns[260]={--Outlaw
			-- }
			-- defensiveCooldowns[261]={--Subtlety
			-- }
			
			tinsert(vanishAffectedSpells, 31224) --Cloak of Shadows
			tinsert(vanishAffectedSpells, 5277) --Evasion
			
			
			
			
			hasuitFramesCenterSetEventType("cleu")
			
			hasuitSetupFrameOptions = {danCleuAppliedCooldownReductionThiefsBargain354827,["CDr"]=24,["affectedSpells"]={11327},["loadOn"]=danCooldownDisplayLoadOn} --Vanish
			initialize(354827) --Thief's Bargain
		end 
		

		defensiveCooldowns["PRIEST"]={
			{cdCle2,["spellId"]=108968,	["priority"]=22,	["duration"]=300},--Void Shift
			{cleAura,["spellId"]=408558,["priority"]=27,	["duration"]=20, --Phase Shift from fade, base 30
				["startAlpha"]=lowStartAlpha},
		}
		defensiveCooldowns[256]={--Discipline
			{cdCle1,["spellId"]=33206,	["priority"]=21,	["duration"]=180, --Pain Suppression
				["charges"]=2},
			{cdCle2,["spellId"]=47536,	["priority"]=24,	["duration"]=90},--Rapture
			-- {cdCle2,["spellId"]=421453,	["priority"]=23,	["duration"]=240},--Ultimate Penitence, todo each penance bolt -2 sec cd if they take it, and change below if so
			{cdCle2,["spellId"]=62618,	["priority"]=25,	["duration"]=180},--Power Word: Barrier, only 20% now?
			{cdCle2,["spellId"]=271466,	["priority"]=25,	["duration"]=180},--Luminous Barrier
		}
		defensiveCooldowns[257]={--Holy
			{cdCle2,["spellId"]=47788,	["priority"]=21,	["duration"]=71.1},--Guardian Spirit, todo -2 sec if not playing new talent
			{cdCle2,["spellId"]=215769,	["priority"]=24,	["duration"]=120, --Spirit of Redemption
				["startAlpha"]=lowStartAlpha},
			{cdCle2,["spellId"]=197268,	["priority"]=25,	["duration"]=90, --Ray of Hope, todo bar
				["startAlpha"]=lowStartAlpha},
			{cdCle2,["spellId"]=328530,	["priority"]=28,	["duration"]=60, --Divine Ascension
				["startAlpha"]=0},
		}
		defensiveCooldowns[258]={--Shadow
			{cdCle2,["spellId"]=47585,	["priority"]=21,	["duration"]=90},--Dispersion, base 120
			{cdCle2,["spellId"]=19236,	["priority"]=26,	["duration"]=90},--Desperate Prayer do people take -20 sec Angel's Mercy?, 
			{cdCle2,["spellId"]=15286,	["priority"]=28,	["duration"]=90},--Vampiric Embrace
		}
		
		hasuitSetupFrameOptions = {danCleuSuccessCooldownReduction,["CDr"]=3,["affectedSpells"]={33206},["loadOn"]=danCooldownDisplayLoadOn} --Pain Suppression, todo ignore unless disc and tracking pain supp
		initialize(17) --Power Word: Shield
		initialize(47536) --Rapture --this instead of shield aura applied because of spellsteal? not sure if that would cause problems, also shielding into a cyclone or something like that probably prevents aura applied
		
		hasuitSetupFrameOptions = {danCleuHealCooldownReduction,["CDr"]=-108.9,["affectedSpells"]={47788},["loadOn"]=danCooldownDisplayLoadOn} --Guardian Spirit
		initialize(48153) --Guardian Spirit proc
		
		
		do
			local blessingOfProtection1 = 
				{cdCle2,["spellId"]=1022,	["priority"]=24,	["duration"]=240,--Blessing of Protection 1 charge, base 300
					["charges"]=1}
			local blessingOfSpellwarding1 = 
				{cdCle2,["spellId"]=204018,	["priority"]=24,	["duration"]=240,--Blessing of Spellwarding 1 charge, base 300
					["charges"]=1}
			local blessingOfProtection2 = 
				{cdCle2,["spellId"]=1022,	["priority"]=24,	["duration"]=240,--Blessing of Protection 2 charges, base 300, todo show forbearance properly for 2 charges, todo spec swapping update correctly
					["charges"]=2}
			
			
			defensiveCooldowns["PALADIN"]={
				{cdCle2,["spellId"]=642,	["priority"]=22,	["duration"]=210, --Divine Shield, base 300
					["isPrimary"]=true},
				{cdCle2,["spellId"]=633,	["priority"]=23,	["duration"]=420},--Lay on Hands, base 600, todo cd based on missing health healing hands
			}
			defensiveCooldowns[65]={--Holy
				{cdCle2,["spellId"]=498,	["priority"]=20,	["duration"]=42},--Divine Protection, base 60, holy
				blessingOfProtection2,
			}
			defensiveCooldowns[66]={--Protection
				blessingOfProtection1,
				blessingOfSpellwarding1,
			}
			defensiveCooldowns[70]={--Retribution --todo sanc
				{cdCle2,["spellId"]=403876,	["priority"]=20,	["duration"]=63},--Divine Protection, base 90, ret
				{cdCle2,["spellId"]=184662,	["priority"]=21,	["duration"]=63},--Shield of Vengeance
				blessingOfProtection1,
				blessingOfSpellwarding1,
				-- {cdCle2,["spellId"]=210256,	   ["group"]=26,	["duration"]=45},--Blessing of Sanctuary, group only, todo separate it from defensives? maybe just put it in its own controller, maybe get rid of unitType priority stuff if i do that
				{cdCle2,["spellId"]=210256,	["priority"]=26,	["duration"]=45, --Blessing of Sanctuary
					["size"]=22},
			}
			
			
			hasuitFramesCenterSetEventType("aura")
			hasuitSetupFrameOptions = {danAuraHypoCooldownFunction,["affectedSpells"]={642,633,1022,204018},["unitClass"]="PALADIN",["loadOn"]=danCooldownDisplayLoadOn}
			initialize(25771) --Forbearance
			
			hasuitSetupFrameOptions = {danAuraPoints1HidesOther,["points1"]=-40,["hideSpellId"]=184662,["loadOn"]=danCooldownDisplayLoadOn} --Shield of Vengeance
			initialize(403876) --Divine Protection
			
		end
	end
	
	
	hasuitFramesCenterSetEventType("cleu")
	
	if #shiftingPowerAffectedSpells>0 then
		hasuitSetupFrameOptions = {danCleuSuccessCooldownReduction,["CDr"]=3,["affectedSpells"]=shiftingPowerAffectedSpells,["loadOn"]=danCooldownDisplayLoadOn}
		initialize(382445) --Shifting Power CDr
	end
	if #coldSnapAffectedSpells>0 then
		hasuitSetupFrameOptions = {danCleuSuccessCooldownReduction,["CDr"]="reset",["affectedSpells"]=coldSnapAffectedSpells,["loadOn"]=danCooldownDisplayLoadOn}
		initialize(235219) --Cold Snap
	end
	
	
	if #vanishAffectedSpells>0 then
		hasuitSetupFrameOptions = {danCleuSuccessCooldownReductionSpec,["CDr"]=22.5,["affectedSpells"]=vanishAffectedSpells,["specId"]=261,["loadOn"]=danCooldownDisplayLoadOn}
		initialize(1856) --Vanish for sub rogue --different for pvp?.. 22.5 instead of 30 but can i trust the tooltip? todo find other pvp only durations
	end
	
	
	
	
	hasuitSetupFrameOptions = {danCleu378441TimeStop,["loadOn"]=danCooldownDisplayLoadOn} --Time Stop cooldown pause
	initialize(378441)
	
	
	
	
	
	
	
	if #timeSkipAffectedSpells>0 then
		hasuitFramesCenterSetEventType("aura")
		hasuitSetupFrameOptions = {danAuraDurationCooldownReduction,["CDr"]=30,["affectedSpells"]=timeSkipAffectedSpells,["loadOn"]=danCooldownDisplayLoadOn,["duration"]=3} --todo assume 10% until cast duration is seen and then change it if 3 sec talent is taken? hopefully aug gets tank treatment so this doesn't matter much except in m+
		initialize(404977) --Time Skip
		hasuitSetupFrameOptions = {danAuraDurationCooldownReduction,["CDr"]=20,["affectedSpells"]=timeSkipAffectedSpells,["loadOn"]=danCooldownDisplayLoadOn,["duration"]=2}
		initialize(404977) --Time Skip
	end
	
end











do
	local allCooldownsTable = {
		hasuitTrinketCooldowns,
		hasuitInterruptCooldowns,
		hasuitDefensiveCooldowns,
	}
	local lastFunction
	for i=1,#allCooldownsTable do
		local spellIdMerger = {}
		for spec, specCooldowns in pairs(allCooldownsTable[i]) do
			for j=1,#specCooldowns do
				local cooldownOptions = specCooldowns[j]
				local spellId = cooldownOptions["spellId"]
				local spellIdMergerTable = spellIdMerger[spellId]
				if not spellIdMergerTable then
					spellIdMerger[spellId] = {}
					spellIdMergerTable = spellIdMerger[spellId]
				end
				local alreadyHave
				for k=1,#spellIdMergerTable do
					if cooldownOptions[1]==spellIdMergerTable[k][1] then
						alreadyHave = true
						-- danPrint("spellIdMergerTable", spellId)
						break
					end
				end
				if not alreadyHave then
					tinsert(spellIdMergerTable, cooldownOptions)
					if lastFunction~=cooldownOptions[1] then
						lastFunction = cooldownOptions[1]
						hasuitFramesCenterSetEventTypeFromFunction(lastFunction)
					end
					cooldownOptions["loadOn"]=danCooldownDisplayLoadOn
					hasuitSetupFrameOptions = cooldownOptions
					initialize(spellId) --this whole do end section not super ideal but i think this is the best way to do it since all spell stuff needs to be as easy to see and make changes to as possible. doing the same setup as general/class spells above with the cooldowns would make it way worse to maintain. is that how people use the word maintain
				end
			end
		end
	end
end

function hasuitResetCooldowns(frame) --should have just done the oncooldowndone function for every icon that's on cd here? not sure why i didn't. this was a source of multiple random things i had to come back to and fix afterward
	local controller
	local wasOtherUnitType
	for basePriority, icon in pairs(frame.cooldownPriorities) do
		if icon.priority==256 or icon.maxCharges then --todo make a better variable for this
			-- danPrintBig("hasuitResetCooldowns", frame.unit, icon.priority, basePriority)
			icon.priority = basePriority
			icon.cooldown:Clear()
			-- icon.alpha = 1
			icon:SetAlpha(icon.alpha)
			-- danPrint("hasuitResetCooldowns")
			icon.expirationTime = nil
			if icon.hypoExpirationTime then
				icon.hypoExpirationTime = nil
				if icon.specialTimer then
					icon.specialTimer:Cancel()
					icon.specialTimer = nil
				end
			end
			if icon.cooldownTextTimer1 then
				icon.cooldownTextTimer1:Cancel()
				icon.cooldownTextTimer2:Cancel()
				icon.cooldownText:SetText("")
			end
			if icon.maxCharges then --should probably have based this on .charges instead? and above
				if icon.maxCharges>1 then
					icon.text:SetText(icon.maxCharges)
					local charges = icon.charges
					if charges and charges<=0 then
						icon.cooldownText:ClearAllPoints() --i mean some stuff is spread out so much in random places that should have been kept easier to manage, but hopefully i'll never have to look at this again
						icon.cooldownText:SetPoint("CENTER", icon, "CENTER", 1, 0) --this counteracts the only way that cooldowntext gets moved above for charges in the first place so should be good?
					end
				else
					icon.text:SetText("")
				end
				icon.charges = false
			end
		end
		
		if controller~=icon.controller then
			controller = icon.controller
			local unitTypeStuff = controller.options[frame.unitType]
			if controller.unitTypeStuff~=unitTypeStuff then
				controller.unitTypeStuff = unitTypeStuff
				wasOtherUnitType = true
			end
			hasuitSortController(controller)
		end
		if wasOtherUnitType then
			icon:ClearAllPoints()
		end
	end
	
	if frame.thiefsBargain then
		frame.thiefsBargain = false --could make this work for any spell pretty easily if there's ever more than 1 like this, rename .thiefsBargain and it points to the pre-change table instead of true/false. something a bit more if multiple can be like that for the same class
		frame.cooldownOptions[11327] = hasuitVanish120
	end
end
