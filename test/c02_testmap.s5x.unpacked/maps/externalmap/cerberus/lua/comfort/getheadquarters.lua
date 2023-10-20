Lib.Register("comfort/GetHeadquarters");

--- Returns the first Headquarters found for the player.
--- @param _PlayerID number ID of player
--- @return number ID Entity 
---
--- @author totalwarANGEL
--- @version 1.0.0
---
function GetHeadquarters(_PlayerID)
    local ID = 0;
    local Headquarters1 = {Logic.GetPlayerEntities(_PlayerID, Entities.PB_Headquarters1, 1)};
    if Headquarters1[1] > 0 then
        ID = Headquarters1[2];
    end
    local Headquarters2 = {Logic.GetPlayerEntities(_PlayerID, Entities.PB_Headquarters2, 1)};
    if Headquarters2[1] > 0 then
        ID = Headquarters2[2];
    end
    local Headquarters3 = {Logic.GetPlayerEntities(_PlayerID, Entities.PB_Headquarters3, 1)};
    if Headquarters3[1] > 0 then
        ID = Headquarters3[2];
    end
    return ID;
end

