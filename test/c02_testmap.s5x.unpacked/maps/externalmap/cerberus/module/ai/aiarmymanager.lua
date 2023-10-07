Lib.Require("comfort/AreEnemiesInArea");
Lib.Require("comfort/CopyTable");
Lib.Require("comfort/GetDistance");
Lib.Require("comfort/IsInTable");
Lib.Require("module/trigger/Job");
Lib.Require("module/ai/AiArmy");
Lib.Require("module/ai/AiArmyRefiller");
Lib.Register("module/ai/AiArmyManager");

---
--- Army manager script
---
--- Managers are pre-made controller scripts for armies that implement basic
--- behaviors in a "campaign". A manager can handle offensive and defensive
--- campaigns of the attached army.
---
--- * Offensive: Attacks target positions if enemies are there
--- * Defensive: Patrols over targets and guards them
---
--- Attacking always has the priority over defending. When a manager has targets
--- and there are enemies present it will send out it's army.
---
--- A manager can only control one army but managers can be synchronized.
--- Synchronizing two or more manager with another means that they will know
--- which targets the other managers attack or guard and this will have an
--- influence on selecting targets.
---
--- * Offensive: Targets won't be selected twice. Synchronized armies will
---   attack one target each if provided (or guard position if not).
--- * Defensive: If an army is guarding a position and is attacked all other
---   synchronized armies that are guarding and not fighting will assist.
---
--- A manager runs each second. All managers are scheduled so that each turn
--- of a second is used to run a subset of the managers. Still, each manager
--- is run only once per second.
---
--- Version 1.3.0
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
--- @param _ArmyID integer  ID of army
--- @return integer ManagerID ID of manager
function AiArmyManager.Create(_ArmyID)
    return AiArmyManager.Internal:CreateManager {ArmyID = _ArmyID};
end

--- Creates a custom manager for the army.
---
--- The manager is not bound to the default behavior and can be programmed
--- freely. The action receives the ID of the manager and the ID of the army
--- that is controlled by the manager.
--- @param _ArmyID integer  ID of army
--- @param _Action function Custom army controller
--- @return integer ManagerID ID of manager
function AiArmyManager.CreateCustom(_ArmyID, _Action)
    return AiArmyManager.Internal:CreateManager {
        ArmyID = _ArmyID,
        Action = _Action,
    };
end

--- Deletes a manager.
--- @param _ID integer ID of manager
function AiArmyManager.Delete(_ID)
    AiArmyManager.Internal:DeleteManager(_ID);
end

--- Returns the army managed by the manager
--- @return integer ID ID of army
function AiArmyManager.GetArmy(_ID)
    if AiArmyManagerData_ManagerIdToManagerInstance[_ID] then
        return AiArmyManagerData_ManagerIdToManagerInstance[_ID]:GetArmy(_ID);
    end
    return 0;
end

--- Removes all associations from the manager.
--- @param _ID integer ID of manager
function AiArmyManager.PurgeSynchronization(_ID)
    AiArmyManager.Internal:PurgeSynchronization(_ID);
end

--- Synchronizes the attacks of all passed manager IDs.
--- @param ... integer List of managers
function AiArmyManager.SynchronizeOffence(...)
    for i= 1, table.getn(arg) do
        for j= 1, table.getn(arg) do
            if arg[i] ~= arg[j] then
                AiArmyManager.Internal:SynchronizeOffence(arg[i], arg[j]);
            end
        end
    end
end

--- Lifts the synchronization of attacks for the passed manager IDs.
--- @param ... integer List of managers
function AiArmyManager.DesynchronizeOffence(...)
    for i= 1, table.getn(arg) do
        for j= 1, table.getn(arg) do
            if arg[i] ~= arg[j] then
                AiArmyManager.Internal:DesynchronizeOffence(arg[i], arg[j]);
            end
        end
    end
end

