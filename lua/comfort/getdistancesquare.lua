Lib.Register("comfort/GetDistanceSquare");

--- Returns the power of 2 of the distance between two positions.
--- @param _pos1 any First position
--- @param _pos2 any Second position
--- @return number Distance Distance between positions
---
--- @author Unknown
--- @version 1.0.0
---
function GetDistanceSquare(_pos1, _pos2)
    if (type(_pos1) == "string") or (type(_pos1) == "number") then
        _pos1 = GetPosition(_pos1);
    end
    if (type(_pos2) == "string") or (type(_pos2) == "number") then
        _pos2 = GetPosition(_pos2);
    end
	assert(type(_pos1) == "table");
	assert(type(_pos2) == "table");
    local xDistance = (_pos1.X - _pos2.X);
    local yDistance = (_pos1.Y - _pos2.Y);
    return (xDistance^2) + (yDistance^2);
end

