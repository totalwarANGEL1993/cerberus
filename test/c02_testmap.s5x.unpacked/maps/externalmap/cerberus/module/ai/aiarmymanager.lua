Lib.Require("comfort/AreEnemiesInArea");
Lib.Require("comfort/CopyTable");
Lib.Require("comfort/GetDistance");
Lib.Require("comfort/IsInTable");
Lib.Require("module/trigger/Job");
Lib.Require("module/ai/AiArmy");
Lib.Require("module/ai/AiTroopSpawner");
Lib.Register("module/ai/AiArmyManager");

---
--- Army manager script
---
--- A manager can handle offensive and defensive campaigns of an army.
--- * Offensive: Attacks target positions if enemies are there
--- * Defensive: Patrols over targets and guards them
---
--- Attacking always has the priority over defending. When a manager has targets
--- and there are enemies present it will send out it's army.
---
--- Synchronizing two or more manager with another means that they will know
--- which targets the other managers attack or guard and will consider this
--- for it's own decision making.
---
--- @author totalwarANGEL
--- @version 1.0.0
---

AiArmyManager = AiArmyManager or {
    Campaign = {
        ATTACK = 1,
        DEFEND = 2,
    }
};

AiArmyManagerData_ManagerIdToManagerInstance = {};

-- -------------------------------------------------------------------------- --
-- API

--- Creates a manager for the army.
--- @param _ArmyID integer ID of army
--- @return integer ManagerID ID of manager
function AiArmyManager.Create(_ArmyID)
    return AiArmyManager.Internal:CreateManager {ArmyID = _ArmyID};
end

--- Deletes a manager.
--- @param _ID any ID of manager
function AiArmyManager.Delete(_ID)
    AiArmyManager.Internal:DeleteManager(_ID);
end

--- Synchronizes all the passed managers to each other.
--- @param ... integer List of managers
function AiArmyManager.Synchronize(...)
    for i= 1, table.getn(arg) do
        for j= 1, table.getn(arg) do
            if arg[i] ~= arg[j] then
                AiArmyManager.Internal:Synchronize(arg[i], arg[j]);
            end
        end
    end
end

--- Lifts the synchronization of the passed managers to another.
--- @param ... integer List of managers
function AiArmyManager.Desynchronize(...)
    for i= 1, table.getn(arg) do
        for j= 1, table.getn(arg) do
            if arg[i] ~= arg[j] then
                AiArmyManager.Internal:Desynchronize(arg[i], arg[j]);
            end
        end
    end
end

--- Sets the time eath guard position is guarded.
--- @param _ID integer ID of manager
--- @param _Time integer Time to guard
function AiArmyManager.SetGuardTime(_ID, _Time)
    AiArmyManager.Internal:SetGuardTime(_ID, _Time);
end

--- Adds an attack target to the manager.
--- @param _ID integer ID of manager
--- @param _Target string Target script entity
function AiArmyManager.AddAttackTarget(_ID, _Target)
    AiArmyManager.Internal:AddAttackTarget(_ID, _Target);
end

--- Adds a attacking path to the manager.
---
--- The last element of the path becomes the attack target. Enemies are
--- searched there and it is used for comparisons between the targets.
--- @param _ID integer ID of manager
--- @param ... table Waypoint list
function AiArmyManager.AddAttackTargetPath(_ID, ...)
    AiArmyManager.Internal:AddAttackTarget(_ID, arg);
end

--- Removes an attack target from the manager.
--- @param _ID integer ID of manager
--- @param _Target string Target script entity
function AiArmyManager.RemoveAttackTarget(_ID, _Target)
    AiArmyManager.Internal:RemoveAttackTarget(_ID, _Target);
end

--- Adds a guard position to the manager.
--- @param _ID integer ID of manager
--- @param _Target string Target script entity
function AiArmyManager.AddGuardPosition(_ID, _Target)
    AiArmyManager.Internal:AddGuardPosition(_ID, _Target);
end

--- Removes a guard position from the manager.
--- @param _ID integer ID of manager
--- @param _Target any Target script entity
function AiArmyManager.RemoveGuardPosition(_ID, _Target)
    AiArmyManager.Internal:RemoveGuardPosition(_ID, _Target);
