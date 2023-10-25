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
    if IsExisting(ID) then
        if  (Logic.IsBuilding(ID) == 1 or Logic.IsSettler(ID) == 1)
        and Logic.GetEntityHealth(ID) > 0 then
            local Task = Logic.GetCurrentTaskList(ID);
            if Task and string.find(Task, "DIE") then
                return false;
            end
            return true;
        end
        return true;
    end
    return false;
end
IsEntityValid = IsValidEntity;