--- Synchronizes the defence of all passed manager IDs.
--- @param ... integer List of managers
function AiArmyManager.SynchronizeDefence(...)
    for i= 1, table.getn(arg) do
        for j= 1, table.getn(arg) do
            if arg[i] ~= arg[j] then
                AiArmyManager.Internal:SynchronizeDefence(arg[i], arg[j]);
            end
        end
    end
end

--- Lifts the synchronization of defence for the passed manager IDs.
--- @param ... integer List of managers
function AiArmyManager.DesynchronizeDefence(...)
    for i= 1, table.getn(arg) do
        for j= 1, table.getn(arg) do
            if arg[i] ~= arg[j] then
                AiArmyManager.Internal:DesynchronizeDefence(arg[i], arg[j]);
            end
        end
    end
end

--- Synchronizes offence and defence of all passed manager IDs.
--- @param ... integer List of managers
function AiArmyManager.Synchronize(...)
    --- @diagnostic disable-next-line: param-type-mismatch
    AiArmyManager.SynchronizeOffence(unpack(arg));
    --- @diagnostic disable-next-line: param-type-mismatch
    AiArmyManager.SynchronizeDefence(unpack(arg));
end

--- Lifts offence and defence synchronization of all passed manager IDs.
--- @param ... integer List of managers
function AiArmyManager.Desynchronize(...)
    --- @diagnostic disable-next-line: param-type-mismatch
    AiArmyManager.DesynchronizeOffence(unpack(arg));
    --- @diagnostic disable-next-line: param-type-mismatch
    AiArmyManager.DesynchronizeDefence(unpack(arg));
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

--- Forbid the manager to send it's army to attack
--- @param _ID integer ID of manager
--- @param _Flag boolean Attacking is forbidden
function AiArmyManager.ForbidAttacking(_ID, _Flag)
    AiArmyManager.Internal:ForbidAttacking(_ID, _Flag);
end

--- Forbid the manager to send it's army to guard duty.
--- @param _ID integer ID of manager
--- @param _Flag boolean Defending is forbidden
function AiArmyManager.ForbidDefending(_ID, _Flag)
    AiArmyManager.Internal:ForbidDefending(_ID, _Flag);
end

--- Stops the current cempaign of the manager.
--- @param _ID integer ID of manager
function AiArmyManager.EndCampaign(_ID)
    AiArmyManager.Internal:EndCampaign(_ID);
end

--- Changes the player of the manager and it's army.
---
--- All synchronizations are cancelled automatically.
--- @param _ID integer ID of manager
--- @param _PlayerID integer New owner
function AiArmyManager.ChangePlayer(_ID, _PlayerID)
    AiArmyManager.Internal:ChangePlayer(_ID, _PlayerID);
end

--- Obtains the custom data of the manager.
--- @param _ID integer ID of manager
--- @return table Data Data of manager
function AiArmyManager.GetCustomData(_ID)
    return AiArmyManagerData_ManagerIdToManagerInstance[_ID].Data;
end

--- Updates the custom data of the manager.
--- @param _ID integer ID of manager
--- @param _Data table Data of manager
function AiArmyManager.SetCustomData(_ID, _Data)
    AiArmyManagerData_ManagerIdToManagerInstance[_ID].Data = _Data or {};
end

