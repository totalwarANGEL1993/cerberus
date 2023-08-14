Lib.Require("comfort/AreEnemiesInArea");
Lib.Require("comfort/ArePositionsConnected");
Lib.Require("comfort/CopyTable");
Lib.Require("comfort/GetDistance");
Lib.Require("comfort/GetEnemiesInArea");
Lib.Require("comfort/GetEntityCategoriesAsString");
Lib.Require("comfort/GetGeometricCenter");
Lib.Require("comfort/IsFighting");
Lib.Require("module/trigger/Job");
Lib.Register("module/ai/AiArmy");

---
--- AI army script
---
--- Creates an army that automatically attacks enemies in reach. It also tries
--- to not focus on a single target and makes use of max range attacks.
---
--- @author totalwarANGEL
--- @version 0.0.1 BETA
---

AiArmy = AiArmy or {
    Behavior = {
        -- Army is waiting for a command
        WAITING = 1,
        -- Army is walking to the target position
        ADVANCE = 2,
        -- Army is gathering at the currend position
        REGROUP = 3,
        -- Army is batteling enemies around the anchor
        BATTLE = 4,
        -- Army is waiting for full strength
        REFILL = 5,
    },
};

-- -------------------------------------------------------------------------- --
-- API

--- Creates an new army.
--- @param _PlayerID number   Owner of army
--- @param _Strength number   Max amount of leaders
--- @param _Position table    Position of army
--- @param _RodeLength number Radius of action
--- @return number ID ID of army
function AiArmy.New(_PlayerID, _Strength, _Position, _RodeLength)
    local Army = AiArmy.Internal.Army:New(_PlayerID, _Strength, _Position, _RodeLength);
    AiArmyData_ArmyIdToArmyInstance[Army.ID] = Army;
    return Army.ID;
end

--- Deletes an army.
---
--- Remaining members are not deleted. Their leader ai is reactivated.
---
--- @param _ID number ID of army
function AiArmy.Delete(_ID)
    if AiArmyData_ArmyIdToArmyInstance[_ID] then
        AiArmyData_ArmyIdToArmyInstance[_ID]:Dispose();
    end
end

--- Returns the army with the ID if any.
--- @param _ID number ID of army
--- @return table? Army Instance of army
function AiArmy.Get(_ID)
    if AiArmyData_ArmyIdToArmyInstance[_ID] then
        return AiArmyData_ArmyIdToArmyInstance[_ID];
    end
end

--- Adds a new troop to the army.
---
--- A troop can be added as reinforcement. In that case the army will not
--- search enemies near to this troop. The troop will walk to the current
--- position of the army using attack walk.
---
--- @param _ID number         ID of army
--- @param _TroopID number    ID of troop
--- @param _Reinforce boolean Add as reinforcement
--- @return boolean Added Was successfully added
function AiArmy.AddTroop(_ID, _TroopID, _Reinforce)
    local Army = AiArmy.Get(_ID);
    if Army then
        return Army:AddTroop(_TroopID, _Reinforce);
    end
    return false;
end

--- Spawns a troop soldiers at the location.
---
--- A troop is always added as reinforcement.
---
--- @param _ID number    ID of army
--- @param _Type number  Unit type to spawn
--- @param _Position any Where to spawn
--- @param _Exp? number  Experience of troop
--- @return boolean Added Was successfully added
function AiArmy.SpawnTroop(_ID, _Type, _Position, _Exp)
    local Army = AiArmy.Get(_ID);
    if Army and Army.Strength > Army:GetNumberOfLeader(true) then
        local Position = _Position;
        if type(Position) ~= "table" then
            Position = GetPosition(_Position);
        end
        local TroopID = AI.Entity_CreateFormation(Army.PlayerID, _Type, 0, 0, _Position.X, _Position.Y, 0, 0, _Exp or 0, 0);
        assert(TroopID ~= nil);
        for i= 1, Logic.LeaderGetMaxNumberOfSoldiers(TroopID) do
            local SoldierType = Logic.LeaderGetSoldiersType(TroopID);
            Logic.CreateEntity(SoldierType, _Position.X, _Position.Y, 0, Army.PlayerID);
            Tools.AttachSoldiersToLeader(TroopID, 1);
        end
        return AiArmy.AddTroop(_ID, TroopID, true);
    end
    return false;
end

--- Removes a troop from an army.
--- 
--- Returns true on success and false on failure. A failure usually means
--- either the army or the troop might not exist.
--- 
--- @param _ID number      ID of army
--- @param _TroopID number ID of troop
--- @return boolean Removed Was successfully removed
function AiArmy.RemoveTroop(_ID, _TroopID)
    local Army = AiArmy.Get(_ID);
    if Army then
        return Army:RemoveTroop(_TroopID) ~= 0;
    end
    return false;
end

