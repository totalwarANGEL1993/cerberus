Lib.Require("comfort/GetAngleBetween");
Lib.Require("comfort/GetDistance");
Lib.Register("comfort/IsInCone");

--- Returns if a position is inside a cone.
--- @param _Target any      Position or entity to check
--- @param _Center any      Position or entity at center
--- @param _Length integer  Lenght of the cone
--- @param _Rotation number Rotation angle of the cone
--- @param _Width number    Clamping angle (both sides)
--- @return boolean InCone Targt is in cone
function IsInCone(_Target, _Center, _Length, _Rotation, _Width)
    local Distance = GetDistance(_Center, _Target)
    if Distance > _Length then
        return false;
    end
    local a = GetAngleBetween(_Center, _Target);
    local lb = _Rotation - _Width;
    local hb = _Rotation + _Width;
    return a >= lb and a <= hb;
end