end

-- -------------------------------------------------------------------------- --
-- Internal

AiArmyManager.Internal = AiArmyManager.Internal or {
    Data = {
        ManagersIdSequence = 0,
        Managers = {},
    },
}

function AiArmyManager.Internal:Install()
    if not self.IsInstalled then
        self.IsInstalled = true;

        self.ControllerJobID = Job.Second(function()
            for i= table.getn(self.Data.Managers), 1, -1 do
                self:ControllManagers(i);
            end
        end);
    end
end

function AiArmyManager.Internal:CreateManager(_Data)
    self:Install();
    self.Data.ManagersIdSequence = self.Data.ManagersIdSequence +1;
    local ID = self.Data.ManagersIdSequence;

    local Manager = {
        ID             = ID,
        ArmyID         = _Data.ArmyID,
        GuardTime      = _Data.GuardTime or (3*60),
        Campaign       = {},
        Synchronized   = {},
        AttackTargets  = _Data.AttackTargets or {},
        GuardPositions = _Data.GuardPositions or {},
    };
    table.insert(self.Data.Managers, Manager);
    AiArmyManagerData_ManagerIdToManagerInstance[ID] = Manager;
    return ID;
end

function AiArmyManager.Internal:DeleteManager(_ID)
    -- Desyncronize all
    for i= table.getn(self.Data.Managers), 1, -1 do
        if self.Data.Managers[i].ID ~= _ID then
            self:Desynchronize(self.Data.Managers[i].ID, _ID);
        end
    end
    -- Delete manager
    for i= table.getn(self.Data.Managers), 1, -1 do
        if self.Data.Managers[i].ID == _ID then
            table.remove(self.Data.Managers, i);
        end
    end
    AiArmyManagerData_ManagerIdToManagerInstance[ID] = nil;
end

-- -------------------------------------------------------------------------- --

function AiArmyManager.Internal:ControllManagers(_Index)
    local Data = self.Data.Managers[_Index];
    if Data then
        local Army = AiArmy.Get(Data.ArmyID);
        if not Army then
            return;
        end

        -- Control attack campaign
        if Data.Campaign.Type == AiArmyManager.Campaign.ATTACK then
            -- Check army defeated
            if Army.Behavior == AiArmy.Behavior.FALLBACK then
                self:EndCampaign(Data.ID);
                return;
            end
            -- Control movement
            if Data.Campaign.Target.Index < table.getn(Data.Campaign.Target) then
                local CurrentData = Data.Campaign.Target;
                if GetDistance(CurrentData[CurrentData.Index], Army:GetArmyPosition()) < 1000 then
                    self.Data.Managers[_Index].Campaign.Target.Index = Data.Campaign.Target.Index + 1;
                    AiArmy.Advance(Data.ArmyID, GetPosition(CurrentData[CurrentData.Index]));
                    return;
                end
            end
            -- Check enemies defeated
            local Target = Data.Campaign.Target[table.getn(Data.Campaign.Target)];
            local Enemies = AiArmy.GetEnemies(Data.ArmyID, GetPosition(Target));
            if not Enemies[1] then
                self:EndCampaign(Data.ID);
                AiArmy.Retreat(Data.ArmyID);
                return;
            end

        -- Control guard campaign
        elseif Data.Campaign.Type == AiArmyManager.Campaign.DEFEND then
            -- Check army defeated
            if Army.Behavior == AiArmy.Behavior.FALLBACK then
                self:EndCampaign(Data.ID);
                return;
            end
            -- Tick down guard time
            if Army.Behavior ~= AiArmy.Behavior.BATTLE then
                self.Data.Managers[_Index].Campaign.Time = Data.Campaign.Time -1;
                if Data.Campaign.Time == 0 then
                    self:EndCampaign(Data.ID);
                    AiArmy.Retreat(Data.ArmyID);
                    return;
                end
            end

        -- Assign new campaign
        else
            if Army.Behavior == AiArmy.Behavior.WAITING then
                -- Get attack target
                local AttackTarget = self:GetUnattendedAttackTarget(Data.ID, AiArmyManager.Campaign.ATTACK);
                if AttackTarget ~= nil then
                    self:BeginOffensiveCampaign(Data.ID, AttackTarget);
                    AiArmy.Advance(Data.ArmyID, GetPosition(AttackTarget[AttackTarget.Index]));
                    return;
                end
                -- Get guard target
                local GuardTarget = self:GetUnattendedDefendTarget(Data.ID, AiArmyManager.Campaign.DEFEND);
                if GuardTarget ~= nil then
                    self:BeginDefensiveCampaign(Data.ID, GuardTarget, Data.GuardTime);
                    AiArmy.Advance(Data.ArmyID, GetPosition(GuardTarget));
                else
                    self:BeginDefensiveCampaign(Data.ID, Army.HomePosition, Data.GuardTime);
                    AiArmy.Advance(Data.ArmyID, Army.HomePosition);
                end
            end
        end
    end
