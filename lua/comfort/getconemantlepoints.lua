Lib.Register("comfort/GetConeMantlePoints");

-- Version: 1.0.0
-- Author:  totalwarANGEL

--- Calculates positions on the mantle lines of the cone
--- @param _Center table Position of center
--- @param _Length integer Length of the cone
--- @param _Rotation integer Rotation of the cone
--- @param _Angle number Angle of cone
--- @param _PointCount? integer Amount of points
--- @return table LeftPoints List of left points
--- @return table RightPoints List of right points
function GetConeMantlePoints(_Center, _Length, _Rotation, _Angle, _PointCount)
    _PointCount = _PointCount or 10;
    local LeftPoints = {};
    local RightPoints = {};
    local halfAngle = _Angle / 2;
    for i = 0, _PointCount - 1 do
        local t = i / (_PointCount - 1);
        local LeftAngle = _Rotation - halfAngle;
        local LeftX = _Center.X + t * _Length * math.cos(math.rad(LeftAngle));
        local LeftY = _Center.Y + t * _Length * math.sin(math.rad(LeftAngle));
        table.insert(LeftPoints, {X = LeftX, Y = LeftY});
        local RightAngle = _Rotation + halfAngle;
        local RightX = _Center.X + t * _Length * math.cos(math.rad(RightAngle));
        local RightY = _Center.Y + t * _Length * math.sin(math.rad(RightAngle));
        table.insert(RightPoints, {X = RightX, Y = RightY});
    end
    return LeftPoints, RightPoints;
end