


local CreateFrame = CreateFrame
local hasuitFramesParent = CreateFrame("Frame", "hasuitFramesParent", UIParent)
hasuitFramesParent:SetIgnoreParentScale(true)
hasuitFramesParent:SetSize(1,1)
hasuitFramesParent:SetPoint("CENTER")
hasuitFramesParent:SetFrameStrata("LOW")
hasuitFramesParent:SetFrameLevel(11)

-- hasuitLoginTime = GetTime()
hasuitPlayerGUID = UnitGUID("player")
hasuitPlayerClass = UnitClassBase("player")

hasuitOutOfRangeAlpha = 0.55
hasuitCcBreakHealthThreshold = 460000 --todo base it on level or patch or something? to not have to change this in the future
hasuitCcBreakHealthThresholdPve = 280000

hasuitClassColorsHexList = { --string.format("Hexadecimal: %X", number)
    ["DEATHKNIGHT"] = "|cffC41E3A",
    ["DEMONHUNTER"] = "|cffA330C9",
    ["DRUID"] = "|cffFF7C0A",
    ["EVOKER"] = "|cff33937F",
    ["HUNTER"] = "|cffAAD372",
    ["MAGE"] = "|cff3FC7EB",
    ["MONK"] = "|cff00FF98",
    ["PALADIN"] = "|cffF48CBA",
    ["PRIEST"] = "|cffFFFFFF",
    ["ROGUE"] = "|cffFFF468",
    ["SHAMAN"] = "|cff0070DD",
    ["WARLOCK"] = "|cff8788EE",
    ["WARRIOR"] = "|cffC69B6D",
}

hasuitSpecIsHealerTable = {
    [105] = true, --resto druid
    [1468] = true, --preservation
    [270] = true, --mistweaver
    [65] = true, --holy paladin
    [256] = true, --disc
    [257] = true, --holy priest
    [264] = true, --rsham
}







hasuitUnitFrameForUnit = {}
hasuitFrameTypeUpdateCount = {}

hasuitUnitFramesForUnitType = {
    ["group"] = {},
    ["pet"] = {},
    ["arena"] = {},
}
hasuitUpdateAllUnitsForUnitType = {}

hasuitFramesCenterNamePlateGUIDs = {}

hasuitTrackedRaceCooldowns = {}



hasuitSavedVariables = {} --for things in the future like keeping track of how long spent offline/update cooldowns of people from that if it was short enough, maybe fix pvp countdown after a reload






hasuitDoThisAddon_Loaded = {} --not accessible from external addons
hasuitDoThisPlayer_Login = hasuitDoThisPlayer_Login or {} --can sync any addons together here, give them these or other functions/run things in certain orders, other addon should do the same thing with hasuitDoThisPlayer_Login = hasuitDoThisPlayer_Login or {} so that it doesn't matter which addon loads first
hasuitDoThisPlayer_Entering_WorldFirstOnly = {}
hasuitDoThisPlayer_Entering_WorldSkipsFirst = {}

hasuitDoThisGroup_Roster_UpdateAlways = {}
hasuitDoThisGroup_Roster_UpdateGroupSizeChanged = {}
-- hasuitDoThisGroup_Roster_UpdateWidthChanged --tinsert into .functions
-- hasuitDoThisGroup_Roster_UpdateHeightChanged --tinsert into .functions
-- hasuitDoThisGroup_Roster_UpdateColumnsChanged --tinsert into .functions
-- hasuitDoThisGroup_Roster_UpdateGroupSize_5 --tinsert into .functions
-- hasuitDoThisGroup_Roster_UpdateGroupSize_5_8 --tinsert into .functions


hasuitDoThisPlayer_Target_Changed = {}

hasuitDoThisUserOptionsLoaded = {} --not accessible from external addons, happens early on addon_loaded

-- hasuitDoThisOnUpdate(func)
-- hasuitDoThisOnUpdatePosition1(func)

-- hasuitDoThisAfterCombat(func)






-- hasuitDoThisGroupUnitUpdate_before = {} --normal
-- hasuitDoThisGroupUnitUpdate = {} --gives unitFrame as arg1
-- hasuitDoThisGroupUnitUpdate_after = {} --wipes at the end if it did anything
--these are for efficiently running functions on every group unitFrame every time there's a group update (usually group_roster_update but the function can come from unit_aura guid not matching or arena update stealing a group frame(s), or player_login
--the way it's set up allows for only running a function on every unitframe based on one condition changing and then not repeating the function on future group updates, until the condition you care about changes again
--example for properly using in testingExternalAddon.lua, will make a guide some time


-- hasuitDoThisGroupUnitUpdate_Positions_before = {} --normal, these wait for combat to drop
hasuitDoThisGroupUnitUpdate_Positions = {} --gives unitFrame as arg1
hasuitDoThisGroupUnitUpdate_Positions_after = {} --wipes at the end if it did anything











local GetInstanceInfo = GetInstanceInfo