--- Returns the army ID the troop is connected to if any.
--- @param _ID number ID of troop
--- @return number ID ID of army
function AiArmy.GetArmyOfTroop(_ID)
    if AiArmyData_ReinforcementIdToArmyId[_ID] then
        return AiArmyData_ReinforcementIdToArmyId[_ID];
    end
    if AiArmyData_TroopIdToArmyId[_ID] then
        return AiArmyData_TroopIdToArmyId[_ID];
    end
    return 0;
end

--- Returns if the army is alive.
--- 
--- A Army is alive when it has troops. Add troops to a dead army and it will
--- rise like Lazarus. ;)
--- 
--- @param _ID number ID of army
--- @return boolean Army is alive
function AiArmy.IsAlive(_ID)
    local Army = AiArmy.Get(_ID);
    if Army then
        return Army:IsAlive();
    end
    return false;
end

--- Returns the number of leader attached to the army.
--- @param _ID number                 ID of army
--- @return number Amount Leader count of army
function AiArmy.GetNumberOfLeader(_ID)
    local Army = AiArmy.Get(_ID);
    if Army then
        return Army:GetNumberOfLeader(true);
    end
    return 0;
end

--- Returns the max number of leader the army can have.
--- @param _ID number                 ID of army
--- @return number Amount Leader count of army
function AiArmy.GetMaxNumberOfLeader(_ID)
    local Army = AiArmy.Get(_ID);
    if Army then
        return Army.Strength;
    end
    return 0;
end

--- Returns if the army has the max amount of leaders and if the leader have
--- a full regiment of soldiers.
--- @param _ID number ID of army
--- @return boolean FullStrength Army is full
function AiArmy.HasFullStrength(_ID)
    local Army = AiArmy.Get(_ID);
    if Army then
        return Army.Strength <= Army:GetCurrentStregth(true);
    end
    return false;
end

--- Forcefully changes the state of the army.
--- (Do not use unless you know what you are doing!)
--- @param _ID number    ID of army
--- @param _State number ID of state
function AiArmy.SetBehavior(_ID, _State)
    local Army = AiArmy.Get(_ID);
    if Army then
        Army:SetBehavior(_State)
    end
end

--- Changes the target position of the army.
---
--- The army will automatically walk to the position if possible. The army will
--- automatically attack enemies. They do not need a command to do so.
---
--- @param _ID number    ID of army
--- @param _Position any Target position of army
function AiArmy.SetPosition(_ID, _Position)
    local Army = AiArmy.Get(_ID);
    if Army then
        local Position = _Position;
        if type(Position) ~= "table" then
            Position = GetPosition(_Position);
        end
        return Army:SetPosition(Position);
    end
end

--- Changes the radius of action of the army.
--- 
--- If the anchor for a battle is already set it will still use the old
--- area of action until the battle has concluded.
--- 
--- @param _ID number   ID of army
--- @param _Area number Area size
function AiArmy.SetRodeLength(_ID, _Area)
    local Army = AiArmy.Get(_ID);
    if Army then
        return Army:SetRodeLength(_Area);
    end
end

--- Sets a function that overwrites which formation is given to troops.
--- @param _ID number           ID of army
--- @param _Controller function Formation controller function
function AiArmy.SetFormationController(_ID, _Controller)
    local Army = AiArmy.Get(_ID);
    if Army then
        Army:SetFormationController(_Controller);
    end
end

--- Resumes the army.
--- @param _ID number ID of army
function AiArmy.Resume(_ID)
    local Army = AiArmy.Get(_ID);
    if Army then
        Army:SetActive(true);
    end
end

--- Pauses the army.
--- 
--- Use this if you want to defunc the army without deleting it.
--- 
--- @param _ID number ID of army
function AiArmy.Yield(_ID)
    local Army = AiArmy.Get(_ID);
    if Army then
        Army:SetActive(false);
    end
end

--- Commands an army to hold position. 
--- (Use this inside a job.)
--- @param _ID number    ID of army
--- @param _Target table Position to defend
function AiArmy:Defend(_ID, _Target)
    local Army = AiArmy.Get(_ID);
    if Army then
        Army:SetPosition(_Target);
    end
end

--- Commands an army to advance to a position. 
--- (Use this inside a job.)
--- @param _ID number    ID of army
--- @param _Target table Position to attack
function AiArmy:Advance(_ID, _Target)
    local Army = AiArmy.Get(_ID);
    if Army then
        if GetDistance(Army:GetArmyPosition(), _Target) > 1200 then
            Army:SetPosition(_Target);
        end
    end
end

--- Commands an army to retreat to the home position. 
--- (Use this inside a job.)
---
--- If enemies are encountered the army will hold the position and fight
--- angainst them.
---
--- @param _ID number ID of army
function AiArmy:Retreat(_ID)
    local Army = AiArmy.Get(_ID);
    if Army then
        local Position = Army:GetArmyPosition();
        if AreEnemiesInArea(Army.PlayerID, Position, Army.RodeLength) then
            Army:SetPosition(Position);
        elseif GetDistance(Position, Army.HomePosition) > 1200 then
            Army:SetPosition(Army.HomePosition);
        end
    end
