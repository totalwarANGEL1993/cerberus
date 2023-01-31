Lib.Register("comfort/GetHealth");

--- Returns the relative health of the entity.
--- @param _Entity any Entity to check
--- @return number Health Relative health
---
--- @author Unknown
--- @version 1.0.0
---
function GetHealth(_Entity)
    local EntityID = GetID(_Entity);
    if not Tools.IsEntityAlive(EntityID) then
        return 0;
    end
    local MaxHealth = Logic.GetEntityMaxHealth(EntityID);
    local Health = Logic.GetEntityHealth(EntityID);
    return (Health / MaxHealth) * 100;
end

