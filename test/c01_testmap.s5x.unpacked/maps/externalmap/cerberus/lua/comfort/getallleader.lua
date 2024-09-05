Lib.Require("comfort/GetValidEntitiesOfType");
Lib.Register("comfort/GetAllLeader");

-- Version: 1.0.0
-- Author:  unknown

--- Returns all leader of the player.
--- @param _PlayerID number ID of player
--- @return table List List of leaders
function GetAllLeader(_PlayerID)
    local PlayerEntities = GetValidEntitiesOfType(_PlayerID, 0);
    for i= table.getn(PlayerEntities), 1, -1 do
        if Logic.IsLeader(PlayerEntities[i]) == 0 then
            table.remove(PlayerEntities, i);
        end
    end
    return PlayerEntities;
end

