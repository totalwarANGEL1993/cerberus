Lib.Register("comfort/IsValidPosition");

-- Version: 1.0.0
-- Author:  unknown

--- Checks if the position is valid.
--- @param _pos table Position to check
--- @return boolean Valid Position is valid
function IsValidPosition(_pos)
    if type(_pos) == "table" then
        if (_pos.X ~= nil and type(_pos.X) == "number") and (_pos.Y ~= nil and type(_pos.Y) == "number") then
            local world = {Logic.WorldGetSize()};
            if _pos.Z and _pos.Z < 0 then
                return false;
            end
            if _pos.X < world[1] and _pos.X > 0 and _pos.Y < world[2] and _pos.Y > 0 then
                return true;
            end
        end
    end
    return false;
end

