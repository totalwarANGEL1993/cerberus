Lib.Register("comfort/IsFighting");

-- Version: 1.0.0
-- Author:  totalwarANGEL

--- Returns if the entity is fighting.
--- @param _Entity any Entity to check
--- @return boolean Fighting Entity is fighting
function IsFighting(_Entity)
    local ID = GetID(_Entity);
    if ID ~= 0 then
        local Task = Logic.GetCurrentTaskList(ID);
        return Task and string.find(Task, "BATTLE") ~= nil;
    end
    return false;
end

