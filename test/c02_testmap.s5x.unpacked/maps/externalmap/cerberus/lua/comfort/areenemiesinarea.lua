Lib.Register("comfort/AreEnemiesInArea");

-- Version: 1.0.1
-- Author:  Emzet

-- If changed, GetEnemiesInArea must also be changed!
AreEntitiesOfDiplomacyStateInArea_RelevantCategories = {
    "Cannon",
    "DefendableBuilding",
    "Hero",
    "Leader",
    "MilitaryBuilding",
    "Serf",
};

--- Returns if enemies of the player are in the area.
--- @param _player number ID of player
--- @param _position any  Area center
--- @param _range number  Area size
--- @return boolean EnemiesNear Enemies are in area
---
function AreEnemiesInArea(_player, _position, _range)
    return AreEntitiesOfDiplomacyStateInArea(_player, _position, _range, Diplomacy.Hostile);
end

--- Returns if allies of the player are in the area.
--- @param _player number ID of player
--- @param _position any  Area center
--- @param _range number  Area size
--- @return boolean AlliesNear Allies are in area
---
function AreAlliesInArea(_player, _position, _range)
    return AreEntitiesOfDiplomacyStateInArea(_player, _position, _range, Diplomacy.Friendly);
end

--- Returns entities of other players with the diplomacy state.
--- @param _player integer    ID of player
--- @param _Position table    Area center
--- @param _range integer     Size of area
--- @param _state integer     Diplomacy state
--- @param _Categories table? Relevant categories
--- @return boolean Found Entities are near
---
function AreEntitiesOfDiplomacyStateInArea(_player, _Position, _range, _state, _Categories)
    local Categories = _Categories or AreEntitiesOfDiplomacyStateInArea_RelevantCategories;
    for i = 1, 8 do
        if i ~= _player and Logic.GetDiplomacyState(_player, i) == _state then
            if Logic.IsPlayerEntityOfCategoryInArea(
                i,
                _Position.X, _Position.Y,
                _range,
                unpack(Categories)
            ) == 1 then
                return true;
            end
        end
    end
    return false;
end

