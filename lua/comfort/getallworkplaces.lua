Lib.Require("comfort/GetValidEntitiesOfType");
Lib.Register("comfort/GetAllWorkplaces");

-- Version: 1.0.0
-- Author:  totalwarANGEL

--- Returns all worker of the player.
--- @param _PlayerID number ID of player
--- @return table List List of worker
function GetAllWorkplaces(_PlayerID, _EntityType)
    _EntityType = _EntityType or 0;
    local PlayerEntities = GetValidEntitiesOfType(_PlayerID, _EntityType);
    for i= table.getn(PlayerEntities), 1, -1 do
        if Logic.GetBuildingWorkPlaceLimit(PlayerEntities[i]) == 0 then
            table.remove(PlayerEntities, i);
        end
    end
    return PlayerEntities;
end

