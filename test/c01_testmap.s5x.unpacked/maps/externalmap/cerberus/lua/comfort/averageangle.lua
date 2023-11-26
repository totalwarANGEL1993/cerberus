Lib.Require("comfort/Arctangent2");
Lib.Register("comfort/AverageAngle");

--- Calculates the average angle using cartesian coordinates and returns it.
--- @param ... number List of angles
--- @return number Angle Average angle
function AverageAngle(...)
    local sumX, sumY = 0, 0;
    for _, angle in ipairs(arg) do
        local x = math.cos(math.rad(angle));
        local y = math.sin(math.rad(angle));
        sumX = sumX + x;
        sumY = sumY + y;
    end
    local averageX = sumX / table.getn(arg);
    local averageY = sumY / table.getn(arg);
    local averageAngle = math.deg(Arctangent2(averageY, averageX));
    if averageAngle < 0 then
        averageAngle = averageAngle + 360;
    end
    return averageAngle;
end

