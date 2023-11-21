Lib.Require("comfort/GetAngleBetween");
Lib.Register("comfort/IsInSight");

--- Returns if an entity is in sight of another
--- @param _Target any      Scriptname or entity ID of target
--- @param _Viewer any      Scriptname or entity ID of viewer
--- @param _Length integer  Lenght of the cone
--- @param _Width number?   Clamping angle (both sides)
--- @return boolean InCone Targt is in view
function IsInSight(_Target, _Viewer, _Length, _Width)
    _Width = _Width or 60;
    local TargetID = GetID(_Target);
    local ViewerID = GetID(_Viewer);
    local Rotation = Logic.GetEntityOrientation(ViewerID) - 90;
    if Logic.CheckEntitiesDistance(TargetID, ViewerID, _Length) == 0 then
        return false;
    end
    local a = GetAngleBetween(ViewerID, TargetID);
    local lb = Rotation - _Width;
    local hb = Rotation + _Width;
    return a >= lb and a <= hb;
end

