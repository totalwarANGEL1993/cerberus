Lib.Register("comfort/GetAllCannons");

--- Returns all cannons of the player.
--- @param _PlayerID number ID of player
--- @return table List List of cannons
---
--- @author totalwarANGEL
--- @version 1.0.0
---
function GetAllCannons(_PlayerID)
    local Cannons = {};
    for i=1, 4 do
        local n, EntityID = Logic.GetPlayerEntities(_PlayerID, Entities["PV_Cannon" ..i], 1);
        local FirstEntity = EntityID;
        repeat
            table.insert(Cannons, EntityID)
            EntityID = Logic.GetNextEntityOfPlayerOfType(EntityID);
        until (FirstEntity == EntityID);
    end
    return Cannons;
end