end

--- Commands an army to haistly retreat to the home position. 
--- (Use this inside a job.)
---
--- Enemies are ignored.
---
--- @param _ID number ID of army
function AiArmy:Fallback(_ID)
    local Army = AiArmy.Get(_ID);
    if Army then
        if Army.Position then
            for j= 1, table.getn(Army.Reinforcements) do
                Logic.SettlerStand(Army.Reinforcements[j]);
            end
            for j= 1, table.getn(Army.Troops) do
                Logic.SettlerStand(Army.Troops[j]);
            end
        end
        Army:SetAnchor(nil);
        Army:SetPosition(nil);
        Army:ResetArmySpeed();
    end
end

-- -------------------------------------------------------------------------- --
-- Internal

AiArmy.Internal = AiArmy.Internal or {
    Data = {},
};

function AiArmy.Internal:Install()
    if not self.isInstalled then
        self.isInstalled = true;

        AiArmyControllerJobId = Job.Turn(function ()
            AiArmy.Internal:Controller();
        end);
    end
end

function AiArmy.Internal:IsTroopAlive(_TroopID)
    if not IsExisting(_TroopID) then
        return false;
    end
    local Task = Logic.GetCurrentTaskList(_TroopID);
    if Task and string.find(Task, "DIE") then
        return false;
    end
    return Logic.GetEntityHealth(_TroopID) > 0;
end

function AiArmy.Internal:IsTroopFighting(_TroopID)
    return IsFighting(_TroopID);
end

function AiArmy.Internal:IsTroopTraining(_TroopID)
    local Task = Logic.GetCurrentTaskList(_TroopID);
    if Task and string.find(Task, "TRAIN") then
        return true;
    end
    return false;
end

function AiArmy.Internal:IsTroopMoving(_TroopID)
    return Logic.IsEntityMoving(_TroopID) == true;
end

function AiArmy.Internal:Controller()
    local Turn = Logic.GetCurrentTurn();

    local QualifyingArmies = {};
    for k,v in pairs(AiArmyData_ArmyIdToArmyInstance) do
        if v.Active then
            ---@diagnostic disable-next-line: undefined-field
            if math.mod(Turn, 10) == v.Tick and v.LastTick+19 < Turn then
                table.insert(QualifyingArmies, v);
            end
        end
    end

    for i= table.getn(QualifyingArmies), 1, -1 do
        local Army = QualifyingArmies[i];
        Army:SetLastTick(Turn);
        Army:ManageArmyMembers();

        if not Army:IsAlive() then
            Army:SetBehavior(AiArmy.Behavior.REFILL);
            Army:SetPosition(nil);
            Army:SetAnchor(nil, nil);
            Army:Abadon(true);
        end

        if Army.Behavior == AiArmy.Behavior.WAITING then
            Army:WaitBehavior();
        elseif Army.Behavior == AiArmy.Behavior.REFILL then
            Army:RefillBehavior();
        elseif Army.Behavior == AiArmy.Behavior.ADVANCE then
            Army:AdvanceBehavior();
        elseif Army.Behavior == AiArmy.Behavior.BATTLE then
            Army:BattleBehavior();
        elseif Army.Behavior == AiArmy.Behavior.REGROUP then
            Army:RegroupBehavior();
        end
    end
end

-- Checks for enemies in the area and removes not reachable.
function AiArmy.Internal:GetEnemiesInTerritory(_PlayerID, _Position, _Area, _TroopID)
    local PlayerID = (_TroopID and Logic.EntityGetPlayer(_TroopID)) or _PlayerID;
    local Position = (_TroopID and GetPosition(_TroopID)) or _Position;
    local Enemies = GetEnemiesInArea(PlayerID, Position, _Area);
    for i= table.getn(Enemies), 1, -1 do
        local Task = Logic.GetCurrentTaskList(Enemies[i]);
        if not IsExisting(Enemies[i])
        or (Task and string.find(Task, "DIE") ~= nil)
        or Logic.GetEntityHealth(Enemies[i]) == 0
        or not ArePositionsConnected(Enemies[i], Position)
        or GetDistance(Position, Enemies[i]) > _Area then
            table.remove(Enemies, i);
        end
    end
    return Enemies;
end

-- Returns the best target for the troop from the target list.
function AiArmy.Internal:PriorityTarget(_TroopID, _Enemies)
    local EnemiesList = CopyTable(_Enemies);
    if table.getn(EnemiesList) > 1 then
        table.sort(EnemiesList, function(a, b)
            local Priority1 = AiArmy.Internal:GetAttackingCosts(_TroopID, a);
            local Priority2 = AiArmy.Internal:GetAttackingCosts(_TroopID, b);
            return Priority1 < Priority2;
        end);
    end
    return EnemiesList[1];
