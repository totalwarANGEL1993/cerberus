Lib.Require("comfort/GetDistance");
Lib.Register("comfort/GetEnemiesInArea");

GetEntitiesOfDiplomacyStateInArea_RelevantTypes = {};

--- Returns enemies in the area.
---
--- (To improve performance, a maximum of 3 entities of one type is returned.)
--- 
--- @param _PlayerID number ID of player
--- @param _Position table  Area center
--- @param _Area number     Size of area
--- @return table List Found enemies
--- @see AreEnemiesInArea
---
--- @author totalwarANGEL
--- @version 1.0.0
---
function GetEnemiesInArea(_PlayerID, _Position, _Area)
    return GetEntitiesOfDiplomacyStateInArea(_PlayerID, _Position, _Area, Diplomacy.Hostile);
end

--- Returns allies in the area.
---
--- (To improve performance, a maximum of 3 entities of one type is returned.)
--- 
--- @param _PlayerID number ID of player
--- @param _Position table  Area center
--- @param _Area number     Size of area
--- @return table List Found allies
--- @see AreAlliesInArea
---
--- @author totalwarANGEL
--- @version 1.0.0
---
function GetAlliesInArea(_PlayerID, _Position, _Area)
    return GetEntitiesOfDiplomacyStateInArea(_PlayerID, _Position, _Area, Diplomacy.Friendly);
end

function GetEntitiesOfDiplomacyStateInArea(_PlayerID, _Position, _Area, _Diplomacy)
    GetEnemiesInArea_Helper_FillRelevantTypes();
    -- Search enemies
    -- (max 3 of each type might be enough)
    local Enemies = {};
    for i= 1, table.getn(Score.Player) do
        if i ~= _PlayerID and Logic.GetDiplomacyState(_PlayerID, i) == _Diplomacy then
            for k, v in pairs(GetEntitiesOfDiplomacyStateInArea_RelevantTypes) do
                local Findings = GetEnemiesInArea_Helper_GetEntitiesInArea(i, v, _Position, _Area, 3);
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
                        or GetDistance(_Position, Findings[j]) <= 300 then
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
    return Enemies;
end

function GetEnemiesInArea_Helper_GetEntitiesInArea(_PlayerID, _Type, _Position, _Area, _Amount)
    local Results = {};
    local AreaSearch = {Logic.GetPlayerEntitiesInArea(_PlayerID, _Type, _Position.X, _Position.Y , _Area, _Amount or 16)};
    for i= 2, AreaSearch[1] +1 do
        table.insert(Results, AreaSearch[i]);
    end
    return Results;
end

function GetEnemiesInArea_Helper_FillRelevantTypes()
    if table.getn(GetEntitiesOfDiplomacyStateInArea_RelevantTypes) == 0 then
        for k, v in pairs(Entities) do
            -- If changed, AreEnemiesInArea must also be changed!
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

