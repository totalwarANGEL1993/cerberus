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
        if Logic.IsBuilding(ID) == 1 or Logic.IsSettler(ID) == 1 then
            if Logic.GetEntityHealth(ID) > 0 then
                if Logic.IsSettler(ID) == 1 then
                    local Task = Logic.GetCurrentTaskList(ID);
                    if Task and not string.find(Task, "DIE") then
                        return true;
                    end
                end
                return true;
            end
        else
            return true;
        end
    end
    return false;
end
IsEntityValid = IsValidEntity;