end

function AiArmyManager.Internal:GetUnattendedAttackTarget(_ID, _CampaignType)
    assert(AiArmyManagerData_ManagerIdToManagerInstance[_ID]);
    local Data = AiArmyManagerData_ManagerIdToManagerInstance[_ID];
    if Data and Data.Campaign.Type == nil and table.getn(Data.AttackTargets) > 0 then
        local Targets = CopyTable(Data.AttackTargets);
        -- If only 1 is defined, return it immedaitly
        if table.getn(Targets) == 1 then
            return Targets[1];
        end

        -- Remove targets processed by synchronized armies
        for i= table.getn(Data.Synchronized), 1, -1 do
            local Other = AiArmyManagerData_ManagerIdToManagerInstance[Data.Synchronized[i]];
            if Other then
                for j= table.getn(Targets), 1, -1 do
                    local OtherTargets = Other.Campaign.Target;
                    if  Other.Campaign.Type == _CampaignType
                    and OtherTargets[table.getn(OtherTargets)] == Targets[j][table.getn(Targets[j])] then
                        table.remove(Targets, j);
                    end
                end
            end
        end

        -- Get target
        if table.getn(Targets) >= 0 then
            for i= table.getn(Targets), 1, -1 do
                local Enemies = AiArmy.GetEnemies(Data.ArmyID, GetPosition(Targets[i][table.getn(Targets[i])]));
                if Enemies[1] then
                    Targets[i].Index = 1;
                    return Targets[i];
                end
            end
        end
    end
end

function AiArmyManager.Internal:GetUnattendedDefendTarget(_ID, _CampaignType)
    assert(AiArmyManagerData_ManagerIdToManagerInstance[_ID]);
    local Data = AiArmyManagerData_ManagerIdToManagerInstance[_ID];
    if Data and Data.Campaign.Type == nil and table.getn(Data.GuardPositions) > 0 then
        local Targets = CopyTable(Data.GuardPositions);
        -- If only 1 is defined, return it immedaitly
        if table.getn(Targets) == 1 then
            return Targets[1];
        end

        -- Remove targets processed by synchronized armies
        local ExtraDataAmount = 0;
        local ExtraData = {};
        for i= table.getn(Data.Synchronized), 1, -1 do
            local Other = AiArmyManagerData_ManagerIdToManagerInstance[Data.Synchronized[i]];
            if Other then
                for j= table.getn(Targets), 1, -1 do
                    if  Other.Campaign.Type == _CampaignType
                    and Other.Campaign.Target == Targets[j] then
                        ExtraDataAmount = ExtraDataAmount +1;
                        ExtraData[Targets[j]] = {Data.Synchronized[i], Other.Campaign.Target, Other.Campaign.Time};
                        table.remove(Targets, j);
                    end
                end
            end
        end

        -- Return random target if available
        if table.getn(Targets) > 0 then
            local Random = math.random(1, table.getn(Targets));
            return Targets[Random];
        end

        -- Find target with smallest guard time remaining
        Targets = CopyTable(Data.GuardPositions);
        for i= table.getn(Targets), 1, -1 do
            if Data.LastGuardTarget == Targets[i] then
                table.remove(Targets[i]);
            end
        end
        if ExtraDataAmount > 0 and table.getn(Targets) > 1 then
            table.sort(Targets, function(a, b)
                a = (ExtraData[a] and ExtraData[a][3]) or 999999999;
                b = (ExtraData[b] and ExtraData[b][3]) or 999999999;
                return a < b;
            end);
        end
        return Targets[1];
    end
