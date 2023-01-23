Lib.Register("comfort/GetEnemiesOfEntity");

GetEntitiesOfDiplomacyStateInArea_RelevantTypes = {};
GetEntitiesOfDiplomacyStateInArea_Cache = {
    [Diplomacy.Friendly] = {},
    [Diplomacy.Hostile] = {},
    [Diplomacy.Neutral] = {},
}

--- Returns enemies in the area.
---
--- (To improve performance, a maximum of 3 entities of one type is returned.)
--- 
--- If an older result within the max lifetime of the cache exists then it will
--- be returned instead of a fresh result. Beware of dead entities!
---
--- The default cache lifetime is 10 seconds.
--- 
--- @param _EntityID number ID of entity
--- @param _Area number     Size of area
--- @param _CacheAge any   (Optional) Max age of cache in seconds
--- @return table List Found enemies
--- @see AreEnemiesInArea
---
--- @author totalwarANGEL
--- @version 1.0.0
---
function GetEnemiesOfEntity(_EntityID, _Area, _CacheAge)
    return GetEntitiesOfDiplomacyStateInArea(_EntityID, _Area, Diplomacy.Hostile, _CacheAge);
end

--- Returns allies in the area.
---
--- (To improve performance, a maximum of 3 entities of one type is returned.)
--- 
--- If an older result within the max lifetime of the cache exists then it will
--- be returned instead of a fresh result. Beware of dead entities!
---
--- The default cache lifetime is 10 seconds.
--- 
--- @param _EntityID number ID of entity
--- @param _Area number     Size of area
--- @param _CacheAge number (Optional) Max age of cache in seconds
--- @return table List Found allies
--- @see AreAlliesInArea
---
--- @author totalwarANGEL
--- @version 1.0.0
---
function GetAlliesOfEntity(_EntityID, _Area, _CacheAge)
    return GetEntitiesOfDiplomacyStateInArea(_EntityID, _Area, Diplomacy.Friendly, _CacheAge);
end

function GetEntitiesOfDiplomacyStateInArea(_EntityID, _Area, _Diplomacy, _CacheAge)
    GetEnemiesOfEntity_Helper_FillRelevantTypes();
    _CacheAge = _CacheAge or 10;

    -- Invoke cache to save on processing power
    if GetEntitiesOfDiplomacyStateInArea_Cache[_Diplomacy][_EntityID] then
        if GetEntitiesOfDiplomacyStateInArea_Cache[_Diplomacy][_EntityID][1] + _CacheAge > Logic.GetTime() then
            return GetEntitiesOfDiplomacyStateInArea_Cache[_Diplomacy][_EntityID][2];
        end
    end

    -- Search enemies
    -- (max 3 of each type might be enough)
    local Enemies = {};
    local PlayerID = Logic.EntityGetPlayer(_EntityID);
    for i= 1, table.getn(Score.Player) do
        if i ~= PlayerID and Logic.GetDiplomacyState(PlayerID, i) == _Diplomacy then
            for k, v in pairs(GetEntitiesOfDiplomacyStateInArea_RelevantTypes) do
                local Findings = GetEnemiesOfEntity_Helper_GetEntitiesInArea(i, v, _EntityID, _Area, 3);
                for j= 1, table.getn(Findings) do
                    -- Add heroes if camouflage is notactive
                    if Logic.IsHero(Findings[j]) == 1 then
                        if Logic.GetCamouflageTimeLeft(Findings[j]) == 0 then
                            table.insert(Enemies, Findings[j]);
                        end
                    -- Add thieves if they are passive
                    elseif Logic.GetEntityType(Findings[j]) == Entities.PU_Thief then
                        local Task = Logic.GetCurrentTaskList(Findings[j]);
                        if (not Task or (string.find(Task,"STEAL_GOODS") or string.find(Task,"BATTLE")))
                        or Logic.CheckEntitiesDistance(_EntityID, Findings[j], 300) == 1 then
                            table.insert(Enemies, Findings[j]);
                        end
                    -- Add all other unit types
                    else
                        table.insert(Enemies, Findings[j]);
                    end
                end
            end
        end
    end

    -- Cache last result for entity
    GetEntitiesOfDiplomacyStateInArea_Cache[_Diplomacy][_EntityID] = {}
    GetEntitiesOfDiplomacyStateInArea_Cache[_Diplomacy][_EntityID][1] = Logic.GetTime();
    GetEntitiesOfDiplomacyStateInArea_Cache[_Diplomacy][_EntityID][2] = Enemies;

    return Enemies;
end

function GetEnemiesOfEntity_Helper_GetEntitiesInArea(_PlayerID, _Type, _EntityID, _Area, _Amount)
    local Results = {};
    local x,y,z = Logic.EntityGetPos(_EntityID);
    local AreaSearch = {Logic.GetPlayerEntitiesInArea(_PlayerID, _Type, x, y, _Area, _Amount or 16)};
    for i= 2, AreaSearch[1] +1 do
        table.insert(Results, AreaSearch[i]);
    end
    return Results;
end

function GetEnemiesOfEntity_Helper_FillRelevantTypes()
    if table.getn(GetEntitiesOfDiplomacyStateInArea_RelevantTypes) == 0 then
        for k, v in pairs(Entities) do
            if Logic.IsEntityTypeInCategory(v, EntityCategories.MilitaryBuilding) == 1
            or Logic.IsEntityTypeInCategory(v, EntityCategories.DefendableBuilding) == 1
            or Logic.IsEntityTypeInCategory(v, EntityCategories.Hero) == 1
            or Logic.IsEntityTypeInCategory(v, EntityCategories.Leader) == 1
            or Logic.IsEntityTypeInCategory(v, EntityCategories.Serf) == 1 then
                table.insert(GetEntitiesOfDiplomacyStateInArea_RelevantTypes, v);
            end
        end
    end
end