local mainLoadOnFunctionSpammable
local tinsert = table.insert
do
    local danDoThisAddonLoaded = hasuitDoThisAddon_Loaded
    local danDoThisPlayerLogin = hasuitDoThisPlayer_Login
    local danDoThisEnteringFirst = hasuitDoThisPlayer_Entering_WorldFirstOnly
    local danFrame = CreateFrame("Frame")
    danFrame:RegisterEvent("ADDON_LOADED")
    danFrame:RegisterEvent("PLAYER_LOGIN")
    danFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    danFrame:SetScript("OnEvent", function(_,event,addonName)
        if event=="ADDON_LOADED" then
            if addonName=="HasuitFrames" then
                danFrame:UnregisterEvent("ADDON_LOADED")
                for i=1,#danDoThisAddonLoaded do
                    danDoThisAddonLoaded[i]()
                end
            end
            
        elseif event=="PLAYER_LOGIN" then
            danFrame:UnregisterEvent("PLAYER_LOGIN")
            for i=1,#danDoThisPlayerLogin do
                danDoThisPlayerLogin[i]()
            end
            
        elseif event=="PLAYER_ENTERING_WORLD" then
            for i=1,#danDoThisEnteringFirst do
                danDoThisEnteringFirst[i]()
            end
            mainLoadOnFunctionSpammable() --not really necessary since every groupsize loadon will also call this initially but oh well
            local danDoThisEnteringWorld = hasuitDoThisPlayer_Entering_WorldSkipsFirst
            danFrame:SetScript("OnEvent", function()
                local _, instanceType, _, _, _, _, _, instanceId = GetInstanceInfo()
                hasuitInstanceId = instanceId
                if instanceType~=hasuitInstanceType then
                    hasuitInstanceType = instanceType
                    mainLoadOnFunctionSpammable() --maybe just move this to loadons only to make it less confusing
                end
                for i=1,#danDoThisEnteringWorld do
                    danDoThisEnteringWorld[i]()
                end
            end)
            
        end
    end)
end







do --hasuitDoThisOnUpdate, hasuitDoThisOnUpdatePosition1
    local danDoThis
    local danFrame = CreateFrame("Frame")
    local function onUpdateFunction()
        local temp = danDoThis
        danDoThis = nil
        for i=1,#temp do
            temp[i]() --kind of catastrophic if an error happens here, pcall if quick fix is needed in the future, or setscript nil above at least, could maybe be fine to do that anyway and get rid of if not danDoThis
        end
        if not danDoThis then
            danFrame:SetScript("OnUpdate", nil) --is there a good way to not have to setscript onupdate an extra time if adding to the table mid-onupdate?
        end
    end
    function hasuitDoThisOnUpdate(func)
        if danDoThis then
            tinsert(danDoThis, func)
        else
            danDoThis = {func}
            danFrame:SetScript("OnUpdate", onUpdateFunction)
        end
    end
    function hasuitDoThisOnUpdatePosition1(func)
        if danDoThis then
            tinsert(danDoThis, 1, func)
        else
            danDoThis = {func}
            danFrame:SetScript("OnUpdate", onUpdateFunction)
        end
    end
    -- function hasuitDoThisOnUpdateSpecificPosition(func, index)
        -- if danDoThis then
            -- tinsert(danDoThis, index, func)
        -- else
            -- danDoThis = {func}
            -- danFrame:SetScript("OnUpdate", onUpdateFunction)
        -- end
    -- end
    -- function hasuitGetCurrentOnUpdateTable()
        -- return danDoThis
    -- end
end











do --hasuitDoThisAfterCombat
    local danDoThis
    local danFrame = CreateFrame("Frame")
    function hasuitDoThisAfterCombat(func)
        if danDoThis then
            tinsert(danDoThis, func)
        else
            danDoThis = {func}
            danFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        end
    end
    danFrame:SetScript("OnEvent", function()
        for i=1,#danDoThis do
            danDoThis[i]()
        end
        danDoThis = nil
        danFrame:UnregisterEvent("PLAYER_REGEN_ENABLED")
    end)
end

