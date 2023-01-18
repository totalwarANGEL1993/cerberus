--- Returns all leader of the player.
--- @param _PlayerID number ID of player
--- @return table List List of leaders
---
--- @author totalwarANGEL
--- @version 1.0.0
---
function GetAllLeader(_PlayerID)
    local Leader = {};
    local NumberOfLeaders = Logic.GetNumberOfLeader(_PlayerID);
    local ID = 0;
    for i=1, NumberOfLeaders do
        ID = Logic.GetNextLeader(_PlayerID, ID);
        table.insert(Leader, ID);
    end
    return Leader;
end

