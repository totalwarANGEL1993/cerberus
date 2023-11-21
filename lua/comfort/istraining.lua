Lib.Register("comfort/IsTraining");

-- Version: 1.0.0
-- Author:  totalwarANGEL

--- Returns if the entity is training.
--- @param _Entity any Entity to check
--- @return boolean Fighting Entity is training
function IsTraining(_Entity)
    local ID = GetID(_Entity);
    if ID ~= 0 then
        return Logic.LeaderGetBarrack(ID) ~= 0;
    end
    return false;
end