local GetNumGroupMembers = GetNumGroupMembers
do
    local danDoThisRelevantSizes = {}
    hasuitDoThisRelevantSizes = danDoThisRelevantSizes
    do
        local function getDoThisSizeTable(danSizeTable)
            local relevantGroupSizes = {functions={}}
            local j = 1
            for i=1,#danSizeTable do
                local relevantSize = danSizeTable[i]
                repeat
                    relevantGroupSizes[j] = relevantSize
                    j = j+1
                until j>relevantSize
            end
            tinsert(danDoThisRelevantSizes, relevantGroupSizes)
            return relevantGroupSizes
        end
        hasuitDoThisGroup_Roster_UpdateWidthChanged =       getDoThisSizeTable({5,8,15,20,24,28,32,36,40}) --todo make this kind of thing work the same way on a table like hasuitRaidFrameWidthForGroupSize? might be nice when useroptions can change frame size and stuff
        hasuitDoThisGroup_Roster_UpdateHeightChanged =      getDoThisSizeTable({8,10,15,40})
        hasuitDoThisGroup_Roster_UpdateColumnsChanged =     getDoThisSizeTable({5,8,20,24,28,32,36,40})
        hasuitDoThisGroup_Roster_UpdateGroupSize_5 =        getDoThisSizeTable({5,40})
        hasuitDoThisGroup_Roster_UpdateGroupSize_5_8 =      getDoThisSizeTable({5,8,40})
    end
    
    local danDoThisOnUpdate = hasuitDoThisOnUpdate
    local danDoThis = hasuitDoThisGroup_Roster_UpdateAlways
    local danDoThisGroupSizeChanged = hasuitDoThisGroup_Roster_UpdateGroupSizeChanged
    local danFrame = CreateFrame("Frame")
    danFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    tinsert(hasuitDoThisAddon_Loaded, 1, function() --ends up being #2 (for now?)
        for i=1,#danDoThisGroupSizeChanged do
            danDoThisGroupSizeChanged[i]()
        end
        for i=1,#danDoThisRelevantSizes do
            local sizeTable = danDoThisRelevantSizes[i]
            sizeTable.activeRelevantSize = sizeTable[hasuitGroupSize]
            local sizeFunctions = sizeTable.functions
            for j=1,#sizeFunctions do
                sizeFunctions[j]()
            end
        end
        for i=1,#danDoThis do
            danDoThis[i]()
        end
        
        
        -- danDoThisOnUpdate(function()
            -- danFrame:RegisterEvent("GROUP_ROSTER_UPDATE") --don't think rosterupdate and player_login can happen at the same time
        -- end)
        
        do
            local columnsForGroupSize = hasuitRaidFrameColumnsForGroupSize
            tinsert(hasuitDoThisGroup_Roster_UpdateColumnsChanged.functions, 1, function()
                hasuitRaidFrameColumns = columnsForGroupSize[hasuitGroupSize]
            end)
        end
    end)
    local function groupRosterUpdateFunction()
        local groupSize = GetNumGroupMembers()
        if groupSize == 0 then
            groupSize = 1
        end
        if groupSize~=hasuitGroupSize then
            hasuitGroupSize = groupSize
            
            for i=1,#danDoThisGroupSizeChanged do
                danDoThisGroupSizeChanged[i]()
            end
            
            for i=1,#danDoThisRelevantSizes do
                local sizeTable = danDoThisRelevantSizes[i]
                local relevantSize = sizeTable[groupSize]
                if sizeTable.activeRelevantSize~=relevantSize then
                    sizeTable.activeRelevantSize = relevantSize
                    local sizeFunctions = sizeTable.functions
                    for j=1,#sizeFunctions do
                        sizeFunctions[j]()
                    end
                end
            end
        end
        for i=1,#danDoThis do
            danDoThis[i]()
        end
    end
    danFrame:SetScript("OnEvent", groupRosterUpdateFunction) --GROUP_ROSTER_UPDATE
    
    
end


hasuitRaidFrameWidthForGroupSize = { --hasuitDoThisGroup_Roster_UpdateWidthChanged
    [0]=114,
    114,--1
    114,--2
    114,--3
    114,--4
    114,--5
    
    110,--6
    110,--7
    110,--8
    
    100,--9
    100,--10
    100,--11
    100,--12
    100,--13
    100,--14
    100,--15
    
    98,--16
    98,--17
    98,--18
    98,--19
    98,--20
    
    94,--21
    94,--22
    94,--23
    94,--24
    
    90,--25
    90,--26
    90,--27
    90,--28
    
    86,--29
    86,--30
    86,--31
    86,--32
    
    82,--33
    82,--34
    82,--35
    82,--36
    
    78,--37
    78,--38
    78,--39
    78,--40
}
hasuitRaidFrameHeightForGroupSize = { --hasuitDoThisGroup_Roster_UpdateHeightChanged
    [0]=90,--0 --bored todo make it so that hasuitGroupSize can be 0 and not matter, maybe already could remove the check that makes it 1?
    90,--1
    90,--2
    90,--3
    90,--4
    90,--5
    90,--6
    90,--7
    90,--8
    
    83,--9
    83,--10, was 76 up to here
    
    63,--11
    63,--12
    63,--13
    63,--14
    63,--15 was 62
    
    49,--16
    49,--17
    49,--18
    49,--19
    49,--20
    49,--21
    49,--22
    49,--23
    49,--24
    49,--25
    49,--26
    49,--27
    49,--28
    49,--29
    49,--30
    49,--31
    49,--32
    49,--33
    49,--34
    49,--35
    49,--36
    49,--37
    49,--38
    49,--39
    49,--40
}
hasuitRaidFrameColumnsForGroupSize = { --hasuitDoThisGroup_Roster_UpdateColumnsChanged
    [0]=1,--0
    1,--1
    1,--2
    1,--3
    1,--4
    1,--5, columns up to here do nothing atm
    
    4,--6
    4,--7
    4,--8
    
    5,--9
    5,--10
    5,--11
    5,--12
    5,--13
    5,--14
    5,--15
    5,--16
    5,--17
    5,--18
    5,--19
    5,--20
    
    6,--21
    6,--22
    6,--23
    6,--24
    
    7,--25
    7,--26
    7,--27
    7,--28
    
    8,--29
    8,--30
    8,--31
    8,--32
    
    9,--33
    9,--34
    9,--35
    9,--36
    
    10,--37
    10,--38
    10,--39
    10,--40
}