--- Removes all weakened troops from the army and attaches them to refillers.
--- Then the IDs of the troops are returned.
--- 
--- If there are no refillers add to an army the troops are just removed from
--- the army and returned.
--- @param _ID integer ID of manager
--- @return table Troops List of troops
function AiArmyManager.DispatchTroopsToRefiller(_ID)
    return AiArmyManager.Internal:DispatchTroopsToSpawner(_ID);
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

        self.ControllerJobID = Job.Turn(function()
            for i= table.getn(self.Data.Managers), 1, -1 do
                --- @diagnostic disable-next-line: undefined-field
                if math.mod(Logic.GetCurrentTurn(), 10) == self.Data.Managers[i].Tick then
                    self:ControllManager(i);
                end
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
        --- @diagnostic disable-next-line: undefined-field
        Tick           = math.mod(ID, 10);
        Data           = {},
        Action         = _Data.Action,
        ArmyID         = _Data.ArmyID,
        GuardTime      = _Data.GuardTime or (3*60),
        Campaign       = {},
        SyncOffence    = {},
        SyncDefence    = {},
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

function AiArmyManager.Internal:ChangePlayer(_ID, _PlayerID)
    assert(AiArmyManagerData_ManagerIdToManagerInstance[_ID]);
    AiArmy.ChangePlayer(AiArmyManagerData_ManagerIdToManagerInstance[_ID].ArmyID, _PlayerID);
    self:PurgeSynchronization(_ID);
end

-- -------------------------------------------------------------------------- --

function AiArmyManager.Internal:ControllManager(_Index)
    local Data = self.Data.Managers[_Index];
    if Data and AiArmy.IsExisting(Data.ArmyID) then
        if Data.Action then
            Data.Action(Data.ID, Data.ArmyID);
        else
            -- Control attack campaign
            if Data.Campaign.Type == AiArmyManager.Campaign.ATTACK then
                -- Check army defeated
                if AiArmy.GetBehavior(Data.ArmyID) == AiArmy.Behavior.FALLBACK then
                    self:EndCampaign(Data.ID);
                    return;
                end
                -- Control movement
                if Data.Campaign.Target.Index < table.getn(Data.Campaign.Target) then
                    local CurrentData = Data.Campaign.Target;
                    if GetDistance(CurrentData[CurrentData.Index], AiArmy.GetLocation(Data.ArmyID)) < 1000 then
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
                if AiArmy.GetBehavior(Data.ArmyID) == AiArmy.Behavior.FALLBACK then
                    self:EndCampaign(Data.ID);
                    return;
                end
                -- Tick down guard time
                if  AiArmy.GetBehavior(Data.ArmyID) ~= AiArmy.Behavior.BATTLE
                and AiArmy.GetBehavior(Data.ArmyID) ~= AiArmy.Behavior.ADVANCE then
                    self.Data.Managers[_Index].Campaign.Time = Data.Campaign.Time -1;
                    if Data.Campaign.Time == 0 then
                        self:EndCampaign(Data.ID);
                        AiArmy.Retreat(Data.ArmyID);
                        return;
                    end
                end
                -- Help synchronized
                if AiArmy.GetBehavior(Data.ArmyID) == AiArmy.Behavior.WAITING then
                    for i= table.getn(Data.SyncDefence), 1, -1 do
                        local Manager = AiArmyManagerData_ManagerIdToManagerInstance[Data.SyncDefence[i]];
                        if Manager.Campaign and Manager.Campaign.Type == AiArmyManager.Campaign.DEFEND then
                            if AiArmy.GetBehavior(Manager.ArmyID) == AiArmy.Behavior.BATTLE then
                                --- @diagnostic disable-next-line: param-type-mismatch
                                AiArmy.Advance(Data.ArmyID, AiArmy.GetLocation(Manager.ArmyID));
                                return;
                            end
                        end
                    end
                    if GetDistance(AiArmy.GetLocation(Data.ArmyID), Data.Campaign.Target) > 1000 then
                        AiArmy.Advance(Data.ArmyID, GetPosition(Data.Campaign.Target));
                    end
                end

            -- Assign new campaign
            else
                if AiArmy.GetBehavior(Data.ArmyID) == AiArmy.Behavior.WAITING then
                    -- Get attack target
                    if not Data.ForbidAttack then
                        local AttackTarget = self:GetUnattendedAttackTarget(Data.ID, AiArmyManager.Campaign.ATTACK);
                        if AttackTarget ~= nil then
                            self:BeginOffensiveCampaign(Data.ID, AttackTarget);
                            AiArmy.Advance(Data.ArmyID, GetPosition(AttackTarget[AttackTarget.Index]));
                            return;
                        end
                    end
                    -- Get guard target
                    if not Data.ForbidDefend then
                        local GuardTarget = self:GetUnattendedDefendTarget(Data.ID, AiArmyManager.Campaign.DEFEND);
                        if GuardTarget ~= nil then
                            self:BeginDefensiveCampaign(Data.ID, GuardTarget, Data.GuardTime);
                            AiArmy.Advance(Data.ArmyID, GetPosition(GuardTarget));
                        else
                            self:BeginDefensiveCampaign(Data.ID, AiArmy.GetHomePosition(Data.ArmyID), Data.GuardTime);
                            --- @diagnostic disable-next-line: param-type-mismatch
                            AiArmy.Advance(Data.ArmyID, AiArmy.GetHomePosition(Data.ArmyID));
                        end
                    end
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
            Targets[1].Index = 1;
            return Targets[1];
        end

        -- Remove targets processed by synchronized armies
        for i= table.getn(Data.SyncOffence), 1, -1 do
            local Other = AiArmyManagerData_ManagerIdToManagerInstance[Data.SyncOffence[i]];
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
        for i= table.getn(Data.SyncDefence), 1, -1 do
            local Other = AiArmyManagerData_ManagerIdToManagerInstance[Data.SyncDefence[i]];
            if Other then
                for j= table.getn(Targets), 1, -1 do
                    if  Other.Campaign.Type == _CampaignType
                    and Other.Campaign.Target == Targets[j] then
                        ExtraDataAmount = ExtraDataAmount +1;
                        ExtraData[Targets[j]] = {Data.SyncDefence[i], Other.Campaign.Target, Other.Campaign.Time};
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
                table.remove(Targets, i);
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

function AiArmyManager.Internal:ForbidAttacking(_ID, _Flag)
    if AiArmyManagerData_ManagerIdToManagerInstance[_ID] then
        AiArmyManagerData_ManagerIdToManagerInstance[_ID].ForbidAttack = _Flag == true;
    end
end

function AiArmyManager.Internal:ForbidDefending(_ID, _Flag)
    if AiArmyManagerData_ManagerIdToManagerInstance[_ID] then
        AiArmyManagerData_ManagerIdToManagerInstance[_ID].ForbidDefend = _Flag == true;
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

function AiArmyManager.Internal:PurgeSynchronization(_ID)
    assert(AiArmyManagerData_ManagerIdToManagerInstance[_ID]);

    for k,v in pairs(AiArmyManagerData_ManagerIdToManagerInstance[_ID].SyncOffence) do
        self:DesynchronizeOffence(_ID, v);
    end
    for k,v in pairs(AiArmyManagerData_ManagerIdToManagerInstance[_ID].SyncDefence) do
        self:DesynchronizeDefence(_ID, v);
    end
end

function AiArmyManager.Internal:SynchronizeOffence(_ID1, _ID2)
    assert(AiArmyManagerData_ManagerIdToManagerInstance[_ID1]);
    assert(AiArmyManagerData_ManagerIdToManagerInstance[_ID2]);

    if not IsInTable(_ID2, AiArmyManagerData_ManagerIdToManagerInstance[_ID1].SyncOffence) then
        table.insert(AiArmyManagerData_ManagerIdToManagerInstance[_ID1].SyncOffence, _ID2);
    end
    if not IsInTable(_ID1, AiArmyManagerData_ManagerIdToManagerInstance[_ID2].SyncOffence) then
        table.insert(AiArmyManagerData_ManagerIdToManagerInstance[_ID2].SyncOffence, _ID1);
    end
end

function AiArmyManager.Internal:DesynchronizeOffence(_ID1, _ID2)
    assert(AiArmyManagerData_ManagerIdToManagerInstance[_ID1]);
    assert(AiArmyManagerData_ManagerIdToManagerInstance[_ID2]);

    for i= table.getn(AiArmyManagerData_ManagerIdToManagerInstance[_ID1].SyncOffence), 1, -1 do
        if AiArmyManagerData_ManagerIdToManagerInstance[_ID1].SyncOffence[i] == _ID2 then
            table.remove(AiArmyManagerData_ManagerIdToManagerInstance[_ID1].SyncOffence, i);
        end
    end
    for i= table.getn(AiArmyManagerData_ManagerIdToManagerInstance[_ID2].SyncOffence), 1, -1 do
        if AiArmyManagerData_ManagerIdToManagerInstance[_ID2].SyncOffence[i] == _ID1 then
            table.remove(AiArmyManagerData_ManagerIdToManagerInstance[_ID2].SyncOffence, i);
        end
    end
end

function AiArmyManager.Internal:SynchronizeDefence(_ID1, _ID2)
    assert(AiArmyManagerData_ManagerIdToManagerInstance[_ID1]);
    assert(AiArmyManagerData_ManagerIdToManagerInstance[_ID2]);

    if not IsInTable(_ID2, AiArmyManagerData_ManagerIdToManagerInstance[_ID1].SyncDefence) then
        table.insert(AiArmyManagerData_ManagerIdToManagerInstance[_ID1].SyncDefence, _ID2);
    end
    if not IsInTable(_ID1, AiArmyManagerData_ManagerIdToManagerInstance[_ID2].SyncDefence) then
        table.insert(AiArmyManagerData_ManagerIdToManagerInstance[_ID2].SyncDefence, _ID1);
    end
end

function AiArmyManager.Internal:DesynchronizeDefence(_ID1, _ID2)
    assert(AiArmyManagerData_ManagerIdToManagerInstance[_ID1]);
    assert(AiArmyManagerData_ManagerIdToManagerInstance[_ID2]);

    for i= table.getn(AiArmyManagerData_ManagerIdToManagerInstance[_ID1].SyncDefence), 1, -1 do
        if AiArmyManagerData_ManagerIdToManagerInstance[_ID1].SyncDefence[i] == _ID2 then
            table.remove(AiArmyManagerData_ManagerIdToManagerInstance[_ID1].SyncDefence, i);
        end
    end
    for i= table.getn(AiArmyManagerData_ManagerIdToManagerInstance[_ID2].SyncDefence), 1, -1 do
        if AiArmyManagerData_ManagerIdToManagerInstance[_ID2].SyncDefence[i] == _ID1 then
            table.remove(AiArmyManagerData_ManagerIdToManagerInstance[_ID2].SyncDefence, i);
        end
    end
end

function AiArmyManager.Internal:DispatchTroopsToSpawner(_ID)
    assert(AiArmyManagerData_ManagerIdToManagerInstance[_ID]);

    local ArmyID = AiArmyManagerData_ManagerIdToManagerInstance[_ID].ArmyID;
    local RefillerIDs = AiArmyRefiller.GetRefillersOfArmy(ArmyID);
    local Weakened = AiArmy.GetWeakenedTroops(ArmyID);
    if table.getn(RefillerIDs) > 0 then
        for i= table.getn(Weakened), 1, -1 do
            -- Get possible refillers
            local PossibleRefillerIDs = {};
            for j= table.getn(RefillerIDs), 1, -1 do
                if AiArmyRefiller.CanTroopBeAdded(RefillerIDs[j], Weakened[i]) then
                    table.insert(PossibleRefillerIDs, RefillerIDs[j]);
                end
            end
            -- Distribute randomly
            local Success = false;
            local RefillerAmount = table.getn(PossibleRefillerIDs);
            if RefillerAmount > 0 then
                if RefillerAmount == 1 then
                    Success = AiArmyRefiller.AddTroop(PossibleRefillerIDs[1], Weakened[i]);
                    if Success == true then
                        AiArmy.RemoveTroop(ArmyID, Weakened[i]);
                    end
                else
                    local Index = math.random(1, RefillerAmount);
                    Success = AiArmyRefiller.AddTroop(PossibleRefillerIDs[Index], Weakened[i]);
                    if Success == true then
                        AiArmy.RemoveTroop(ArmyID, Weakened[i]);
                    end
                end
            end
        end
    else
        for i= table.getn(Weakened), 1, -1 do
            AiArmy.RemoveTroop(ArmyID, Weakened[i]);
        end
    end
    return Weakened;
end

