Lib.Require("comfort/GetValidEntitiesOfType");
Lib.Register("comfort/GetAllCannons");

-- Version: 1.0.0
-- Author:  unknown

--- Returns all cannons of the player.
--- @param _PlayerID number ID of player
--- @return table List List of cannons
function GetAllCannons(_PlayerID)
    local PlayerEntities = GetValidEntitiesOfType(_PlayerID, 0);
    for i= table.getn(PlayerEntities), 1, -1 do
        if Logic.IsEntityInCategory(PlayerEntities[i], EntityCategories.Cannon) == 0 then
            table.remove(PlayerEntities, i);
        end
    end
    return PlayerEntities;
end

