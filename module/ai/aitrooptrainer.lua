Lib.Require("comfort/AreEnemiesInArea");
Lib.Require("comfort/GetDistance");
Lib.Require("module/trigger/Job");
Lib.Require("module/ai/AiArmy");
Lib.Register("module/ai/AiTroopTrainer");

---
--- Troop recruiter script
---
--- Allows to define buildings as trainers. Trainers recruit troops for armies
--- attached to them.
---
--- Version ALPHA
---

AiTroopTrainer = AiTroopTrainer or {};

AiArmyTrainerData_TrainerIdToTrainerInstance = {};

-- -------------------------------------------------------------------------- --
-- API

--- Creates a new trainer.
---
--- Possible fields for definition:
--- * ScriptName   (Required) Scriptname of spawner
--- * SpawnPoint   (Optional) Scriptname of position
--- * AllowedTypes (Optional) List of upgrade categories
---
--- @param _Data table Troop Trainer definition
--- @return integer ID ID of trainer
function AiTroopTrainer.Create(_Data)
    return AiTroopTrainer.Internal:CreateTrainer(_Data);
end

--- Deletes a spawner.
--- @param _ID integer ID of spawner
function AiTroopTrainer.Delete(_ID)
    AiTroopTrainer.Internal:DeleteTrainer(_ID);
end

--- Returns the trainer ID by the entity.
--- @param _Entity any ID or Scriptname
--- @return integer ID ID of trainer
function AiTroopTrainer.Get(_Entity)
    return AiTroopTrainer.Internal:GetByEntity(_Entity);
end

--- Adds a new allowed type to the unit roster.
--- @param _ID integer   ID of spawner
--- @param _Type integer Upgrade category of Leader
--- @param _Exp integer?  Experience points (unused)
function AiTroopTrainer.AddAllowedType(_ID, _Type, _Exp)
    if AiArmyTrainerData_TrainerIdToTrainerInstance[_ID] then
        table.insert(AiArmyTrainerData_TrainerIdToTrainerInstance[_ID].AllowedTypes, {_Type, 0});
    end
end

--- Removes all allowed types from the unit roster.
--- @param _ID integer ID of spawner
function AiTroopTrainer.ClearAllowedTypes(_ID)
    if AiArmyTrainerData_TrainerIdToTrainerInstance[_ID] then
        AiArmyTrainerData_TrainerIdToTrainerInstance[_ID].AllowedTypes = {};
    end
end

--- Adds an army to the trainer.
--- @param _ID integer        ID of trainer
--- @param _ArmyID integer    ID of army
function AiTroopTrainer.AddArmy(_ID, _ArmyID)
    AiTroopTrainer.Internal:AddArmy(_ID, _ArmyID);
end

--- Removes an army from the trainer.
--- @param _ID integer     ID of trainer
--- @param _ArmyID integer ID of army
function AiTroopTrainer.RemoveArmy(_ID, _ArmyID)
    AiTroopTrainer.Internal:RemoveArmy(_ID, _ArmyID);
end

--- Adds a troop to be refilling list.
---
--- When a troop is added to the refiller list it gets new soldiers until it
--- is full. Refilled troops are prioritized before training new ones.
---
--- A troop can only be added to a trainer if it's type is supported, meaning
--- inside the list of types.
---
--- @param _ID integer      ID of spawner
--- @param _TroopID integer ID of troop
--- @return boolean Added Troop was added
function AiTroopTrainer.AddTroop(_ID, _TroopID)
    return AiTroopTrainer.Internal:AddTroop(_ID, _TroopID);
end

--- Checks if a troop can be added to a trainer.
--- @param _ID integer      ID of trainer
--- @param _TroopID integer ID of troop
--- @return boolean Addable Troop can be added
function AiTroopTrainer.CanTroopBeAdded(_ID, _TroopID)
    return AiTroopTrainer.Internal:CanTroopBeAdded(_ID, _TroopID);
end

--- Removes a troop from the refilling list.
--- @param _ID integer      ID of spawner
--- @param _TroopID integer ID of troop
function AiTroopTrainer.RemoveTroop(_ID, _TroopID)
    AiTroopTrainer.Internal:RemoveTroop(_ID, _TroopID);
end

