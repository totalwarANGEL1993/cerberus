Lib.Require("comfort/IsValidPosition");
Lib.Register("comfort/GetCirclePosition");

-- Version: 1.0.0
-- Author:  totalwarANGEL

--- Returns a position around a central position.
--- @param _Target any      Center position
--- @param _Distance number Radius from center
--- @param _Angle number    Angle of circle
--- @return table Position
function GetCirclePosition(_Target, _Distance, _Angle)
    if not IsValidPosition(_Target) and not IsExisting(_Target) then
        return {X= 1, Y= 1, Z = 2000};
    end

    local Position = _Target;
    local Orientation = 0+ (_Angle or 0);
    if type(_Target) ~= "table" then
        local EntityID = GetID(_Target);
        Orientation = Logic.GetEntityOrientation(EntityID)+(_Angle or 0);
        Position = GetPosition(EntityID);
    end

    local Result = {
        X= Position.X+_Distance * math.cos(math.rad(Orientation)),
        Y= Position.Y+_Distance * math.sin(math.rad(Orientation)),
        Z= Position.Z
    };
    return Result;
end

