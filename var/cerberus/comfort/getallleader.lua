Lib.Register("comfort/GetAllLeader");

--- Returns all leader of the player.
--- @param _PlayerID number ID of player
--- @return table List List of leaders
---
--- @author totalwarANGEL
--- @version 1.0.0
---
function GetAllLeader(_PlayerID)
    local LeaderList = {};
    local FirstID = Logic.GetNextLeader(_PlayerID, 0);
    if FirstID ~= 0 then
        local PrevID = FirstID;
        table.insert(LeaderList, FirstID);
        while true do
            local NextID = Logic.GetNextLeader(_PlayerID, PrevID);
            if NextID == FirstID then
                break;
            end
            table.insert(LeaderList, NextID);
            PrevID = NextID;
        end
    end
    return LeaderList;
end