end

-- -------------------------------------------------------------------------- --

function AiArmyManager.Internal:SetArmyID(_ID, _ArmyID)
    if AiArmyManagerData_ManagerIdToManagerInstance[_ID] then
        AiArmyManagerData_ManagerIdToManagerInstance[_ID].ArmyID = _ArmyID;
    end
end

function AiArmyManager.Internal:AddAttackTarget(_ID, _Target)
    if AiArmyManagerData_ManagerIdToManagerInstance[_ID] then
        local Target = (type(_Target) ~= "table" and {_Target}) or _Target;
        if not self:IsInTargetTable(Target, AiArmyManagerData_ManagerIdToManagerInstance[_ID].AttackTargets) then
            table.insert(AiArmyManagerData_ManagerIdToManagerInstance[_ID].AttackTargets, Target);
        end
    end
end

function AiArmyManager.Internal:RemoveAttackTarget(_ID, _Target)
    if AiArmyManagerData_ManagerIdToManagerInstance[_ID] then
        local Target = (type(_Target) ~= "table" and {_Target}) or _Target;
        for i= table.getn(AiArmyManagerData_ManagerIdToManagerInstance[_ID].AttackTargets), 1, -1 do
            local SelfTarget = AiArmyManagerData_ManagerIdToManagerInstance[_ID].AttackTargets[i];
            if SelfTarget[table.getn(SelfTarget)] == Target[table.getn(Target)] then
                table.remove(AiArmyManagerData_ManagerIdToManagerInstance[_ID].AttackTargets, i);
            end
        end
    end
end

function AiArmyManager.Internal:AddGuardPosition(_ID, _Target)
    if AiArmyManagerData_ManagerIdToManagerInstance[_ID] then
        if not IsInTable(_Target, AiArmyManagerData_ManagerIdToManagerInstance[_ID].GuardPositions) then
            table.insert(AiArmyManagerData_ManagerIdToManagerInstance[_ID].GuardPositions, _Target);
        end
    end
end

function AiArmyManager.Internal:RemoveGuardPosition(_ID, _Target)
    if AiArmyManagerData_ManagerIdToManagerInstance[_ID] then
        for i= table.getn(AiArmyManagerData_ManagerIdToManagerInstance[_ID].GuardPositions), 1, -1 do
            if AiArmyManagerData_ManagerIdToManagerInstance[_ID].GuardPositions[i] == _Target then
                table.remove(AiArmyManagerData_ManagerIdToManagerInstance[_ID].GuardPositions, i);
            end
        end
    end
end

function AiArmyManager.Internal:IsInTargetTable(_Target, _Table)
    for i= 1, table.getn(_Table) do
        if _Target == _Table[i][table.getn(_Table[i])] then
            return true;
        end
    end
    return false;
end

function AiArmyManager.Internal:SetGuardTime(_ID, _Time)
    if AiArmyManagerData_ManagerIdToManagerInstance[_ID] then
        AiArmyManagerData_ManagerIdToManagerInstance[_ID].GuartTime = _Time;
    end
end

function AiArmyManager.Internal:BeginOffensiveCampaign(_ID, _Target)
    assert(AiArmyManagerData_ManagerIdToManagerInstance[_ID]);
    -- Delete target memory
    AiArmyManagerData_ManagerIdToManagerInstance[_ID].LastAttackTarget = nil;
    -- Save campaign data
    AiArmyManagerData_ManagerIdToManagerInstance[_ID].Campaign = {
        Type = AiArmyManager.Campaign.ATTACK,
        Target = _Target,
        Time = -1,
    };
end