end

function AiArmy.Internal:GetAttackingCosts(_TroopID, _EnemyID)
    -- Obtain base priority factor
    local Factor = 1.0;
    local Priorities = self:GetPriorityFactorMap(_TroopID);
    for k, v in pairs(GetEntityCategoriesAsString(_EnemyID)) do
        if not Priorities[v] then
            Factor = 0;
            break;
        end
        Factor = Factor * (1/Priorities[v]);
    end
    -- Adjust factor by threat potency
    -- (Leaders with more soldiers will do more damage and are higher up on
    -- the kill list)
    if Factor > 0 and Logic.IsLeader(_EnemyID) == 1 then
        local Maximum = Logic.LeaderGetMaxNumberOfSoldiers(_EnemyID);
        if Maximum > 0 then
            local Current = Logic.LeaderGetNumberOfSoldiers(_EnemyID);
            Factor = Factor * (1/((Current+1)/(Maximum+1)));
        else
            Factor = Factor * 10;
        end
    end
    -- Set costs by distance
    if Factor > 0 then
        local Costs = GetDistance(_TroopID, _EnemyID);
        return Factor * Costs;
    end
    return Logic.WorldGetSize();
end

function AiArmy.Internal:GetPriorityFactorMap(_TroopID)
    if Logic.IsEntityInCategory(_TroopID, EntityCategories.EvilLeader) == 1
    or Logic.GetEntityType(_TroopID) == Entities.CU_Evil_LeaderSkirmisher then
        return AiArmyConfig.Targeting.LongRange;
    end
    if Logic.IsEntityInCategory(_TroopID, EntityCategories.Rifle) == 1
    or Logic.GetEntityType(_TroopID) == Entities.PU_Hero10 then
        return AiArmyConfig.Targeting.Rifle;
    end
    if Logic.IsEntityInCategory(_TroopID, EntityCategories.LongRange) == 1
    or Logic.GetEntityType(_TroopID) == Entities.PU_Hero5 then
        return AiArmyConfig.Targeting.LongRange;
    end
    if Logic.IsEntityInCategory(_TroopID, EntityCategories.Spear) == 1 then
        return AiArmyConfig.Targeting.Spear;
    end
    if Logic.IsEntityInCategory(_TroopID, EntityCategories.CavalryHeavy) == 1 then
        return AiArmyConfig.Targeting.CavalryHeavy;
    end
    if Logic.IsEntityInCategory(_TroopID, EntityCategories.Cannon) == 1 then
        return AiArmyConfig.Targeting.Cannon;
    end
    return AiArmyConfig.Targeting.Sword;
end

-- -------------------------------------------------------------------------- --
-- Model

AiArmy.Internal.Army = AiArmy.Internal.Army or {
    ID              = 0,
    Active          = true,
    PlayerID        = 1,
    State           = 0;
    Strength        = 8,
    RodeLength  	= 3000,
    HomePosition    = nil,
    Position        = nil,
    DefeatThreshold = 0.10,
    LastTick        = 0,

    Targets         = {},
    Reinforcements  = {},
    Troops          = {},
    CleanUp         = {},

    Anchor          = {
        Position    = nil,
        RodeLength  = nil,
    },
};

AiArmyData_TroopIdToArmyId = AiArmyData_TroopIdToArmyId  or {};
AiArmyData_ReinforcementIdToArmyId = AiArmyData_ReinforcementIdToArmyId  or {};
AiArmyData_ArmyIdToArmyInstance = AiArmyData_ArmyIdToArmyInstance  or {};
AiArmyData_IdSequence = AiArmyData_IdSequence  or 0;

function AiArmy.Internal.Army:New(_PlayerID, _Strength, _Position, _RodeLength)
    AiArmyData_IdSequence = AiArmyData_IdSequence +1;
    AiArmy.Internal:Install();

    local Army = CopyTable(self);
    Army.ID = AiArmyData_IdSequence;
    Army.PlayerID = _PlayerID;
    Army.Behavior = AiArmy.Behavior.WAITING;
    ---@diagnostic disable-next-line: undefined-field
    Army.Tick = math.mod(self.ID, 10);
    Army.HomePosition = _Position;
    Army.RodeLength = _RodeLength;
    Army.Strength = _Strength;
    Army.FormationController = nil;
    return Army;
end

function AiArmy.Internal.Army:Dispose()
    self:Abadon(false);
    AiArmyData_ArmyIdToArmyInstance[self.ID] = nil;
end

