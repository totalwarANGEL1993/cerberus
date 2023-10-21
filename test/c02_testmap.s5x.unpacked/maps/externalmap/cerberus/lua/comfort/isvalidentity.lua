Lib.Register("comfort/IsValidEntity");

--- Checks if the entity is valid. An entity is valid if it
--- exists, has HP and is not busy with dying.
--- @param _Entity any Entity to check
--- @return boolean Valid Entity is alive and well
---
--- @author totalwarANGEL
--- @version 1.0.0
---
function IsValidEntity(_Entity)
    local ID = GetID(_Entity);
    if  Logic.IsSettler(ID) == 1
    and not Logic.IsEntityDestroyed(ID)
    and Logic.GetEntityHealth(ID) > 0 then
        local Task = Logic.GetCurrentTaskList(ID);
        if Task and string.find(Task, "DIE") then
            return false;
        end
        return true;
    end
    return false;
end
IsEntityValid = IsValidEntity;

