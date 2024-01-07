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
    -- Get target position
    local TargetX, TargetY, TargetZ;
    if type(_Target) == "table" then
        TargetX, TargetY, TargetZ = _Target.X, _Target.Y, _Target.Z or 0;
    else
        TargetX, TargetY, TargetZ = Logic.EntityGetPos(GetID(_Target));
    end
    TargetX = math.floor(TargetX + 0.5);
    TargetY = math.floor(TargetY + 0.5);
    -- Evaluate reachable position
    local MaxOffset = 2000;
    local CurrentOffset = 0;
    local OffsetStep = 100;
    while CurrentOffset <= MaxOffset do
        if CurrentOffset == 0 then
            local WaterHeight = CUtil.GetWaterHeight(TargetX/100, TargetY/100);
            local Height, Blocking, Sector, Terrain = CUtil.GetTerrainInfo(TargetX, TargetY);
            if Height > WaterHeight and (Sector ~= 0 and (Blocking == 0 or Blocking == 4)) then
                local ReachablePosition = {X= TargetX, Y= TargetY, Z= TargetZ};
                if IsValidPosition(ReachablePosition) then
                    return ReachablePosition;
                end
            end
        else
            for x = TargetX - CurrentOffset, TargetX + CurrentOffset, OffsetStep do
                for y = TargetY - CurrentOffset, TargetY + CurrentOffset, OffsetStep do
                    local WaterHeight = CUtil.GetWaterHeight(x/100, y/100);
                    local Height, Blocking, Sector, Terrain = CUtil.GetTerrainInfo(x, y);
                    if Height > WaterHeight and (Sector ~= 0 and (Blocking == 0 or Blocking == 4)) then
                        local ReachablePosition = {X= x, Y= y, Z= Height};
                        if IsValidPosition(ReachablePosition) then
                            return ReachablePosition;
                        end
                    end
                end
            end
        end
        CurrentOffset = CurrentOffset + OffsetStep;
    end
end

