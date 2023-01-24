Lib.Require("comfort/AreEnemiesInArea");
Lib.Require("comfort/CopyTable");
Lib.Require("comfort/GetDistance");
Lib.Require("comfort/GetEnemiesOfEntity");
Lib.Require("comfort/GetEntityCategoriesAsString");
Lib.Require("comfort/GetGeometricCenter");
Lib.Require("comfort/IsFighting");
Lib.Require("comfort/StartInlineTrigger");
Lib.Register("module/army/AiArmy");

---
--- AI army script
---
--- Creates an army that automatically attacks enemies in reach. It also tries
--- to not focus on a single target and makes use of max range attacks.
---
--- @author totalwarANGEL
--- @version 1.0.0
---

AiArmy = AiArmy or {
    Behavior = {
        WAITING = 1,
        PASSIVE = 2,
        ADVANCE = 3,
        REGROUP = 4,
        BATTLE = 5,
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
    table.insert(AiArmy.Internal.Data.Armies, Army);
    return Army.ID;
end

--- comment
--- @param _ID any
function AiArmy.Delete(_ID)
    for i= table.getn(AiArmy.Internal.Data.Armies), 1, -1 do
        if AiArmy.Internal.Data.Armies[i].ID == _ID then
            for j= table.getn(AiArmy.Internal.Data.Armies[i].Troops), 1, -1 do
                local TroopID = AiArmy.Internal.Data.Armies[i].Troops[j];
                AiArmy.Internal.Data.Armies[i]:RemoveTroop(TroopID);
            end
            table.remove(AiArmy.Internal.Data.Armies, i);
            return;
        end
    end
end

--- comment
--- @param _ID any
--- @return unknown
function AiArmy.Get(_ID)
    for i= 1, table.getn(AiArmy.Internal.Data.Armies) do
        if AiArmy.Internal.Data.Armies[i].ID == _ID then
            return AiArmy.Internal.Data.Armies[i];
        end
    end
    return 0;
end

--- comment
--- @param _ID any
--- @param _TroopID any
--- @return unknown
function AiArmy.AddTroop(_ID, _TroopID)
    local Army = AiArmy.Get(_ID);
    if Army then
        return Army:AddTroop(_TroopID);
    end
    return false;
end

--- comment
--- @param _ID any
--- @param _TroopID any
--- @return unknown
function AiArmy.RemoveTroop(_ID, _TroopID)
    local Army = AiArmy.Get(_ID);
    if Army then
        return Army:RemoveTroop(_TroopID);
    end
    return false;
end

--- comment
--- @param _ID any
--- @param _Position any
--- @return unknown
function AiArmy.SetPosition(_ID, _Position)
    local Army = AiArmy.Get(_ID);
    if Army then
        return Army:SetPosition(_Position);
    end
    return false;
end

--- comment
--- @param _ID any
--- @param _Area any
--- @return unknown
function AiArmy.SetRodeLength(_ID, _Area)
    local Army = AiArmy.Get(_ID);
    if Army then
        return Army:SetRodeLength(_Area);
    end
    return false;
end

--- comment
--- @param _ID any
--- @param _Position any
--- @param _Area any
function AiArmy.SetAnchor(_ID, _Position, _Area)
    local Army = AiArmy.Get(_ID);
    if Army then
        Army:SetAnchor(_Position, _Area);
    end
end

--- comment
--- @param _ID any
--- @param _State any
function AiArmy.SetState(_ID, _State)
    local Army = AiArmy.Get(_ID);
    if Army then
        Army:SetState(_State);
    end
end

--- comment
--- @param _ID any
function AiArmy.Resume(_ID)
    local Army = AiArmy.Get(_ID);
    if Army then
        Army:SetActive(true);
    end
end

--- comment
--- @param _ID any
function AiArmy.Yield(_ID)
    local Army = AiArmy.Get(_ID);
    if Army then
        Army:SetActive(false);
    end
end

-- -------------------------------------------------------------------------- --
-- Internal

AiArmy.Internal = AiArmy.Internal or {
    Data = {
        Armies = {},
    },
};

function AiArmy.Internal:Install()
    if not self.isInstalled then
        self.isInstalled = true;

        StartSimpleTurnTrigger(function ()
            AiArmy.Internal:Controller();
        end);
    end
end

function AiArmy.Internal:IsTroopAlive(_TroopID)
    if not IsExisting(_TroopID) then
        return false;
    end
    local Task = Logic.GetCurrentTaskList(_TroopID);
    if not Task or string.find(Task, "DIE") then
        return false;
    end
    return Logic.GetEntityHealth(_TroopID) > 0;
end

function AiArmy.Internal:IsTroopFighting(_TroopID)
    return IsFighting(_TroopID);
end

function AiArmy.Internal:IsTroopMoving(_TroopID)
    return Logic.IsEntityMoving(_TroopID) == true;
end

function AiArmy.Internal:Controller()
    local Turn = Logic.GetCurrentTurn();

    local QualifyingArmies = {};
    for k,v in pairs(self.Data.Armies) do
        if v.Active and v:IsAlive() then
            if math.mod(Turn, 10) == v.Tick and v.LastTick+19 < Turn then
                table.insert(QualifyingArmies, v);
            end
        end
    end

    for i= table.getn(QualifyingArmies), 1, -1 do
        local Army = QualifyingArmies[i];
        Army:SetLastTick(Turn);

        -- Update troops
        Army:RemoveInvalidTroops();
        Army:RemoveInvalidTargets();

        -- Army is waiting to act
        if Army.State == AiArmy.Behavior.WAITING then
            if table.getn(Army.Troops) > 0 then
                local ArmyPosition = Army:GetArmyPosition();
                if AreEnemiesInArea(Army.PlayerID, ArmyPosition, Army.RodeLength) then
                    Army:SetState(AiArmy.Behavior.BATTLE);
                    Army:SetAnchor(ArmyPosition, Army.RodeLength);
                else
                    if Army.Position and GetDistance(ArmyPosition, Army.Position) > 1200 then
                        Army:SetState(AiArmy.Behavior.ADVANCE);
                    end
                end
            end

        -- Army is advancing to the target
        elseif Army.State == AiArmy.Behavior.ADVANCE then
            if table.getn(Army.Troops) > 0 then
                local TroopEncounteredEnemy = 0;
                for j= 1, table.getn(Army.Troops) do
                    local Exploration = Logic.GetEntityExplorationRange(Army.Troops[j]);
                    if AreEnemiesInArea(Army.PlayerID, Army.Troops[j], Exploration * 100) then
                        TroopEncounteredEnemy = Army.Troops[j];
                        break;
                    end
                end

                if TroopEncounteredEnemy ~= 0 then
                    Army:SetState(AiArmy.Behavior.BATTLE);
                    Army:SetAnchor(GetPosition(TroopEncounteredEnemy), Army.RodeLength);
                    for j= 1, table.getn(Army.Troops) do
                        Logic.GroupAttackMove(Army.Troops[j], Army.Anchor.Position.X, Army.Anchor.Position.Y);
                    end
                else
                    if not Army.Position then
                        Army:SetState(AiArmy.Behavior.WAITING);
                    else
                        if Army:IsScattered() then
                            Army:SetState(AiArmy.Behavior.REGROUP);
                            for j= 1, table.getn(Army.Troops) do
                                Logic.SettlerStand(Army.Troops[j]);
                            end
                        else
                            local ArmyPosition = Army:GetArmyPosition();
                            if GetDistance(ArmyPosition, Army.Position) > 1200 then
                                for j= 1, table.getn(Army.Troops) do
                                    Logic.MoveSettler(Army.Troops[j], Army.Position.X, Army.Position.Y);
                                end
                            else
                                Army:SetState(AiArmy.Behavior.WAITING);
                            end
                        end
                    end
                end
            else
                Army:SetState(AiArmy.Behavior.WAITING);
            end

        -- Army is combating enemies
        elseif Army.State == AiArmy.Behavior.BATTLE then
            if table.getn(Army.Troops) > 0 then
                if not AreEnemiesInArea(Army.PlayerID, Army.Anchor.Position, Army.Anchor.RodeLength) then
                    Army:SetState(AiArmy.Behavior.REGROUP);
                    Army:SetAnchor(nil, nil);
                else
                    for j= 1, table.getn(Army.Troops) do
                        if GetDistance(Army.Anchor.Position, Army.Troops[j]) > Army.Anchor.RodeLength then
                            Logic.MoveSettler(Army.Troops[j], Army.Anchor.Position.X, Army.Anchor.Position.Y);
                            Army:SetTroopTarget(Army.Troops[j], nil);
                        else
                            if not Army.Targets[Army.Troops[j]] then
                                local Enemies = self:GetLivingEnemies(Army.Troops[j], Army.RodeLength, 5);
                                if Enemies[1] then
                                    local TargetID = self:PriorityTarget(Army.Troops[j], Enemies);
                                    Army:SetTroopTarget(Army.Troops[j], TargetID);
                                    Logic.GroupAttack(Army.Troops[j], TargetID);
                                elseif table.getn(Army.Targets) > 0 then
                                    local TargetID = Army.Targets[math.random(1, table.getn(Army.Targets))][2];
                                    Army:SetTroopTarget(Army.Troops[j], TargetID);
                                    Logic.GroupAttack(Army.Troops[j], TargetID);
                                else
                                    Logic.GroupAttackMove(Army.Troops[j], Army.Anchor.Position.X, Army.Anchor.Position.Y);
                                end
                            end
                        end
                    end
                end
            else
                Army:SetState(AiArmy.Behavior.WAITING);
            end

        -- Army is regrouping
        elseif Army.State == AiArmy.Behavior.REGROUP then
            if table.getn(Army.Troops) > 0 then
                local ArmyPosition = Army:GetArmyPosition();
                if AreEnemiesInArea(Army.PlayerID, ArmyPosition, Army.RodeLength) then
                    Army:SetState(AiArmy.Behavior.BATTLE);
                    Army:SetAnchor(ArmyPosition, Army.RodeLength);
                else
                    if Army:IsScattered() then
                        for j= 1, table.getn(Army.Troops) do
                            Logic.MoveSettler(Army.Troops[j], ArmyPosition.X, ArmyPosition.Y);
                        end
                    else
                        Army:SetState(AiArmy.Behavior.WAITING);
                    end
                end
            else
                Army:SetState(AiArmy.Behavior.WAITING);
            end
        end
    end
end

function AiArmy.Internal:GetLivingEnemies(_TroopID, _Area, _CacheAge)
    local Enemies = GetEnemiesOfEntity(_TroopID, _Area, _CacheAge);
    for i= table.getn(Enemies), 1, -1 do
        if not IsExisting(Enemies[i]) then
            table.remove(Enemies, i);
        else
            local Task = Logic.GetCurrentTaskList(Enemies[i]);
            if (Task and string.find(Task, "DIE") ~= nil)
            or Logic.GetEntityHealth(Enemies[i]) == 0 then
                table.remove(Enemies, i);
            end
        end
    end
    return Enemies;
end

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
        return AiArmyTargetPriority.LongRange;
    end
    if Logic.IsEntityInCategory(_TroopID, EntityCategories.Rifle) == 1
    or Logic.GetEntityType(_TroopID) == Entities.PU_Hero10 then
        return AiArmyTargetPriority.Rifle;
    end
    if Logic.IsEntityInCategory(_TroopID, EntityCategories.LongRange) == 1
    or Logic.GetEntityType(_TroopID) == Entities.PU_Hero5 then
        return AiArmyTargetPriority.LongRange;
    end
    if Logic.IsEntityInCategory(_TroopID, EntityCategories.Spear) == 1 then
        return AiArmyTargetPriority.Spear;
    end
    if Logic.IsEntityInCategory(_TroopID, EntityCategories.CavalryHeavy) == 1 then
        return AiArmyTargetPriority.CavalryHeavy;
    end
    if Logic.IsEntityInCategory(_TroopID, EntityCategories.Cannon) == 1 then
        return AiArmyTargetPriority.Cannon;
    end
    return AiArmyTargetPriority.Sword;
end

-- -------------------------------------------------------------------------- --
-- Model

AiArmy.Internal.Army = AiArmy.Internal.Army or {
    ID              = 0,
    Active          = true,
    InitiallyFilled = false,
    PlayerID        = 1,
    State           = 0;
    Strength        = 8,
    RodeLength  	= 3000,
    HomePosition    = nil,
    Position        = nil,
    LastTick        = 0,

    Targets         = {},
    Troops          = {},

    Anchor          = {
        Position    = nil,
        RodeLength  = nil,
    },
};

function AiArmy.Internal.Army:New(_PlayerID, _Strength, _Position, _RodeLength)
    AiArmy.Internal:Install();

    self.ID = self.ID +1;

    local Army = CopyTable(self);
    Army.PlayerID = _PlayerID;
    Army.State = AiArmy.Behavior.WAITING;
    Army.Tick = math.mod(self.ID, 10);
    Army.HomePosition = _Position;
    Army.Position = _Position;
    Army.RodeLength = _RodeLength;
    Army.Strength = _Strength;
    return Army;
end

function AiArmy.Internal.Army:AddTroop(_ID)
    if self:GetNumberOfLeader() < self.Strength then
        for i= table.getn(self.Troops), 1, -1 do
            if self.Troops[i] == _ID then
                return false;
            end
        end
        if AiArmy.Internal:IsTroopAlive(_ID) then
            AI.Army_EnableLeaderAi(_ID, 0);
        end
        self.InitiallyFilled = true;
        table.insert(self.Troops, _ID);
        return true;
    end
    return false;
end

function AiArmy.Internal.Army:RemoveTroop(_ID)
    for i= table.getn(self.Troops), 1, -1 do
        if self.Troops[i] == _ID then
            if AiArmy.Internal:IsTroopAlive(_ID) then
                AI.Army_EnableLeaderAi(_ID, 1);
            end
            table.remove(self.Troops, i);
            return true;
        end
    end
    return false;
end

function AiArmy.Internal.Army:SetTroopTarget(_TroopID, _TargetID)
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

function AiArmy.Internal.Army:RemoveInvalidTroops()
    for j= table.getn(self.Troops), 1, -1 do
        if not AiArmy.Internal:IsTroopAlive(self.Troops[j]) then
            self:SetTroopTarget(self.Troops[j], nil);
            table.remove(self.Troops, j);
        end
    end
end

function AiArmy.Internal.Army:RemoveInvalidTargets()
    for j= table.getn(self.Targets), 1, -1 do
        if not AiArmy.Internal:IsTroopAlive(self.Targets[j][2])
        or self.Targets[j][3] == nil
        or Logic.GetTime() > self.Targets[j][3]+15 then
            table.remove(self.Targets, j);
        end
    end
end

function AiArmy.Internal.Army:SetActive(_Active)
    self.Active = _Active;
end

function AiArmy.Internal.Army:SetState(_State)
    self.State = _State;
end

function AiArmy.Internal.Army:SetPosition(_Position)
    self.Position = _Position;
end

function AiArmy.Internal.Army:SetRodeLength(_RodeLength)
    self.RodeLength = _RodeLength;
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

function AiArmy.Internal.Army:GetNumberOfLeader()
    return table.getn(self.Troops);
end

function AiArmy.Internal.Army:GetArmyPosition()
    if self:GetNumberOfLeader() > 0 then
        return GetGeometricCenter(unpack(self.Troops));
    end
    return GetPosition(self.HomePosition);
end

function AiArmy.Internal.Army:IsAlive()
    if self.InitiallyFilled then
        return self:GetNumberOfLeader() > 0;
    end
    return true;
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

-- -------------------------------------------------------------------------- --
-- Config

AiArmyTargetPriority = {}

-- 
AiArmyTargetPriority.Sword = {
    ["Hero"] = 1.0,
    ["LongRange"] = 0.9,
    ["Spear"] = 0.9,
}
-- 
AiArmyTargetPriority.Spear = {
    ["CavalryHeavy"] = 1.0,
    ["CavalryLight"] = 0.8,
}
-- 
AiArmyTargetPriority.CavalryHeavy = {
    ["Hero"] = 1.0,
    ["LongRange"] = 0.9,
    ["Sword"] = 0.75,
    ["MilitaryBuilding"] = 0.4,
}
-- 
AiArmyTargetPriority.LongRange = {
    ["Hero"] = 1.0,
    ["CavalryHeavy"] = 0.9,
    ["CavalryLight"] = 0.7,
    ["Spear"] = 0.6,
}
-- 
AiArmyTargetPriority.Rifle = {
    ["MilitaryBuilding"] = 1.0,
    ["EvilLeader"] = 1.0,
    ["LongRange"] = 0.8,
}
-- 
AiArmyTargetPriority.Cannon = {
    ["MilitaryBuilding"] = 1.0,
    ["EvilLeader"] = 1.0,
    ["LongRange"] = 0.7,
}