function AiArmy.Internal.Army:WaitBehavior()
    self:ResetArmySpeed();
    local ArmyPosition = self:GetArmyPosition();
    if AreEnemiesInArea(self.PlayerID, ArmyPosition, self.RodeLength) then
        local Enemies = AiArmy.Internal:GetEnemiesInTerritory(self.PlayerID, ArmyPosition, self.RodeLength);
        if Enemies[1] then
            self:SetBehavior(AiArmy.Behavior.BATTLE);
            self:SetAnchor(GetPosition(Enemies[1]), self.RodeLength);
        end
    else
        if self.Position then
            if ArePositionsConnected(ArmyPosition, self.Position) then
                if GetDistance(ArmyPosition, self.Position) > 1200 then
                    self:SetBehavior(AiArmy.Behavior.ADVANCE);
                end
            end
        else
            if ArePositionsConnected(ArmyPosition, self.HomePosition) then
                if GetDistance(ArmyPosition, self.HomePosition) > 1200 then
                    for j= 1, table.getn(self.Troops) do
                        if Logic.IsEntityMoving(self.Troops[j]) == false then
                            Logic.MoveSettler(self.Troops[j], self.HomePosition.X, self.HomePosition.Y);
                        end
                    end
                end
            end
        end
    end
end

function AiArmy.Internal.Army:RefillBehavior()
    self:ResetArmySpeed();
    local ArmyPosition = self:GetArmyPosition();
    if AreEnemiesInArea(self.PlayerID, ArmyPosition, self.RodeLength) then
        local Enemies = AiArmy.Internal:GetEnemiesInTerritory(self.PlayerID, ArmyPosition, self.RodeLength);
        if Enemies[1] then
            self:SetBehavior(AiArmy.Behavior.BATTLE);
            self:SetAnchor(GetPosition(Enemies[1]), self.RodeLength);
        end
    else
        if self:GetCurrentStregth() >= 1 then
            self:SetBehavior(AiArmy.Behavior.WAITING);
        end
    end
end

function AiArmy.Internal.Army:AdvanceBehavior()
    self:NormalizedArmySpeed();
    local EncounteredEnemy = 0;
    for j= 1, table.getn(self.Troops) do
        local Exploration = Logic.GetEntityExplorationRange(self.Troops[j]);
        if AreEnemiesInArea(self.PlayerID, self.Troops[j], Exploration * 100) then
            local Enemies = AiArmy.Internal:GetEnemiesInTerritory(self.PlayerID, GetPosition(self.Troops[j]), Exploration * 100);
            if Enemies[1] then
                EncounteredEnemy = Enemies[1];
            end
            break;
        end
    end

    if EncounteredEnemy ~= 0 then
        self:SetBehavior(AiArmy.Behavior.BATTLE);
        self:SetAnchor(GetPosition(EncounteredEnemy), self.RodeLength);
        for j= 1, table.getn(self.Troops) do
            Logic.GroupAttackMove(self.Troops[j], self.Anchor.Position.X, self.Anchor.Position.Y);
        end
    else
        if self:IsScattered() then
            self:SetBehavior(AiArmy.Behavior.REGROUP);
            for j= 1, table.getn(self.Troops) do
                Logic.SettlerStand(self.Troops[j]);
            end
        else
            local ArmyPosition = self:GetArmyPosition();
            if ArePositionsConnected(ArmyPosition, self.Position) then
                if GetDistance(ArmyPosition, self.Position) > 1200 then
                    for j= 1, table.getn(self.Troops) do
                        Logic.MoveSettler(self.Troops[j], self.Position.X, self.Position.Y);
                    end
                else
                    self:SetBehavior(AiArmy.Behavior.WAITING);
                end
            end
        end
    end
end

function AiArmy.Internal.Army:BattleBehavior()
    if not AreEnemiesInArea(self.PlayerID, self.Anchor.Position, self.Anchor.RodeLength) then
        self:SetBehavior(AiArmy.Behavior.REGROUP);
        self:SetAnchor(nil, nil);
    else
        self:ResetArmySpeed();
        for j= 1, table.getn(self.Troops) do
            if GetDistance(self.Anchor.Position, self.Troops[j]) > self.Anchor.RodeLength then
                Logic.MoveSettler(self.Troops[j], self.Anchor.Position.X, self.Anchor.Position.Y);
                self:LockOn(self.Troops[j], nil);
            else
                if not self.Targets[self.Troops[j]] then
                    local Enemies = AiArmy.Internal:GetEnemiesInTerritory(self.PlayerID, self.Anchor.Position, self.Anchor.RodeLength, self.Troops[j]);
                    if Enemies[1] then
                        local TargetID = AiArmy.Internal:PriorityTarget(self.Troops[j], Enemies);
                        self:LockOn(self.Troops[j], TargetID);
                        Logic.GroupAttack(self.Troops[j], TargetID);
                    else
                        local ArmyPosition = self:GetArmyPosition();
                        if GetDistance(ArmyPosition, self.Anchor.Position) > 1200 then
                            Logic.MoveSettler(self.Troops[j], self.Anchor.Position.X, self.Anchor.Position.Y);
                        end
                    end
                end
            end
        end
    end
