Lib.Register("comfort/IsDeadWrapper");

--- Returns if the entity or army is dead.
--- @param _input any Entity or BB army
--- @return boolean Dead Subject is dead
---
--- @author Unknown
--- @version 1.0.0
---
function IsDeadWrapper(_input)
    if type(_input) == "table" and not _input.created then
        _input.created = not IsDeadOrig(_input);
        return false;
    end
    return IsDeadOrig(_input);
end
IsDeadOrig = IsDead;
IsDead = IsDeadWrapper;

