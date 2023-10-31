Lib.Register("comfort/GetReachablePosition");

-- Version: 1.0.0
-- Author:  totalwarANGEL

--- Returns a position that can be reached by the entity
--- @param _Entity any   Reference entity
--- @param _Target any   Target position
--- @param _Fallback any Position in case of error
--- @return table Position Reachable position
function GetReachablePosition(_Entity, _Target, _Fallback)
    local Result;
    if CUtil then
        Result = GetReachablePosition_Helper_CUtil(_Entity, _Target);
    else
        local PlayerID = Logic.EntityGetPlayer(GetID(_Entity));
        local Position1 = GetPosition(_Entity);
        local Position2 =_Target;
        if (type(Position2) == "string") or (type(Position2) == "number") then
            Position2 = GetPosition(_Target);
        end
        assert(type(Position1) == "table");
        assert(type(Position2) == "table");
        local ID = AI.Entity_CreateFormation(PlayerID, Entities.PU_Serf, 0, 0, Position2.X, Position2.Y, 0, 0, 0, 0);
        local NewPosition = GetPosition(ID);
        DestroyEntity(ID);
        Result = NewPosition;
    end

    if Result == nil then
        Result = _Fallback or _Entity;
        if type(Result) ~= "table" then
            Result = GetPosition(_Fallback);
        end
    end
    return Result;
end

function GetReachablePosition_Helper_CUtil(_Entity, _Target)
    local WorldX, WorldY = Logic.WorldGetSize();

    -- Get target position
    local TargetX, TargetY, TargetZ;
    if type(_Target) == "table" then
        TargetX, TargetY, TargetZ = _Target.X, _Target.Y, _Target.Z or 0;
    else
        TargetX, TargetY, TargetZ = Logic.EntityGetPos(GetID(_Target));
    end
    -- Evaluate reachable position
    local PrevDistance = WorldX ^ 2;
    local ReachableX, ReachableY = 0, 0;
    for x = TargetX - 2000, TargetX + 2000, 50 do
        for y = TargetY - 2000, TargetY + 2000, 50 do
            if y > 0 and x > 0 and x < WorldX and y < WorldY then
                local Distance = (x - TargetX)^2 + (y - TargetY)^2
                local height, blockingtype, sector, terrainType = CUtil.GetTerrainInfo(x, y);
                if sector > 0 and (height > CUtil.GetWaterHeight(x/100, y/100)) then
                    if PrevDistance > Distance then
                        ReachableX, ReachableY = x, y;
                        PrevDistance = Distance;
                    end
                end
            end
        end
    end
    if ReachableX ~= 0 and ReachableY ~= 0 then
        local NewPosition = {X= ReachableX, Y= ReachableY, Z= 0};
        return NewPosition;
    end
end