--- All troops that are currently refilling are removed from the trainer.
--- @param _ID integer ID of trainer
--- @return table List of troops
function AiTroopTrainer.DraftTroops(_ID)
    local Troops = {};
    if AiArmyTrainerData_TrainerIdToTrainerInstance[_ID] then
        for i= table.getn(AiArmyTrainerData_TrainerIdToTrainerInstance[_ID].Refilling), 1, -1 do
            local ID = table.remove(AiArmyTrainerData_TrainerIdToTrainerInstance[_ID].Refilling, i);
            table.insert(Troops, ID);
        end
    end
    return Troops;
end

--- Returns all trainers the army is connected to.
--- @param _ArmyID integer ID of army
--- @return table IdList List of Spawner IDs
function AiTroopTrainer.GetTrainersOfArmy(_ArmyID)
    local SpawnerIDs = {};
    for i= 1, table.getn(AiTroopTrainer.Internal.Data.Trainers) do
        local Spawner = AiTroopTrainer.Internal.Data.Trainers[i];
        for j= 1, table.getn(Spawner.Armies) do
            if Spawner.Armies[j] == _ArmyID then
                table.insert(SpawnerIDs, Spawner.ID);
            end
        end
    end
    return SpawnerIDs;
end

--- Changes the owner of the trainer.
--- @param _ID integer ID of trainer
--- @param _PlayerID integer New owner
function AiTroopTrainer.ChangePlayer(_ID, _PlayerID)
    return AiTroopTrainer.Internal:ChangePlayer(_ID, _PlayerID);
end

-- -------------------------------------------------------------------------- --
-- Internal

AiTroopTrainer.Internal = AiTroopTrainer.Internal or {
    Data = {
        TrainerIdSequence = 0,
        Trainers = {},
    },
}

function AiTroopTrainer.Internal:Install()
    if not self.IsInstalled then
        self.IsInstalled = true;

        self.ControllerJobID = Job.Second(function()
            for i= table.getn(self.Data.Trainers), 1, -1 do
                self:ControllTrainer(i);
            end
        end);

        self.ControllerJobID = Job.Create(function()
            local EntityID = Event.GetEntityID();
            self:ControlTrainedUnits(EntityID);
        end);
    end
end

function AiTroopTrainer.Internal:CreateTrainer(_Data)
    self:Install();
    self.Data.TrainerIdSequence = self.Data.TrainerIdSequence +1;
    local ID = self.Data.TrainerIdSequence;

    assert(Logic.EntityGetPlayer(GetID(_Data.ScriptName)) > 0);

    local AllowedTypes = _Data.AllowedTypes or {};
    for i= 1, table.getn(AllowedTypes) do
        if type(AllowedTypes[i]) ~= "table" then
            AllowedTypes[i] = {AllowedTypes[i]};
        end
    end

    local Spawner = {
        ID           = ID,
        PlayerID     = _Data.PlayerID,
        ScriptName   = _Data.ScriptName,
        SpawnPoint   = _Data.SpawnPoint,
        AllowedTypes = AllowedTypes,
        Refilling    = {},
        Armies       = {},
    }
    if Spawner.SpawnPoint == nil then
        local Position = GetPosition(Spawner.ScriptName);
        local PlayerID = Logic.EntityGetPlayer(GetID(Spawner.ScriptName));
        PlayerID = (PlayerID == 0 and 8) or PlayerID;
        local EntityID  = AI.Entity_CreateFormation(PlayerID, Entities.PU_Serf, 0, 0, Position.X, Position.Y, 0, 0, 0, 0);
        Position = GetPosition(EntityID);
        DestroyEntity(EntityID);
        EntityID = Logic.CreateEntity(Entities.XD_ScriptEntity, Position.X, Position.Y, 0, PlayerID);
        Spawner.SpawnPoint = Spawner.ScriptName.. "Spawn";
        Logic.SetEntityName(EntityID, Spawner.SpawnPoint);
    end
    Spawner.AllowedTypes.Index = 0;
    table.insert(self.Data.Trainers, Spawner);
    AiArmyTrainerData_TrainerIdToTrainerInstance[ID] = Spawner;
    return ID;
end

