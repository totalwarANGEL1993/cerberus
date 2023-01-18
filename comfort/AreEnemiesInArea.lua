--- Returns if enemies of the player are in the area.
--- @param _player number ID of player
--- @param _position any  Area center
--- @param _range number  Area size
--- @return boolean EnemiesNear Enemies are in area
---
--- @author Emzet
--- @version 1.0.0
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
--- @author Emzet
--- @version 1.0.0
---
function AreAlliesInArea(_player, _position, _range)
    return AreEntitiesOfDiplomacyStateInArea(_player, _position, _range, Diplomacy.Friendly);
end

-- Improved version by totalwarANGEL
function AreEntitiesOfDiplomacyStateInArea(_player, _Position, _range, _state)
    local Position = _Position;
    if type(Position) ~= "table" then
        Position = GetPosition(Position);
    end
    for i = 1, 8 do
        if i ~= _player and Logic.GetDiplomacyState(_player, i) == _state then
            if Logic.IsPlayerEntityOfCategoryInArea(i, Position.X, Position.Y, _range, "DefendableBuilding", "Military", "MilitaryBuilding") == 1 then
                return true;
            end
        end
    end
    return false;
end

