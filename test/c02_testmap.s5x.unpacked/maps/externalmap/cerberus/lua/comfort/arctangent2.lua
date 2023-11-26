Lib.Register("comfort/Arctangent2");

-- Version: 1.0.0
-- Author:  totalwarANGEL

--- Implementation for arctan2 from newer Lua versions.
--- @param y number Length of vertical line from (0;0) to point
--- @param x number Length of horizontal line from (0;0) to point
--- @return number Arctangent Arctangent of y/x
function Arctangent2(y, x)
    return math.atan(y / x) + (x < 0 and math.pi or 0)
end