end

function AiArmy.Internal.Army:RegroupBehavior()
    local ArmyPosition = self:GetArmyPosition();
    self:NormalizedArmySpeed();
    if AreEnemiesInArea(self.PlayerID, ArmyPosition, self.RodeLength) then
        local Enemies = AiArmy.Internal:GetEnemiesInTerritory(self.PlayerID, ArmyPosition, self.RodeLength);
        if Enemies[1] then
            self:SetBehavior(AiArmy.Behavior.BATTLE);
            self:SetAnchor(GetPosition(Enemies[1]), self.RodeLength);
        end
    else
        if self:IsScattered() then
            for j= 1, table.getn(self.Troops) do
                Logic.MoveSettler(self.Troops[j], ArmyPosition.X, ArmyPosition.Y);
            end
        else
            if self.Position then
                self:SetBehavior(AiArmy.Behavior.WAITING);
            else
                self:SetBehavior(AiArmy.Behavior.REFILL);
            end
        end
    end
end

function AiArmy.Internal.Army:ManageArmyMembers()
    -- Update reinforcements
    for j= table.getn(self.Reinforcements), 1, -1 do
        if not AiArmy.Internal:IsTroopAlive(self.Reinforcements[j]) then
            local ID = table.remove(self.Reinforcements, j);
            AiArmyData_ReinforcementIdToArmyId[ID] = nil;
        elseif GetDistance(self.Reinforcements[j], self:GetArmyPosition()) <= 1500 then
            local ID = table.remove(self.Reinforcements, j);
            AiArmyData_ReinforcementIdToArmyId[ID] = nil;
            self:AddTroop(ID, false);
        else
            if Logic.IsEntityMoving(self.Reinforcements[j]) == false then
                local Position = self:GetArmyPosition();
                Logic.GroupAttackMove(self.Reinforcements[j], Position.X, Position.Y);
            end
        end
    end

    -- Update current troops
    for j= table.getn(self.Troops), 1, -1 do
        if not AiArmy.Internal:IsTroopAlive(self.Troops[j]) then
            self:LockOn(self.Troops[j], nil);
            local ID = table.remove(self.Troops, j);
            AiArmyData_TroopIdToArmyId[ID] = nil;
        end
    end

    -- Update troop cleanup
    for j= table.getn(self.CleanUp), 1, -1 do
        local Alive = AiArmy.Internal:IsTroopAlive(self.CleanUp[j]);
        local Fighting = AiArmy.Internal:IsTroopFighting(self.CleanUp[j]);
        local Moving = AiArmy.Internal:IsTroopMoving(self.CleanUp[j]);
        if not Alive or not Fighting or not Moving then
            AiArmyData_TroopIdToArmyId[ID] = nil;
            local ID = table.remove(self.CleanUp, j);
            self:LockOn(ID, nil);
            if not Fighting and not Moving then
                local Soldiers = {Logic.GetSoldiersAttachedToLeader(ID)};
                for i= Soldiers[1] +1, 1, -1 do
                    SetHealth(Soldiers[i], 0);
                end
                SetHealth(ID, 0);
            end
        end
    end

    -- Update troop targets
    for j= table.getn(self.Targets), 1, -1 do
        if not AiArmy.Internal:IsTroopAlive(self.Targets[j][2])
        or self.Targets[j][3] == nil
        or Logic.GetTime() > self.Targets[j][3]+15 then
            table.remove(self.Targets, j);
        end
    end
end

function AiArmy.Internal.Army:AddTroop(_ID, _Reinforcement)
    if self:GetNumberOfLeader(true) < self.Strength then
        if AiArmyData_TroopIdToArmyId[_ID] then
            return false;
        end
        if AiArmyData_ReinforcementIdToArmyId[_ID] then
            return false;
        end

        if AiArmy.Internal:IsTroopAlive(_ID) then
            AI.Army_EnableLeaderAi(_ID, 0);
            if self.FormationController then
                self:FormationController(_ID);
            else
                self:ChoseFormation(_ID);
            end
        end
        if _Reinforcement then
            AiArmyData_ReinforcementIdToArmyId[_ID] = self.ID;
            table.insert(self.Reinforcements, _ID);
        else
            AiArmyData_TroopIdToArmyId[_ID] = self.ID;
            table.insert(self.Troops, _ID);
        end
        return true;
    end
    return false;
end

