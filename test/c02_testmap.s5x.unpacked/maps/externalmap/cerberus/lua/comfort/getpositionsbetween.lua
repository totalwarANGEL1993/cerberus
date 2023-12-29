Lib.Register("comfort/GetPositionsBetween");

--- Returns positions on a line between start and end.
--- @param _StartPoint table Start position
--- @param _EndPoint table End position
--- @param _NumPoints integer Amount of points inbetween
--- @return table
function GetPositionsBetween(_StartPoint, _EndPoint, _NumPoints)
    assert(type(_StartPoint) == "table" and type(_EndPoint) == "table");
    assert(type(_NumPoints) == "number" and _NumPoints > 1);

    local Points = {};
    for i = 1, _NumPoints do
        assert(_NumPoints - 1 > 0);
        local t = (i - 1) / (_NumPoints - 1);
        local x = _StartPoint.X + (_EndPoint.X - _StartPoint.X) * t;
        local y = _StartPoint.Y + (_EndPoint.Y - _StartPoint.Y) * t;
        local Point = {X = x, Y = y};
        table.insert(Points, Point);
    end
    return Points;
end

--- Calculates the amount of positions between start and end.
--- @param _StartPoint table Start position
--- @param _EndPoint table End position
--- @param _MaxDistance number Distance between positions
--- @return integer Amount Amount of positions
function CalculateOptimalNumPoints(_StartPoint, _EndPoint, _MaxDistance)
    assert(type(_StartPoint) == "table" and type(_EndPoint) == "table");
    assert(type(_MaxDistance) == "number" and _MaxDistance > 0);

    local Distance = math.sqrt((_EndPoint.X - _StartPoint.X)^2 + (_EndPoint.Y - _StartPoint.Y)^2);
    local NumPoints = math.max(2, math.ceil(Distance / _MaxDistance));
    return NumPoints;
end