function AiTroopTrainer.Internal:DeleteTrainer(_ID)
    for i= table.getn(self.Data.Trainers), 1, -1 do
        if self.Data.Trainers[i].ID == _ID then
            table.remove(self.Data.Trainers, i);
        end
    end
    AiArmyTrainerData_TrainerIdToTrainerInstance[_ID] = nil;
end

function AiTroopTrainer.Internal:GetByEntity(_Entity)
    local EntityID = GetID(_Entity);
    for i= table.getn(self.Data.Trainers), 1, -1 do
        if GetID(self.Data.Trainers[i].ScriptName) == EntityID then
            return self.Data.Trainers[i].ID;
        end
    end
    return 0;
end

function AiTroopTrainer.Internal:ChangePlayer(_ID, _PlayerID)
    if AiArmyTrainerData_TrainerIdToTrainerInstance[_ID] then
        local EntityID = GetID(AiArmyTrainerData_TrainerIdToTrainerInstance[_ID].ScriptName);
        -- Foundrys are replaced to abort cannon forging
        if InterfaceTool_IsBuildingDoingSomething(EntityID) == 1 then
            EntityID = ReplaceEntity(EntityID, Logic.GetEntityType(EntityID));
        end
        -- If leaders are training they are deleted
        local LeaderID = Logic.GetLeaderTrainingAtBuilding(EntityID);
        while (LeaderID ~= nil and LeaderID ~= 0) do
            DestroyEntity(LeaderID);
            LeaderID = Logic.GetLeaderTrainingAtBuilding(EntityID);
        end
        -- Change player of all refilling leaders
        local Refilling = {};
        for k,v in pairs(AiArmyTrainerData_TrainerIdToTrainerInstance[_ID].Refilling) do
            table.insert(Refilling, ChangePlayer(v, _PlayerID));
        end
        AiArmyTrainerData_TrainerIdToTrainerInstance[_ID].Refilling = Refilling;
        -- Finally change player of building
        ChangePlayer(AiArmyTrainerData_TrainerIdToTrainerInstance[_ID].ScriptName, _PlayerID);
        AiArmyTrainerData_TrainerIdToTrainerInstance[_ID].PlayerID = _PlayerID;
    end
end

function AiTroopTrainer.Internal:AddArmy(_ID, _ArmyID)
    local Trainer = AiArmyTrainerData_TrainerIdToTrainerInstance[_ID];
    local PlayerID = AiArmy.GetPlayer(_ArmyID);
    if Trainer and Trainer.PlayerID == PlayerID then
        self:RemoveArmy(_ID, _ArmyID);
        table.insert(AiArmyTrainerData_TrainerIdToTrainerInstance[_ID].Armies, _ArmyID);
    end
end

function AiTroopTrainer.Internal:RemoveArmy(_ID, _ArmyID)
    if AiArmyTrainerData_TrainerIdToTrainerInstance[_ID] then
        for i= table.getn(AiArmyTrainerData_TrainerIdToTrainerInstance[_ID].Armies), 1, -1 do
            if AiArmyTrainerData_TrainerIdToTrainerInstance[_ID].Armies[i] == _ArmyID then
                table.remove(AiArmyTrainerData_TrainerIdToTrainerInstance[_ID].Armies, i);
            end
        end
    end
end

function AiTroopTrainer.Internal:AddTroop(_ID, _TroopID)
    if self:CanTroopBeAdded(_ID, _TroopID) then
        self:RemoveTroop(_ID, _TroopID);
        table.insert(AiArmyTrainerData_TrainerIdToTrainerInstance[_ID].Refilling, _TroopID);
        return true;
    end
    return false;
end

function AiTroopTrainer.Internal:CanTroopBeAdded(_ID, _TroopID)
    local Trainer = AiArmyTrainerData_TrainerIdToTrainerInstance[_ID];
    local PlayerID = Logic.EntityGetPlayer(_TroopID);
    if Trainer and Trainer.PlayerID == PlayerID then
        local Type = Logic.GetEntityType(_TroopID);
        for i= 1, table.getn(Trainer.AllowedTypes) do
            local Categories = Logic.GetSettlerTypesInUpgradeCategory(Trainer.AllowedTypes[i][1]);
            for j= 2, Categories[1]+1 do
                if Type == Categories[j] then
                    return true;
                end
            end
        end
    end
    return false;
