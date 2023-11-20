Lib.Require("comfort/GetAngleBetween");
Lib.Require("comfort/GetDistance");
Lib.Register("comfort/IsInCone");

function IsInCone(_Target, _Center, _Length, _MiddleAlpha, _BetaAvailable)
    local Distance = GetDistance(_Center, _Target)
    if Distance > _Length then
        return false;
    end
    local a = GetAngleBetween(_Center, _Target);
    local lb = _MiddleAlpha - _BetaAvailable;
    local hb = _MiddleAlpha + _BetaAvailable;
    return a >= lb and a <= hb;
end

