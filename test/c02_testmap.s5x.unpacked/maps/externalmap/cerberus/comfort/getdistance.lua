Lib.Require("comfort/GetDistanceSquare");
Lib.Register("comfort/GetDistance");

--- Returns the distance between two positions.
--- @param _pos1 any First position
--- @param _pos2 any Second position
--- @return number Distance Distance between positions
---
--- @author Unknown
--- @version 1.0.0
---
function GetDistance(_pos1, _pos2)
    return math.sqrt(GetDistanceSquare(_pos1, _pos2));
end