end

function AiTroopTrainer.Internal:RemoveTroop(_ID, _TroopID)
    if AiArmyTrainerData_TrainerIdToTrainerInstance[_ID] then
        for i= table.getn(AiArmyTrainerData_TrainerIdToTrainerInstance[_ID].Refilling), 1, -1 do
            if AiArmyTrainerData_TrainerIdToTrainerInstance[_ID].Refilling[i] == _TroopID then
                table.remove(AiArmyTrainerData_TrainerIdToTrainerInstance[_ID].Refilling, i);
            end
        end
    end
end

function AiTroopTrainer.Internal:ControllTrainer(_Index)
    if self.Data.Trainers[_Index] then
        if IsExisting(self.Data.Trainers[_Index].ScriptName) then
            -- Clear invalid armies
            for i= table.getn(self.Data.Trainers[_Index].Armies), 1, -1 do
                if not AiArmy.Get(self.Data.Trainers[_Index].Armies[i]) then
                    table.remove(self.Data.Trainers[_Index].Armies, i);
                end
            end

            -- Control training
            local ArmyID = self:GetArmyAwardedRespawn(self.Data.Trainers[_Index].ID);
            if ArmyID > 0 and AiArmy.GetBehavior(ArmyID) == AiArmy.Behavior.REFILL then
                local PlayerID = AiArmy.GetPlayer(ArmyID);
                if PlayerID == self.Data.Trainers[_Index].PlayerID then
                    local TroopID = self:Refill(self.Data.Trainers[_Index].ID, ArmyID);
                    if TroopID ~= 0 then
                        AiArmy.AddTroop(ArmyID, TroopID, true);
                    end
                end
            end
        end
    end
end

function AiTroopTrainer.Internal:ControlTrainedUnits(_EntityID)
    local PlayerID = Logic.EntityGetPlayer(_EntityID);
    if Logic.IsEntityInCategory(_EntityID, EntityCategories.Cannon) == 1
    or Logic.IsLeader(_EntityID) == 1 then
        local Trainer;
        for i= table.getn(self.Data.Trainers), 1, -1 do
            if GetDistance(self.Data.Trainers[i], _EntityID) <= 1000 then
                Trainer = self.Data.Trainers[i];
            end
        end
        if Trainer and Trainer.PlayerID == PlayerID then
            local Task = Logic.GetCurrentTaskList(_EntityID);
            if not Task or (Task and string.find(Task, "TRAIN")) then
                self:AddTroop(Trainer.ID, _EntityID);
            end
        end
    end
end

function AiTroopTrainer.Internal:ControlTroopRefilling(_ID)
    local Trainer = AiArmyTrainerData_TrainerIdToTrainerInstance[_ID];
    if Trainer then
        for i= table.getn(Trainer.Refilling), 1, -1 do
            local TroopID = Trainer.Refilling[i];
            if not IsExisting(Trainer.Refilling[i]) then
                table.remove(Trainer.Refilling, i);
            else
                local PlayerID = Logic.EntityGetPlayer(TroopID);
                local SpawnPos = GetPosition(Trainer.SpawnPoint);
                if Trainer.PlayerID == PlayerID then
                    if GetDistance(TroopID, SpawnPos) > AiTroopSpawner.RefillDistance then
                        Logic.MoveSettler(TroopID, SpawnPos.X, SpawnPos.Y);
                    else
                        if not AreEnemiesInArea(Logic.EntityGetPlayer(TroopID), SpawnPos, AiTroopSpawner.NoEnemyDistance) then
                            local MaxAmount = Logic.LeaderGetMaxNumberOfSoldiers(TroopID);
                            local CurAmount = Logic.LeaderGetNumberOfSoldiers(TroopID);
                            if MaxAmount > CurAmount then
                                Tools.CreateSoldiersForLeader(ID, 1);
                            end
                        end
                    end
                end
            end
        end
    end
end

function AiTroopTrainer.Internal:Refill(_ID, _ArmyID)
    local Trainer = AiArmyTrainerData_TrainerIdToTrainerInstance[_ID];
    local TroopID = 0;
    local PlayerID = AiArmy.GetPlayer(_ArmyID);
    if Trainer and PlayerID == Trainer.PlayerID then
        TroopID = self:GetTroop(_ID);
        local TypeAmount = table.getn(Trainer.AllowedTypes);
        if TroopID == 0 and TypeAmount > 0 then
            self:OrderTroop(_ID, math.random(1, TypeAmount));
        end
    end
    return TroopID;
