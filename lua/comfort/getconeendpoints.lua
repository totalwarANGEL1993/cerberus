Lib.Register("comfort/GetConeEndPoints");

-- Version: 1.0.0
-- Author:  totalwarANGEL

--- Calculates positions on the baseline of the cone.
--- @param _Center table Position of center
--- @param _Length integer Length of the cone
--- @param _Rotation integer Rotation of the cone
--- @param _Angle number Angle of cone
--- @param _PointCount? integer Amount of points
--- @return table Points List of points
function GetConeEndPoints(_Center, _Length, _Rotation, _Angle, _PointCount)
    _PointCount = _PointCount or 10;
    local Points = {};
    local HalfAngle = _Angle / 2;
    local Step = _Angle / (_PointCount - 1);
    for i = 0, _PointCount - 1 do
        local angle = _Rotation - HalfAngle + i * Step;
        local pointX = _Center.X + _Length * math.cos(math.rad(angle));
        local pointY = _Center.Y + _Length * math.sin(math.rad(angle));
        table.insert(Points, {X = pointX, Y = pointY});
    end
    return Points;
end

