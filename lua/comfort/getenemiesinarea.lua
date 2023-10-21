Lib.Register("comfort/GetEnemiesInArea");

-- Helper list of entities
GetEntitiesOfDiplomacyStateInArea_RelevantTypes = {};
-- If changed, AreEnemiesInArea must also be changed!
GetEntitiesOfDiplomacyStateInArea_RelevantCategories = {
    "Cannon",
    "DefendableBuilding",
    "Hero",
    "Leader",
    "MilitaryBuilding",
    "Serf",
};

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

--- Returns entities of other players with the diplomacy state.
--- @param _PlayerID integer  ID of player
--- @param _Position table    Area center
--- @param _Area integer      Size of area
--- @param _Diplomacy integer Diplomacy state
--- @param _Categories table? Relevant categories
--- @return table List Found entities
function GetEntitiesOfDiplomacyStateInArea(_PlayerID, _Position, _Area, _Diplomacy, _Categories)
    GetEnemiesInArea_Helper_FillRelevantTypes(_Categories);

    -- Create central entity
    local AreaCenterID = Logic.CreateEntity(Entities.XD_Rock1, _Position.X, _Position.Y, 0, 0);
    -- Search enemies
    local Enemies = {};
    for i= 1, table.getn(Score.Player) do
        if i ~= _PlayerID and Logic.GetDiplomacyState(_PlayerID, i) == _Diplomacy then
            for k, v in pairs(GetEntitiesOfDiplomacyStateInArea_RelevantTypes) do
                local Findings = GetEnemiesInArea_Helper_GetEntitiesInArea(i, v, _Position, _Area, 16);
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
                        or Logic.CheckEntitiesDistance(AreaCenterID, Findings[j], 300) then
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
    -- Destroy central entity
    DestroyEntity(AreaCenterID);

    return Enemies;
end

function GetEnemiesInArea_Helper_GetEntitiesInArea(_PlayerID, _Type, _Position, _Area, _Amount)
    local Results = {};
    local AreaSearch = {Logic.GetPlayerEntitiesInArea(_PlayerID, _Type, _Position.X, _Position.Y , _Area, _Amount or 16)};
    for i= 2, AreaSearch[1] +1 do
        if Logic.GetEntityHealth(AreaSearch[i]) > 0 then
            table.insert(Results, AreaSearch[i]);
        end
    end
    return Results;
end

function GetEnemiesInArea_Helper_FillRelevantTypes(_Categories)
    local Categories = GetEntitiesOfDiplomacyStateInArea_RelevantCategories;
    if _Categories then
        GetEntitiesOfDiplomacyStateInArea_RelevantTypes = {};
        Categories = _Categories;
    end
    if table.getn(GetEntitiesOfDiplomacyStateInArea_RelevantTypes) == 0 then
        for k, v in pairs(Entities) do
            local InAnyCategory = false;
            for i= 1, table.getn(Categories) do
                if Logic.IsEntityTypeInCategory(v, EntityCategories[Categories[i]]) == 1 then
                    InAnyCategory = true;
                    break;
                end
            end
            if InAnyCategory then
                table.insert(GetEntitiesOfDiplomacyStateInArea_RelevantTypes, v);
            end
        end
    end
end

