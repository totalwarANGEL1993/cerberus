Lib.Register("comfort/GetConeEnd");

-- Version: 1.0.0
-- Author:  totalwarANGEL

--- Calculates the end position of the cone.
--- @param _Center table     Position of center
--- @param _Length integer   Length of the cone
--- @param _Rotation integer Rotation of the cone
--- @return table End End position of cone
function GetConeEnd(_Center, _Length, _Rotation)
    local centerX = _Center.X + _Length * math.cos(math.rad(_Rotation));
    local centerY = _Center.Y + _Length * math.sin(math.rad(_Rotation));
    return {X = centerX, Y = centerY};
end