function AiArmy.Internal.Army:RemoveTroop(_ID)
    for i= table.getn(self.Reinforcements), 1, -1 do
        if self.Reinforcements[i] == _ID then
            if AiArmy.Internal:IsTroopAlive(_ID) then
                AI.Army_EnableLeaderAi(_ID, 1);
            end
            AiArmyData_ReinforcementIdToArmyId[_ID] = nil;
            return table.remove(self.Troops, i);
        end
    end
    for i= table.getn(self.Troops), 1, -1 do
        if self.Troops[i] == _ID then
            if AiArmy.Internal:IsTroopAlive(_ID) then
                AI.Army_EnableLeaderAi(_ID, 1);
            end
            AiArmyData_TroopIdToArmyId[_ID] = nil;
            return table.remove(self.Troops, i);
        end
    end
    return 0;
end

function AiArmy.Internal.Army:Abadon(_KillLater)
    for i= table.getn(self.Reinforcements), 1, -1 do
        local ID = self:RemoveTroop(self.Reinforcements[i]);
        if _KillLater and ID ~= 0 and IsExisting(ID) then
            table.insert(self.CleanUp, ID);
        end
    end
    for i= table.getn(self.Troops), 1, -1 do
        local ID = self:RemoveTroop(self.Troops[i]);
        if _KillLater and ID ~= 0 and IsExisting(ID) then
            table.insert(self.CleanUp, ID);
        end
    end
end

function AiArmy.Internal.Army:LockOn(_TroopID, _TargetID)
    if _TargetID ~= nil then
        table.insert(self.Targets, {_TroopID, _TargetID, Logic.GetTime()});
    else
        for i= table.getn(self.Targets), 1, -1 do
            if self.Targets[i][1] == _TroopID then
                table.remove(self.Targets, i);
            end
        end
    end
end

function AiArmy.Internal.Army:SetActive(_Active)
    self.Active = _Active == true;
end

function AiArmy.Internal.Army:SetBehavior(_State)
    self.Behavior = _State;
end

function AiArmy.Internal.Army:SetPosition(_Position)
    self.Position = _Position;
end

function AiArmy.Internal.Army:SetRodeLength(_RodeLength)
    self.RodeLength = _RodeLength;
end

function AiArmy.Internal.Army:SetFormationController(_FormationController)
    self.FormationController = _FormationController;
end

function AiArmy.Internal.Army:SetStrength(_Strength)
    self.Strength = _Strength;
end

function AiArmy.Internal.Army:SetAnchor(_Position, _RodeLength)
    self.Anchor.RodeLength = _RodeLength;
    self.Anchor.Position = _Position;
end

function AiArmy.Internal.Army:SetLastTick(_Time)
    self.LastTick = _Time;
end

function AiArmy.Internal.Army:GetNumberOfLeader(_WithReinforcments)
    local Amount = table.getn(self.Troops);
    if _WithReinforcments then
        Amount = Amount + table.getn(self.Reinforcements);
    end
    return Amount;
end

--- @return table
function AiArmy.Internal.Army:GetArmyPosition()
    if self:GetNumberOfLeader(false) > 0 then
        return GetGeometricCenter(unpack(self.Troops));
    end
    return self.HomePosition;
end

function AiArmy.Internal.Army:IsAlive()
    return self:GetNumberOfLeader(true) > 0 and self:GetCurrentStregth(true) > self.DefeatThreshold;
end

function AiArmy.Internal.Army:GetCurrentStregth(_WithReinforcments)
    local CurStrength = 0;
    local Troops = CopyTable(self.Troops, {});
    if _WithReinforcments then
        Troops = CopyTable(self.Reinforcements, Troops);
    end
    for i= table.getn(Troops), 1, -1 do
        local StrValue = 1;
        if Logic.IsLeader(Troops[i]) == 1 then
            local MaxSoldiers = Logic.LeaderGetMaxNumberOfSoldiers(Troops[i]);
            if MaxSoldiers > 0 then
                StrValue = (Logic.LeaderGetNumberOfSoldiers(Troops[i])/MaxSoldiers);
            end
        end
        CurStrength = CurStrength + StrValue;
    end
    return CurStrength / self.Strength;
end

function AiArmy.Internal.Army:IsScattered()
    for i= 1, table.getn(self.Troops) do
        if IsExisting(self.Troops[i]) then
            if GetDistance(self:GetArmyPosition(), self.Troops[i]) > self.RodeLength * 0.75 then
                return true;
            end
        end
    end
    return false;
end

function AiArmy.Internal.Army:ChoseFormation(_TroopID)
    if Logic.IsEntityInCategory(_TroopID, EntityCategories.EvilLeader) == 1 then
        return;
    elseif Logic.IsEntityInCategory(_TroopID, EntityCategories.CavalryHeavy) == 1 then
        Logic.LeaderChangeFormationType(_TroopID, 6);
        return;
    end
    Logic.LeaderChangeFormationType(_TroopID, 4);
end