end

function AiTroopTrainer.Internal:OrderTroop(_ID, _Selected)
    local Trainer = AiArmyTrainerData_TrainerIdToTrainerInstance[_ID];
    if Trainer and table.getn(Trainer.Refilling) < 3 then
        local BuildingID = GetID(Trainer.ScriptName);
        local PlayerID = Logic.EntityGetPlayer(BuildingID);
        local UnitCategory = Trainer.AllowedTypes[_Selected][1];
        if InterfaceTool_IsBuildingDoingSomething(BuildingID) == 0 then
            local Costs = {};
            Logic.FillLeaderCostsTable(PlayerID, UnitCategory, Costs);
            for Resource,Amount in pairs(Costs) do
                Logic.AddToPlayersGlobalResource(PlayerID, Resource, Amount)
            end

            local Type = Logic.GetEntityType(BuildingID);
            if Type == Entities.PB_Foundry1 or Type == Entities.PB_Foundry2 then
                local n, SmelterID = Logic.GetAttachedWorkersToBuilding(BuildingID)
				if n >= 1 and Logic.GetCurrentTaskList(SmelterID) == "TL_SMELTER_WORK1_WAIT" then
                    local CannonType = AiTroopTrainerConstants.CannonCategoryToType[UnitCategory];
                    if CannonType then
                        if SendEvent and SendEvent.BuyCannon then
                            -- FIXME: Player change needed?
                            SendEvent.BuyCannon(BuildingID, CannonType);
                        else
                            -- FIXME: Player change needed?
                            GUI.BuyCannon(BuildingID, CannonType);
                        end
                    end
                end
            else
                Logic.BarracksBuyLeader(BuildingID, UnitCategory);
            end
        end
    end
end

function AiTroopTrainer.Internal:GetTroop(_ID)
    local Trainer = AiArmyTrainerData_TrainerIdToTrainerInstance[_ID];
    if Trainer then
        for i= table.getn(Trainer.Refilling), 1, -1 do
            local TroopID = Trainer.Refilling[i];
            if Logic.EntityGetPlayer(TroopID) == Trainer.PlayerID then
                local MaxAmount = Logic.LeaderGetMaxNumberOfSoldiers(TroopID);
                local CurAmount = Logic.LeaderGetNumberOfSoldiers(TroopID);
                if MaxAmount == CurAmount then
                    table.remove(Trainer.Refilling, i);
                    return TroopID;
                end
            end
        end
    end
    return 0;
end

-- Returns the army attached to the trainer with the least amount of troops.
function AiTroopTrainer.Internal:GetArmyAwardedRefill(_ID)
    local LastArmyID = 0;
    local LastStrength = 999;
    local Trainer = AiArmyTrainerData_TrainerIdToTrainerInstance[_ID];
    if Trainer then
        if IsExisting(Trainer.ScriptName) then
            for i= table.getn(Trainer.Armies), 1, -1 do
                local ArmyID = Trainer.Armies[i];
                if AiArmy.IsActive(ArmyID) and AiArmy.GetPlayer(ArmyID) == Trainer.PlayerID then
                    if AiArmy.GetNumberOfLeader(ArmyID) < AiArmy.GetMaxNumberOfLeader(ArmyID) then
                        local Strength = AiArmy.GetNumberOfLeader(ArmyID);
                        if Strength < LastStrength then
                            LastStrength = Strength;
                            LastArmyID = ArmyID;
                        end
                    end
                end
            end
        end
    end
    return LastArmyID;
end

-- -------------------------------------------------------------------------- --

AiTroopTrainerConstants = {
    CannonCategoryToType = {
        [UpgradeCategories.Cannon1] = Entities.PV_Cannon1,
        [UpgradeCategories.Cannon2] = Entities.PV_Cannon2,
        [UpgradeCategories.Cannon3] = Entities.PV_Cannon3,
        [UpgradeCategories.Cannon4] = Entities.PV_Cannon4,
    }
}

