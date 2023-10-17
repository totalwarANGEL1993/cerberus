Lib.Require("module/trigger/Job");
Lib.Register("module/entity/EntityTracker");

---
--- Entity Movement
--- 
--- A little module with functions to move an entity.
--- 
--- Version 1.0.0
---

EntityMover = EntityMover or {};

-- -------------------------------------------------------------------------- --
-- API

--- Moves an entity to a destination and replaces it with a script entity.
--- @param _Entity string|integer Entity to move
--- @param _Target string|integer Target entity
function MoveAndVanish(_Entity, _Target)
    EntityMover.Internal:MoveAndVanish(_Entity, _Target);
end

--- Moves an entity on a path of waypoints.
--- @param _Entity string|integer Entity to move
--- @param _Vanish boolean Replace with script entity on arrival
--- @param ... string|integer List of waypoints
function MoveOnWaypoints(_Entity, _Vanish, ...)
    EntityMover.Internal:MoveOnWaypoints(_Entity, _Vanish, unpack(arg));
end

-- -------------------------------------------------------------------------- --
-- Internal

EntityMover.Internal = EntityMover.Internal or {
    Data = {},
    Config = {},
};

function EntityMover.Internal:Install()
    if not self.IsInstalled then
        EntityMover.Internal.Data.MoveAndVanish = {};
        EntityMover.Internal.Data.MovingOnWaypoints = {};

        Job.Turn(function()
            EntityMover.Internal:MoveAndVanishController();
            EntityMover.Internal:MoveOnWaypointsController();
        end);

        self.IsInstalled = true;
    end
end

function EntityMover.Internal:MoveAndVanish(_Entity, _Target)
    self:Install();
    Move(_Entity, _Target);
    self.Data.MoveAndVanish[_Entity] = _Target;
end

function EntityMover.Internal:MoveAndVanishController()
    for Entity, Target in pairs(self.Data.MovingOnWaypoints) do
        if not IsExisting(Entity) then
            self.Data.MovingOnWaypoints[Entity] = nil;
            return;
        end
        if not Logic.IsEntityMoving(GetID(Entity)) then
            Move(Entity, Target);
        end
        if IsNear(Entity, Target, 150) then
            local EntityID = GetID(Entity);
            local PlayerID = Logic.EntityGetPlayer(EntityID);
            local Orientation = Logic.GetEntityOrientation(EntityID);
            local ScriptName = Logic.GetEntityName(EntityID);
            local x, y, z = Logic.EntityGetPos(EntityID);
            DestroyEntity(EntityID);
            EntityID = Logic.CreateEntity(Entities.XD_ScriptEntity, x, y, Orientation, PlayerID);
            Logic.SetEntityName(EntityID, ScriptName);
            self.Data.MovingOnWaypoints[Entity] = nil;
        end
    end
end

function EntityMover.Internal:MoveOnWaypoints(_Entity, _Vanish, ...)
    self:Install();

    if not IsExisting(_Entity) then
        return;
    end

    local ID = GetID(_Entity);
    self.Data.MovingOnWaypoints[ID] = {
        Vanish = _Vanish == true,
        Current = 1,
    };
    for i= 1, table.getn(arg), 1 do
        table.insert(
            self.Data.MovingOnWaypoints[ID],
            {arg[i].Target,
             arg[i].Distance or 50,
             arg[i].IgnoreBlocking == true,
             (arg[i].Waittime or 0) * 10,
             arg[i].Callback}
        );
    end
end

function EntityMover.Internal:MoveOnWaypointsController()
    for ID, Data in pairs(self.Data.MovingOnWaypoints) do
        if not IsExisting(ID) or not self.Data.MovingOnWaypoints[ID] then
            self.Data.MovingOnWaypoints[ID] = nil;
            return;
        end

        local Index = Data.Current;
        local Waypoint = Data[Index];
        local Task = Logic.GetCurrentTaskList(ID);
        if not string.find(Task or "", "WALK") then
            local x, y, z = Logic.EntityGetPos(GetID(Waypoint[1]));
            if Waypoint[3] then
                Logic.SetTaskList(ID, TaskLists.TL_NPC_WALK);
                Logic.MoveEntity(ID, x, y);
            else
                Logic.MoveSettler(ID, x, y);
            end
        end

        if IsNear(ID, Waypoint[1], Waypoint[2]) then
            if Data[Index][4] > 0 then
                self.Data.MovingOnWaypoints[ID][Index][4] = Waypoint[4] -1;
                if string.find(Task or "", "WALK") then
                    Logic.SetTaskList(ID, TaskLists.TL_NPC_IDLE);
                end
            else
                Data.Current = Index +1;
                if Waypoint[5] then
                    Waypoint[5](Waypoint);
                end
            end
            if Index == table.getn(Data) then
                if Data.Vanish then
                    local PlayerID = Logic.EntityGetPlayer(ID);
                    local Orientation = Logic.GetEntityOrientation(ID);
                    local ScriptName = Logic.GetEntityName(ID);
                    local x, y, z = Logic.EntityGetPos(ID);
                    DestroyEntity(ID);
                    local NewID = Logic.CreateEntity(Entities.XD_ScriptEntity, x, y, Orientation, PlayerID);
                    Logic.SetEntityName(NewID, ScriptName);
                end
                self.Data.MovingOnWaypoints[ID] = nil;
            end
        end
    end
end