local type = type
local pairs = pairs
local tremove = tremove

local allTable = {}


local function mainLoadOnFunction()
    for dan=1, #allTable do
        local loadedTable = allTable[dan][1]
        local unloadedTable = allTable[dan][2]
        for spellId, unloadedStuff in pairs(unloadedTable) do --not necessarily a spellId
            local loadedStuff
            local reloadCount = 0
            for i=#unloadedStuff, 1, -1 do
                local loadOn = unloadedStuff[i]["loadOn"]
                if not loadOn or loadOn.shouldLoad then
                    loadedStuff = loadedTable[spellId]
                    if not loadedStuff then
                        loadedTable[spellId] = {}
                        loadedStuff = loadedTable[spellId]
                    end
                    -- local loadFunction = unloadedStuff[i]["loadFunction"] --could do specific load/unload functions per spell like maybe clear an aura? probably won't ever have a good enough reason to uncomment these
                        -- if loadFunction then
                        -- loadFunction()
                    -- end
                    tinsert(loadedStuff, tremove(unloadedStuff, i))
                    reloadCount = reloadCount+1
                end
            end
            if not loadedStuff then 
                loadedStuff = loadedTable[spellId]
            end
            if loadedStuff then
                local numberOfAlreadyLoadedStuff = #loadedStuff-reloadCount
                if numberOfAlreadyLoadedStuff>0 then
                    for i=numberOfAlreadyLoadedStuff, 1, -1 do
                        local loadOn = loadedStuff[i]["loadOn"]
                        if loadOn and not loadOn.shouldLoad then
                            -- local unloadFunction = loadedStuff[i]["unloadFunction"]
                            -- if unloadFunction then
                                -- unloadFunction()
                            -- end
                            tinsert(unloadedStuff, tremove(loadedStuff, i))
                        end
                    end
                    if #loadedStuff==0 then
                        loadedTable[spellId] = nil
                    end
                end
            end
        end
    end
end
local GetTime = GetTime
local lastTime
local danPriorityOnUpdate = hasuitDoThisOnUpdatePosition1
function mainLoadOnFunctionSpammable()
    local currentTime = GetTime()
    if lastTime~=currentTime then
        lastTime = currentTime
        danPriorityOnUpdate(mainLoadOnFunction)
    end
end
hasuitMainLoadOnFunctionSpammable = mainLoadOnFunctionSpammable


