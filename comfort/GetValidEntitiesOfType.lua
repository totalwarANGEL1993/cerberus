--- Returns all valid entities of the type.
---
--- * Buildings must be fully constructed to be returned.
--- * Settlers musn't train or die to be returned.
---
--- @param _PlayerID   number ID of player
--- @param _EntityType number Entity type or 0 for all
--- @return table List List of entity IDs 
---
--- @author totalwarANGEL
--- @version 1.0.0
---
function GetValidEntitiesOfType(_PlayerID, _EntityType)
    local PlayerEntities = GetPlayerEntities(_PlayerID, _EntityType);
    for i= table.getn(PlayerEntities), 1, -1 do
        -- Remove buildings if construction is incomplete or no workers.
        if Logic.IsBuilding(PlayerEntities[i]) == 1 then
            if Logic.IsConstructionComplete(PlayerEntities[i]) == 0 then
                table.remove(PlayerEntities, i);
            end
        end
        -- Remove settlers if they are training or dying
        if Logic.IsSettler(PlayerEntities[i]) == 1 then
            local Task = Logic.GetCurrentTaskList(PlayerEntities[i]);
            if Task and (string.find(Task, "TRAIN") or string.find(Task, "DIE")) then
                table.remove(PlayerEntities, i);
            end
        end
    end
    return PlayerEntities;
end

