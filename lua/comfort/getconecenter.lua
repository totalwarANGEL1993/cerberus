Lib.Register("comfort/GetConeCenter");

-- Version: 1.0.0
-- Author:  totalwarANGEL

--- Calculates the middlepoint of the cone.
--- @param _Center table     Position of center
--- @param _Length integer   Length of the cone
--- @param _Rotation integer Rotation of the cone
--- @return table Middlepoint Position of middlepoint
function GetConeCenter(_Center, _Length, _Rotation)
    local centerX = _Center.X + _Length / 2 * math.cos(math.rad(_Rotation));
    local centerY = _Center.Y + _Length / 2 * math.sin(math.rad(_Rotation));
    return {X = centerX, Y = centerY};
end