function AiArmy.Internal.Army:NormalizedArmySpeed()
    local TroopSpeed = 0;
    local AbsoluteTroopAmount = 0;
    local Dividend = 0;
    local TroopSpeedTable = {};
    -- Get unit speeds
    for i= 1, table.getn(self.Troops), 1 do
        local First = self:GetTroopSpeedConfigKey(self.Troops[i]);
        First = (AiArmyConfig.SpeedWeighting[First] and First) or "_Others";
        TroopSpeedTable[First] = TroopSpeedTable[First] or {};
        TroopSpeedTable[First][1] = AiArmyConfig.SpeedWeighting[First];
        TroopSpeedTable[First][2] = (TroopSpeedTable[First][2] or 0) +1;
        AbsoluteTroopAmount = AbsoluteTroopAmount +1;
    end
    -- Calculate army
    for k, v in pairs(TroopSpeedTable) do
        Dividend = Dividend + (v[1]*v[2]*AiArmyConfig.BaseSpeed[k]);
    end
    Dividend = Dividend + AiArmyConfig.SpeedWeighting["_Others"];
    TroopSpeed = Dividend/(AbsoluteTroopAmount+1);
    -- Set speed factor
    for i= 1, table.getn(self.Troops), 1 do
        local First = self:GetTroopSpeedConfigKey(self.Troops[i]);
        local NewSpeed = (TroopSpeed >= 250 and TroopSpeed) or 250;
        self:SetTroopSpeed(self.Troops[i], NewSpeed/AiArmyConfig.BaseSpeed[First]);
    end
end

function AiArmy.Internal.Army:ResetArmySpeed()
    for i= 1, table.getn(self.Troops), 1 do
        self:SetTroopSpeed(self.Troops[i], 1.0);
    end
end

function AiArmy.Internal.Army:SetTroopSpeed(_TroopID, _Factor)
    if AiArmy.Internal:IsTroopAlive(_TroopID) then
        Logic.SetSpeedFactor(_TroopID, _Factor);
        if Logic.IsLeader(_TroopID) == 1 then
            local Soldiers = {Logic.GetSoldiersAttachedToLeader(_TroopID)};
            for i= 2, Soldiers[1]+1, 1 do
                if AiArmy.Internal:IsTroopAlive(_TroopID) then
                    Logic.SetSpeedFactor(Soldiers[i], _Factor);
                end
            end
        end
    end
end

function AiArmy.Internal.Army:GetTroopSpeedConfigKey(_TroopID)
    if AiArmy.Internal:IsTroopAlive(_TroopID) then
        local TypeName = Logic.GetEntityTypeName(Logic.GetEntityType(_TroopID));
        if AiArmyConfig.BaseSpeed[TypeName] then
            return TypeName;
        else
            for k, v in pairs(GetEntityCategoriesAsString(_TroopID)) do
                if AiArmyConfig.BaseSpeed[v] then
                    return v;
                end
            end
        end
    end
    return "_Others";
end

-- -------------------------------------------------------------------------- --
-- Config

AiArmyConfig = {
    -- Configures the favorite target type of specific entity categories.
    -- (The lower the less focus. No entry means 0.)
    Targeting = {
        Sword = {
            ["Hero"] = 1.0,
            ["LongRange"] = 0.9,
            ["Spear"] = 0.9,
        },
        Spear = {
            ["CavalryHeavy"] = 1.0,
            ["CavalryLight"] = 0.8,
        },
        CavalryHeavy = {
            ["Hero"] = 1.0,
            ["LongRange"] = 0.9,
            ["Sword"] = 0.75,
            ["MilitaryBuilding"] = 0.4,
        },
        LongRange = {
            ["Hero"] = 1.0,
            ["CavalryHeavy"] = 0.9,
            ["CavalryLight"] = 0.7,
            ["Spear"] = 0.6,
        },
        Rifle = {
            ["MilitaryBuilding"] = 1.0,
            ["EvilLeader"] = 1.0,
            ["LongRange"] = 0.8,
        },
        Cannon = {
            ["MilitaryBuilding"] = 1.0,
            ["EvilLeader"] = 1.0,
            ["LongRange"] = 0.7,
        }
    },

    -- Holds the basic speed of the units.
    BaseSpeed = {
        ["Bow"] = 320,
        ["CavalryLight"] = 500,
        ["CavalryHeavy"] = 500,
        ["Hero"] = 400,
        ["Rifle"] = 320,

        ["PV_Cannon1"] = 240,
        ["PV_Cannon2"] = 260,
        ["PV_Cannon3"] = 220,
        ["PV_Cannon4"] = 180,

        ["_Others"] = 360,
    },

    -- Configures how much a singular base speed influences the calculated
    -- average speed of the army.
    -- (We do not want wo make anyone as slow as the slowest unit!)
    SpeedWeighting = {
        ["CavalryLight"] = 0.4,
        ["CavalryHeavy"] = 0.4,

        ["PV_Cannon3"] = 0.3,
        ["PV_Cannon4"] = 0.1,

        ["_Others"] = 1.0
    }
}