local allTablePairsLoaded = {}
local allTablePairsUnloaded = {}
function hasuitFramesCenterAddToAllTable(tableForEventType, eventType)
    tinsert(allTable, {tableForEventType, {}})
    local dan = allTable[#allTable]
    allTablePairsLoaded[eventType] = dan[1]
    allTablePairsUnloaded[eventType] = dan[2]
end

local loadedTable
local unloadedTable
function hasuitFramesCenterSetEventType(eventType)
    loadedTable = allTablePairsLoaded[eventType]
    unloadedTable = allTablePairsUnloaded[eventType]
end

local functionsTableLoaded = {}
local functionsTableUnloaded = {}
function hasuitFramesCenterSetEventTypeFromFunction(func)
    loadedTable = functionsTableLoaded[func]
    unloadedTable = functionsTableUnloaded[func]
end

function hasuitFramesCenterAddMultiFunction(func)
    functionsTableLoaded[func] = loadedTable
    functionsTableUnloaded[func] = unloadedTable
    return func
end


local _, instanceType, _, _, _, _, _, instanceId = GetInstanceInfo()
hasuitInstanceType = instanceType
hasuitInstanceId = instanceId

local groupSize = GetNumGroupMembers()
if groupSize == 0 then
    groupSize = 1
end
hasuitGroupSize = groupSize
hasuitRaidFrameWidth = hasuitRaidFrameWidthForGroupSize[groupSize]
hasuitRaidFrameHeight = hasuitRaidFrameHeightForGroupSize[groupSize]
hasuitRaidFrameColumns = hasuitRaidFrameColumnsForGroupSize[groupSize]




function hasuitFramesInitialize(spellId) --not necessarily a spellId, todo should make a function to put all options of a controller into savedvariables sorted by priority or something like that? to make it easy to see what exactly is going on. automating priority here wouldn't be worth it i think
    local unloadedStuff = unloadedTable[spellId]
    if not unloadedStuff then
        unloadedTable[spellId] = {}
        unloadedStuff = unloadedTable[spellId]
    end
    
    local loadOn = hasuitSetupSpellOptions["loadOn"]
    if not loadOn or loadOn.shouldLoad then
        
        local loadedStuff = loadedTable[spellId]
        if not loadedStuff then
            loadedTable[spellId] = {}
            loadedStuff = loadedTable[spellId]
        end
        tinsert(loadedStuff, hasuitSetupSpellOptions)
    else
        tinsert(unloadedStuff, hasuitSetupSpellOptions)
    end
end

function hasuitFramesInitializeMulti(spellId, startI) --not necessarily a spellId
    for i=startI or 1, #hasuitSetupSpellOptionsMulti do
        local spellOptions = hasuitSetupSpellOptionsMulti[i]
        local unloadedTable = functionsTableUnloaded[spellOptions[1]]
        
        
        local unloadedStuff = unloadedTable[spellId]
        if not unloadedStuff then
            unloadedTable[spellId] = {}
            unloadedStuff = unloadedTable[spellId]
        end
        
        local loadOn = spellOptions["loadOn"]
        if not loadOn or loadOn.shouldLoad then
            local loadedTable = functionsTableLoaded[spellOptions[1]]
            
            local loadedStuff = loadedTable[spellId]
            if not loadedStuff then
                loadedTable[spellId] = {}
                loadedStuff = loadedTable[spellId]
            end
            tinsert(loadedStuff, spellOptions)
        else
            tinsert(unloadedStuff, spellOptions)
        end
    end
end


hasuitDiminishSpellOptionsTable = {}
hasuitTrackedDiminishSpells = {
    ["stun"]={},
    ["disorient"]={}, --fear
    ["root"]={},
    ["incapacitate"]={}, --sheep
    ["silence"]={},
    ["disarm"]={},
    -- ["knockback"]={},
}

do
    local GetSpellTexture = C_Spell.GetSpellTexture
    local diminishOptionsTable = hasuitDiminishSpellOptionsTable
    local drCount = 0
    local tonumber = tonumber
    function hasuitFramesTrackDiminishTypeAndTexture(drType, texture)
        if not diminishOptionsTable[drType] then
            if type(texture)=="string" then
                local pre = texture
                texture = GetSpellTexture(texture)
                if not texture then
                    if tonumber(pre) then
                        print("|cffff2222HasuitFrames error no texture for \""..pre.."\"|r. This looks like you need to remove the \"'s") --todo how to show which file/line this is coming from? Without needing people to add something to their private addon just for this. maybe something with debug --debugstack?
                    else
                        print("|cffff2222HasuitFrames error no texture for", pre, "|r. spell names have to be in current spellbook to get a texture from them. if you can't get a spell name to work try looking up the spell texture on wowhead. Click the icon there and the texture is the number to the right of ID:  , alternatively you can use /run print(C_Spell.GetSpellTexture(spell))")
                    end
                    return
                end
            end
            drCount = drCount+1
            diminishOptionsTable[drType] = {
                ["arena"] = drCount,
                ["texture"] = texture,
            }
        else
            print("|cffff2222HasuitFrames error attempting to track diminish type", drType, "twice, ignoring|r, everything should still work fine. Removing the duplicate will get rid of this error message")
        end
    end
end

local trackedDiminishSpells = hasuitTrackedDiminishSpells
local drSpellTable
function hasuitFramesCenterSetDrType(drType)
    drSpellTable = trackedDiminishSpells[drType]
end
function hasuitFramesInitializePlusDiminish(spellId)
    tinsert(drSpellTable, spellId)
    local unloadedStuff = unloadedTable[spellId]
    if not unloadedStuff then
        unloadedTable[spellId] = {}
        unloadedStuff = unloadedTable[spellId]
    end
    
    local loadOn = hasuitSetupSpellOptions["loadOn"]
    if not loadOn or loadOn.shouldLoad then
        
        local loadedStuff = loadedTable[spellId]
        if not loadedStuff then
            loadedTable[spellId] = {}
            loadedStuff = loadedTable[spellId]
        end
        tinsert(loadedStuff, hasuitSetupSpellOptions)
    else
        tinsert(unloadedStuff, hasuitSetupSpellOptions)
    end
end


local initializeMulti = hasuitFramesInitializeMulti
function hasuitFramesInitializeMultiPlusDiminish(spellId)
    -- hasuitDoThisEasySavedVariables(spellId, danTestingCollectionTableDiminish)
    tinsert(drSpellTable, spellId)
    initializeMulti(spellId)
end

































local namePlateGUIDs = hasuitFramesCenterNamePlateGUIDs
local danUnitFrameForUnit = hasuitUnitFrameForUnit
local UnitGUID = UnitGUID

local hasuitFramesCenterGUIDTrackerNameplateAdded = CreateFrame("Frame")
hasuitFramesCenterGUIDTrackerNameplateAdded:RegisterEvent("NAME_PLATE_UNIT_ADDED")
hasuitFramesCenterGUIDTrackerNameplateAdded:RegisterEvent("FORBIDDEN_NAME_PLATE_UNIT_ADDED")
hasuitFramesCenterGUIDTrackerNameplateAdded:SetScript("OnEvent", function(_, _, unit)
    local unitGUID = UnitGUID(unit)
    namePlateGUIDs[unitGUID] = unit
    danUnitFrameForUnit[unit] = danUnitFrameForUnit[unitGUID]
end)

local hasuitFramesCenterGUIDTrackerNameplateRemoved = CreateFrame("Frame")
hasuitFramesCenterGUIDTrackerNameplateRemoved:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
hasuitFramesCenterGUIDTrackerNameplateRemoved:RegisterEvent("FORBIDDEN_NAME_PLATE_UNIT_REMOVED")
hasuitFramesCenterGUIDTrackerNameplateRemoved:SetScript("OnEvent", function(_, _, unit)
    namePlateGUIDs[UnitGUID(unit)] = nil
    danUnitFrameForUnit[unit] = nil
end)


do
    local danDoThis = hasuitDoThisPlayer_Target_Changed
    local danFrame = CreateFrame("Frame")
    danFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    danFrame:SetScript("OnEvent", function()
        local unitGUID = UnitGUID("target")
        if unitGUID then
            danUnitFrameForUnit["target"] = danUnitFrameForUnit[unitGUID]
        else
            danUnitFrameForUnit["target"] = nil
        end
        for i=1,#danDoThis do
            danDoThis[i]()
        end
    end)
end

local hasuitFramesCenterGUIDTrackerFocusChanged = CreateFrame("Frame")
hasuitFramesCenterGUIDTrackerFocusChanged:RegisterEvent("PLAYER_FOCUS_CHANGED")
hasuitFramesCenterGUIDTrackerFocusChanged:SetScript("OnEvent", function()
    local unitGUID = UnitGUID("focus")
    if unitGUID then
        danUnitFrameForUnit["focus"] = danUnitFrameForUnit[unitGUID]
    else
        danUnitFrameForUnit["focus"] = nil
    end
end)

local hasuitFramesCenterGUIDTrackerMouseoverChanged = CreateFrame("Frame")
hasuitFramesCenterGUIDTrackerMouseoverChanged:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
hasuitFramesCenterGUIDTrackerMouseoverChanged:SetScript("OnEvent", function()
    local unitGUID = UnitGUID("mouseover")
    if unitGUID then
        danUnitFrameForUnit["mouseover"] = danUnitFrameForUnit[unitGUID]
    else
        danUnitFrameForUnit["mouseover"] = nil
    end
end)

local hasuitFramesCenterGUIDTrackerSoftFriendChanged = CreateFrame("Frame")
hasuitFramesCenterGUIDTrackerSoftFriendChanged:RegisterEvent("PLAYER_SOFT_FRIEND_CHANGED") --not sure soft unit stuff will ever have a use, i don't think events ever fire for them, or mouseover, but who knows
hasuitFramesCenterGUIDTrackerSoftFriendChanged:SetScript("OnEvent", function()
    local unitGUID = UnitGUID("softfriend")
    if unitGUID then
        danUnitFrameForUnit["softfriend"] = danUnitFrameForUnit[unitGUID]
    else
        danUnitFrameForUnit["softfriend"] = nil
    end
end)

local hasuitFramesCenterGUIDTrackerSoftEnemyChanged = CreateFrame("Frame")
hasuitFramesCenterGUIDTrackerSoftEnemyChanged:RegisterEvent("PLAYER_SOFT_ENEMY_CHANGED")
hasuitFramesCenterGUIDTrackerSoftEnemyChanged:SetScript("OnEvent", function()
    local unitGUID = UnitGUID("softenemy")
    if unitGUID then
        danUnitFrameForUnit["softenemy"] = danUnitFrameForUnit[unitGUID]
    else
        danUnitFrameForUnit["softenemy"] = nil
    end
end)



tinsert(hasuitDoThisPlayer_Entering_WorldFirstOnly, function() --a list, semi enforced naturally. todo add things that stay global and don't get set to nil as comments. This should hopefully be a comprehensive list of things that can be accessed from outside of the addon, not a full list of internal functions
    C_Timer.After(0, function() --hasuitSetupSpellOptions
        hasuitDoThisAddon_Loaded = nil
        hasuitDoThisPlayer_Login = nil
        hasuitDoThisPlayer_Entering_WorldFirstOnly = nil
        hasuitDoThisPlayer_Entering_WorldSkipsFirst = nil
        
        hasuitDoThisGroup_Roster_UpdateAlways = nil
        hasuitDoThisGroup_Roster_UpdateGroupSizeChanged = nil
        hasuitDoThisGroup_Roster_UpdateWidthChanged = nil
        hasuitDoThisGroup_Roster_UpdateHeightChanged = nil
        hasuitDoThisGroup_Roster_UpdateColumnsChanged = nil
        hasuitDoThisGroup_Roster_UpdateGroupSize_5 = nil
        hasuitDoThisGroup_Roster_UpdateGroupSize_5_8 = nil
        hasuitDoThisRelevantSizes = nil
        
        -- hasuitDoThisGroupUnitUpdate_before = nil
        -- hasuitDoThisGroupUnitUpdate = nil
        -- hasuitDoThisGroupUnitUpdate_after = nil
        -- hasuitDoThisGroupUnitUpdate_Positions_before = nil
        hasuitDoThisGroupUnitUpdate_Positions = nil
        hasuitDoThisGroupUnitUpdate_Positions_after = nil
        
        hasuitDoThisOnUpdate = nil
        hasuitDoThisOnUpdatePosition1 = nil
        hasuitDoThisPlayerTargetChanged = nil
        hasuitDoThisAfterCombat = nil
        
        hasuitDoThisPlayer_Target_Changed = nil
        hasuitDoThisUserOptionsLoaded = nil
        hasuitUserOptionsOnChanged = nil
        
        hasuitRaidFrameWidthForGroupSize = nil
        hasuitRaidFrameHeightForGroupSize = nil
        hasuitRaidFrameColumnsForGroupSize = nil
        
        hasuitUnitFrameForUnit = nil
        hasuitUpdateAllUnitsForUnitType = nil
        hasuitTrackedRaceCooldowns = nil
        hasuitFramesCenterNamePlateGUIDs = nil
        
        hasuitFramesInitialize = nil
        hasuitFramesInitializeMulti = nil
        hasuitFramesInitializeMultiPlusDiminish = nil
        hasuitSetupSpellOptionsMulti = nil
        hasuitFramesCenterAddMultiFunction = nil
        hasuitFramesCenterSetEventTypeFromFunction = nil
        hasuitFramesCenterAddToAllTable = nil
        hasuitFramesCenterSetEventType = nil
        
        hasuitDiminishSpellOptionsTable = nil
        hasuitTrackedDiminishSpells = nil
        hasuitFramesTrackDiminishTypeAndTexture = nil
        hasuitFramesCenterSetDrType = nil
        hasuitFramesInitializePlusDiminish = nil
        
        hasuitFramesSpellOptionsClassSpecificHarmful = nil
        hasuitFramesSpellOptionsClassSpecificHelpful = nil
        
        hasuitLoadOn_EnablePve = nil
        hasuitLoadOn_InstanceTypeNone = nil
        hasuitLoadOn_BgOnly = nil
        hasuitLoadOn_NotArenaOnly = nil
        hasuitLoadOn_ArenaOnly = nil
        hasuitLoadOn_RootCleuBreakable = nil
        hasuitLoadOn_PartySize = nil
        hasuitLoadOn_CooldownDisplay = nil
        
        
        hasuitSpellFunction_CleuCcBreakThreshold = nil
        hasuitSpellFunction_CleuInterrupted = nil
        hasuitSpellFunction_CleuINC = nil
        hasuitSpellFunction_CleuDiminish = nil
        hasuitSpellFunction_CleuSpellSummon = nil
        hasuitSpellFunction_CleuSuccessCooldownReduction = nil
        hasuitSpellFunction_CleuInterruptCooldownReduction = nil
        hasuitSpellFunction_CleuHealCooldownReduction = nil
        hasuitSpellFunction_CleuEnergizeCooldownReduction = nil
        hasuitSpellFunction_CleuAppliedCooldownReduction = nil
        hasuitSpellFunction_CleuSpellEmpowerInterruptCooldownReduction = nil
        hasuitSpellFunction_CleuAppliedCooldownReductionSourceIsDest = nil
        hasuitSpellFunction_CleuSuccessCooldownReductionSpec = nil
        hasuitSpellFunction_CleuInterruptCooldownReductionSolarBeam = nil
        hasuitSpellFunction_CleuAppliedCooldownReductionThiefsBargain354827 = nil
        hasuitSpellFunction_CleuSuccessCooldownStart1 = nil
        hasuitSpellFunction_CleuSuccessCooldownStart2 = nil
        hasuitSpellFunction_CleuHealCooldownStart = nil
        hasuitSpellFunction_CleuHealCooldownStart = nil
        hasuitSpellFunction_CleuSpellEmpowerStartCooldownStart2 = nil
        hasuitSpellFunction_CleuAppliedCooldownStart = nil
        hasuitSpellFunction_CleuRemovedCooldownStart = nil
        hasuitSpellFunction_CleuAppliedCooldownStartPreventMultiple = nil
        hasuitSpellFunction_CleuSuccessCooldownStartSolarBeam = nil
        hasuitSpellFunction_CleuSuccessCooldownStartPvPTrinket = nil
        hasuitSpellFunction_CleuAppliedCooldownStartRacial = nil
        hasuitSpellFunction_CleuAppliedRacialNotTrackedAffectingPvpTrinket = nil
        hasuitSpellFunction_Cleu378441TimeStop = nil
        hasuitSpellFunction_CleuCooldownStartPet = nil
        hasuitSpellFunction_CleuCasting = nil
        
        hasuitSpellFunction_UnitCastSucceededCooldownStart = nil
        hasuitSpellFunction_UnitCastSucceededChangedTalents = nil
        
        hasuitSpellFunction_UnitCastingMiddleCastBars = nil
        hasuitSpellFunction_UnitCasting = nil
        
        hasuitSpellFunction_AuraMainFunction = nil
        hasuitSpellFunction_AuraMainFunctionPveUnknown = nil
        hasuitSpellFunction_AuraSourceIsPlayer = nil
        hasuitSpellFunction_AuraSourceIsNotPlayer = nil
        hasuitSpellFunction_AuraPoints1Required = nil
        hasuitSpellFunction_AuraPoints2Required = nil
        hasuitSpellFunction_AuraHypoCooldownFunction = nil
        hasuitSpellFunction_AuraPoints1CooldownReduction = nil
        hasuitSpellFunction_AuraPoints2CooldownReduction = nil
        hasuitSpellFunction_AuraPoints2CooldownReductionExternal = nil
        hasuitSpellFunction_AuraPoints1HidesOther = nil
        hasuitSpellFunction_AuraDurationCooldownReduction = nil
        
        hasuitSpecialAuraFunction_CcBreakThreshold = nil
        hasuitSpecialAuraFunction_SmokeBombFunctionForArenaFrames = nil
        hasuitSpecialAuraFunction_SmokeBombForPlayer = nil
        hasuitSpecialAuraFunction_ShadowyDuel = nil
        hasuitSpecialAuraFunction_FeignDeath = nil
        hasuitSpecialAuraFunction_DarkSimShowingWhatGotStolen = nil
        hasuitSpecialAuraFunction_OrbOfPower = nil
        hasuitSpecialAuraFunction_FlagDebuffBg = nil
        hasuitSpecialAuraFunction_SoulOfTheForest = nil
        hasuitSpecialAuraFunction_SoulHots = nil
        hasuitSpecialAuraFunction_RedLifebloom = nil
        hasuitSpecialAuraFunction_CanChangeTexture = nil
        hasuitSpecialAuraFunction_BlessingOfAutumn = nil
        hasuitBlessingOfAutumnIgnoreList = nil
        
        
        hasuitGetIcon = nil
        hasuitGetCastBar = nil
        
        hasuitOutOfRangeAlpha = nil
        
        hasuitGetD2anCleuSubevent = nil
        hasuitGetD4anCleuSourceGuid = nil
        hasuitGetD12anCleuSpellId = nil
        
        hasuitRestoreCooldowns = nil
        
        hasuitMakeTestGroupFrames = nil
        hasuitMakeTestArenaFrames = nil
        
        hasuitRemoveUnitHealthControlNotSafe = nil
        hasuitRemoveUnitHealthControlSafe = nil
        
        hasuitSort = nil
        hasuitSortExpirationTime = nil
        hasuitSortPriorityExpirationTime = nil
        
        hasuitNormalGrow = nil
        hasuitMiddleGrow = nil
        hasuitMiddleCastBarsGrow = nil
        
        hasuitTrinketCooldowns = nil
        hasuitDefensiveCooldowns = nil
        hasuitInterruptCooldowns = nil
        hasuitCrowdControlCooldowns = nil
        
        -- hasuitInitializeSeparateController = nil
        hasuitCleanController = nil
        hasuitInitializeController = nil
        hasuitSortController = nil
        -- hasuitAddToSeparateController = nil
        
        hasuitController_TopRight_TopRight = nil
        hasuitController_TopLeft_TopLeft = nil
        hasuitController_TopLeft_TopRight = nil
        hasuitController_BottomLeft_BottomRight = nil
        hasuitController_TopRight_TopLeft = nil
        hasuitController_BottomRight_BottomLeft = nil
        hasuitController_Middle_Middle = nil
        
        hasuitController_BottomRight_BottomRight = nil
        hasuitController_BottomLeft_BottomLeft = nil
        
        hasuitController_Separate_UpperScreenCastBars = nil
        hasuitController_CooldownsControllers = nil
        
        danCommonMiddleCastBars1 = nil
        danCommonMiddleCastBars2 = nil
        danCommonMiddleCastBars3 = nil
        danCommonMiddleCastBars4 = nil
        danCommonMiddleCastBars5 = nil
        hasuitBigRedMiddleCastBarsSpellOptions =    nil
        hasuitBigGreenMiddleCastBarsSpellOptions =  nil
        hasuitYellowMiddleCastBarsSpellOptions =    nil
        hasuitRootMiddleCastBarsSpellOptions =      nil
        hasuitMiscMiddleCastBarsSpellOptions = nil
        hasuitCastBarFont20 = nil
        hasuitCastBarFont18 = nil
        hasuitCastBarFont15 = nil
        hasuitCastBar1Font = nil
        hasuitLocal1 = nil
        hasuitLocal2 = nil
        hasuitLocal3 = nil
        hasuitLocal4 = nil
        hasuitLocal5 = nil
        hasuitLocal6 = nil
        hasuitUnusedCastBars = nil
        
        hasuitResetCooldowns = nil
        hasuitSetIconText = nil
        hasuitUnusedTextFrames = nil
        hasuitCcBreakHealthThreshold = nil
        hasuitCcBreakHealthThresholdPve = nil
        hasuitClassColorsHexList = nil
        hasuitPlayerGUID = nil
        hasuitPlayerClass = nil
        hasuitSpecIsHealerTable = nil
        hasuitFrameTypeUpdateCount = nil
        hasuitUnitFramesForUnitType = nil
        hasuitStartCooldownTimerText = nil
        hasuitVanish96 = nil
        hasuitVanish120 = nil
        hasuitNpcIds = nil
        hasuitMainLoadOnFunctionSpammable = nil
        hasuitUnitAuraIsFullUpdate = nil
        
        hasuitCooldownTextFonts = nil
        
    end)
end)