function AiArmyManager.Internal:BeginDefensiveCampaign(_ID, _Target, _Time)
    assert(AiArmyManagerData_ManagerIdToManagerInstance[_ID]);
    -- Delete target memory
    AiArmyManagerData_ManagerIdToManagerInstance[_ID].LastGuardTarget = nil;
    -- Save campaign data
    AiArmyManagerData_ManagerIdToManagerInstance[_ID].Campaign = {
        Type = AiArmyManager.Campaign.DEFEND,
        Target = _Target,
        Time = _Time,
    };
end

function AiArmyManager.Internal:EndCampaign(_ID)
    local Data = AiArmyManagerData_ManagerIdToManagerInstance[_ID];
    assert(Data);
    self:DispatchTroopsToSpawner(_ID);
    -- Save last position
    if Data.Campaign.Type == AiArmyManager.Campaign.Attack then
        local Target = Data.Campaign.Target[table.getn(Data.Campaign.Target)];
        AiArmyManagerData_ManagerIdToManagerInstance[_ID].LastAttackTarget = Target;
    end
    if Data.Campaign.Type == AiArmyManager.Campaign.DEFEND then
        AiArmyManagerData_ManagerIdToManagerInstance[_ID].LastGuardTarget = Data.Campaign.Target;
    end
    -- Create idle campaign
    AiArmyManagerData_ManagerIdToManagerInstance[_ID].Campaign = {
        Type = AiArmyManager.Campaign.IDLE,
        Target = 0,
        Time = -1,
    };
end

function AiArmyManager.Internal:Synchronize(_ID1, _ID2)
    assert(AiArmyManagerData_ManagerIdToManagerInstance[_ID1]);
    assert(AiArmyManagerData_ManagerIdToManagerInstance[_ID2]);

    if not IsInTable(_ID2, AiArmyManagerData_ManagerIdToManagerInstance[_ID1].Synchronized) then
        table.insert(AiArmyManagerData_ManagerIdToManagerInstance[_ID1].Synchronized, _ID2);
    end
    if not IsInTable(_ID1, AiArmyManagerData_ManagerIdToManagerInstance[_ID2].Synchronized) then
        table.insert(AiArmyManagerData_ManagerIdToManagerInstance[_ID2].Synchronized, _ID1);
    end
end

function AiArmyManager.Internal:Desynchronize(_ID1, _ID2)
    assert(AiArmyManagerData_ManagerIdToManagerInstance[_ID1]);
    assert(AiArmyManagerData_ManagerIdToManagerInstance[_ID2]);

    for i= table.getn(AiArmyManagerData_ManagerIdToManagerInstance[_ID1].Synchronized), 1, -1 do
        if AiArmyManagerData_ManagerIdToManagerInstance[_ID1].Synchronized[i] == _ID2 then
            table.remove(AiArmyManagerData_ManagerIdToManagerInstance[_ID1].Synchronized, i);
        end
    end
    for i= table.getn(AiArmyManagerData_ManagerIdToManagerInstance[_ID2].Synchronized), 1, -1 do
        if AiArmyManagerData_ManagerIdToManagerInstance[_ID2].Synchronized[i] == _ID1 then
            table.remove(AiArmyManagerData_ManagerIdToManagerInstance[_ID2].Synchronized, i);
        end
    end
end

function AiArmyManager.Internal:DispatchTroopsToSpawner(_ID)
    assert(AiArmyManagerData_ManagerIdToManagerInstance[_ID]);

    local ArmyID = AiArmyManagerData_ManagerIdToManagerInstance[_ID].ArmyID;
    local SpawnerIDs = AiTroopSpawner.GetSpawnersOfArmy(ArmyID);
    local Weakened = AiArmy.GetWeakenedTroops(ArmyID);
    for i= table.getn(Weakened), 1, -1 do
        local Success = false;
        for j= 1, table.getn(SpawnerIDs) do
            Success = AiTroopSpawner.AddTroop(SpawnerIDs[j], Weakened[i]);
            if Success == true then
                AiArmy.RemoveTroop(ArmyID, Weakened[i]);
                break;
            end
        end
    end
end

