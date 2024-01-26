Lib.Require("comfort/AreEnemiesInArea");
Lib.Require("comfort/GetDistance");
Lib.Require("comfort/IsFighting");
Lib.Require("comfort/GetMaxAmountOfPlayer");
Lib.Require("module/trigger/Job");
Lib.Register("module/ai/AiTroopTrainer");

---
--- Troop recruiter script
---
--- TODO: implement
---

AiTroopTrainer = AiTroopTrainer or {};

AiArmyTrainerData_TrainerIDToTrainerInstance = {};

AiTroopTrainer_CannonCategoryToCannonType = {
    [UpgradeCategories.Cannon1] = Entities.PV_Cannon1,
    [UpgradeCategories.Cannon2] = Entities.PV_Cannon2,
    [UpgradeCategories.Cannon3] = Entities.PV_Cannon3,
    [UpgradeCategories.Cannon4] = Entities.PV_Cannon4,
}

-- -------------------------------------------------------------------------- --
-- API

--- Creates a new trainer.
---
--- If any error occurs, 0 will be returned.
---
--- Possible fields for definition:
--- * ScriptName   (Required) Scriptname of trainer
--- * SpawnPoint   (Optional) ScriptName of position
---                (If an entity Scriptname.. "Spawn" exists, it will be taken automatically)
--- * AllowedTypes (Optional) List of upgrade categories
---
--- @param _Data table Troop Trainer definition
--- @return integer ID ID of trainer
function AiTroopTrainer.Create(_Data)
    return AiTroopTrainer.Internal:CreateTrainer(_Data);
end

--- Deletes a trainer.
--- @param _ID integer ID of trainer
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
--- @param _ID integer   ID of trainer
--- @param _Type integer Upgrade category of Leader
--- @param _Exp integer?  Experience points (unused)
function AiTroopTrainer.AddAllowedType(_ID, _Type, _Exp)
    if AiArmyTrainerData_TrainerIDToTrainerInstance[_ID] then
        table.insert(AiArmyTrainerData_TrainerIDToTrainerInstance[_ID].AllowedTypes, _Type);
    end
end

--- Removes all allowed types from the unit roster.
--- @param _ID integer ID of trainer
function AiTroopTrainer.ClearAllowedTypes(_ID)
    if AiArmyTrainerData_TrainerIDToTrainerInstance[_ID] then
        AiArmyTrainerData_TrainerIDToTrainerInstance[_ID].AllowedTypes = {};
    end
end

--- Adds an army to the trainer.
---
--- The player ID of the army must match the player ID of the trainer!
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
--- @param _ID integer      ID of trainer
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
--- @param _ID integer      ID of trainer
--- @param _TroopID integer ID of troop
function AiTroopTrainer.RemoveTroop(_ID, _TroopID)
    AiTroopTrainer.Internal:RemoveTroop(_ID, _TroopID);
end

--- All troops that are currently refilling are removed from the trainer.
--- @param _ID integer ID of trainer
--- @return table List of troops
function AiTroopTrainer.DraftTroops(_ID)
    local Troops = {};
    if AiArmyTrainerData_TrainerIDToTrainerInstance[_ID] then
        for i= table.getn(AiArmyTrainerData_TrainerIDToTrainerInstance[_ID].Refilling), 1, -1 do
            local ID = table.remove(AiArmyTrainerData_TrainerIDToTrainerInstance[_ID].Refilling, i);
            table.insert(Troops, ID);
        end
    end
    return Troops;
end

--- Returns all trainers the army is connected to.
--- @param _ArmyID integer ID of army
--- @return table IdList List of Trainer IDs
function AiTroopTrainer.GetTrainersOfArmy(_ArmyID)
    local TrainerIDs = {};
    for i= 1, table.getn(AiTroopTrainer.Internal.Data.Trainers) do
        local Trainer = AiTroopTrainer.Internal.Data.Trainers[i];
        for j= 1, table.getn(Trainer.Armies) do
            if Trainer.Armies[j] == _ArmyID then
                table.insert(TrainerIDs, Trainer.ID);
            end
        end
    end
    return TrainerIDs;
end

--- Changes the owner of the trainer.
--- @param _ID integer ID of trainer
--- @param _PlayerID integer New owner
function AiTroopTrainer.ChangePlayer(_ID, _PlayerID)
    return AiTroopTrainer.Internal:ChangePlayer(_ID, _PlayerID);
end

--- Checks if the trainer is alive.
--- @param _ID integer ID of trainer
--- @return boolean Alive Trainer is alive
function AiTroopTrainer.IsAlive(_ID)
    if AiArmyTrainerData_TrainerIDToTrainerInstance[_ID] then
        return IsExisting(AiArmyTrainerData_TrainerIDToTrainerInstance[_ID].ScriptName);
    end
    return false;
end

-- -------------------------------------------------------------------------- --
-- Internal

AiTroopTrainer.Internal = AiTroopTrainer.Internal or {
    Data = {
        TrainerIdSequence = 0,
        Trainers = {},
        GlobalOrderList = {},
        GlobalHireList = {},
    },
}

function AiTroopTrainer.Internal:Install()
    if not self.IsInstalled then
        self.IsInstalled = true;

        Job.Second(function()
            for i= table.getn(AiTroopTrainer.Internal.Data.Trainers), 1, -1 do
                AiTroopTrainer.Internal:ControllTrainer(i);
            end
        end);

        Job.Turn(function()
            AiTroopTrainer.Internal:AssignHiredTroopsToTrainerController();
            AiTroopTrainer.Internal:HireTroopsFromOrderQueueController();
        end);

        Job.Create(function()
            AiTroopTrainer.Internal:EntityCreatedController();
        end);
    end
end

function AiTroopTrainer.Internal:CreateTrainer(_Data)
    self:Install();
    self.Data.TrainerIdSequence = self.Data.TrainerIdSequence +1;
    local ID = self.Data.TrainerIdSequence;

    local AllowedTypes = _Data.AllowedTypes or {};

    local Trainer = {
        ID           = ID,
        ScriptName   = _Data.ScriptName,
        SpawnPoint   = _Data.SpawnPoint,
        AllowedTypes = AllowedTypes,
        Refilling    = {},
        Trainees     = {},
        Armies       = {},
    }
    if _Data.Endlessly then
        Trainer.Endlessly = _Data.Endlessly == true;
    end
    if Trainer.SpawnPoint == nil then
        if IsExisting(Trainer.ScriptName.. "Spawn") then
            Trainer.SpawnPoint = Trainer.ScriptName.. "Spawn";
        else
            local Position = GetPosition(Trainer.ScriptName);
            local PlayerID = Logic.EntityGetPlayer(GetID(Trainer.ScriptName));
            PlayerID = (PlayerID == 0 and 8) or PlayerID;
            local EntityID  = AI.Entity_CreateFormation(PlayerID, Entities.PU_Serf, 0, 0, Position.X, Position.Y, 0, 0, 0, 0);
            Position = GetPosition(EntityID);
            DestroyEntity(EntityID);
            EntityID = Logic.CreateEntity(Entities.XD_ScriptEntity, Position.X, Position.Y, 0, PlayerID);
            Trainer.SpawnPoint = Trainer.ScriptName.. "Spawn";
            Logic.SetEntityName(EntityID, Trainer.SpawnPoint);
        end
    end
    Trainer.AllowedTypes.Index = 0;
    AiArmyTrainerData_TrainerIDToTrainerInstance[ID] = Trainer;
    table.insert(self.Data.Trainers, Trainer);
    return ID;
end

function AiTroopTrainer.Internal:DeleteTrainer(_ID)
    for i= table.getn(self.Data.Trainers), 1, -1 do
        if self.Data.Trainers[i].ID == _ID then
            table.remove(self.Data.Trainers, i);
        end
    end
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
    local Trainer = AiArmyTrainerData_TrainerIDToTrainerInstance[_ID];
    if Trainer then
        local Refilling = {};
        for k,v in pairs(Trainer.Refilling) do
            table.insert(Refilling, ChangePlayer(v, _PlayerID));
        end
        Trainer.Refilling = Refilling;

        ChangePlayer(Trainer.ScriptName, _PlayerID);
    end
end

function AiTroopTrainer.Internal:AddArmy(_ID, _ArmyID)
    if AiArmyTrainerData_TrainerIDToTrainerInstance[_ID] then
        local ScriptName = AiArmyTrainerData_TrainerIDToTrainerInstance[_ID].ScriptName;
        local TrainerPlayerID = GetPlayer(ScriptName);
        local ArmyPlayerID = AiArmy.GetPlayer(_ArmyID);
        assert(TrainerPlayerID == ArmyPlayerID, "Trainer player ID must match army player ID!");
        self:RemoveArmy(_ID, _ArmyID);
        table.insert(AiArmyTrainerData_TrainerIDToTrainerInstance[_ID].Armies, _ArmyID);
    end
end

function AiTroopTrainer.Internal:RemoveArmy(_ID, _ArmyID)
    if AiArmyTrainerData_TrainerIDToTrainerInstance[_ID] then
        for i= table.getn(AiArmyTrainerData_TrainerIDToTrainerInstance[_ID].Armies), 1, -1 do
            if AiArmyTrainerData_TrainerIDToTrainerInstance[_ID].Armies[i] == _ArmyID then
                table.remove(AiArmyTrainerData_TrainerIDToTrainerInstance[_ID].Armies, i);
            end
        end
    end
end

function AiTroopTrainer.Internal:AddTroop(_ID, _TroopID)
    if self:CanTroopBeAdded(_ID, _TroopID) then
        self:RemoveTroop(_ID, _TroopID);
        table.insert(AiArmyTrainerData_TrainerIDToTrainerInstance[_ID].Refilling, _TroopID);
        return true;
    end
    return false;
end

function AiTroopTrainer.Internal:CanTroopBeAdded(_ID, _TroopID)
    if AiArmyTrainerData_TrainerIDToTrainerInstance[_ID] then
        local Type = Logic.GetEntityType(_TroopID);
        for i= 1, table.getn(AiArmyTrainerData_TrainerIDToTrainerInstance[_ID].AllowedTypes) do
            if Type == AiArmyTrainerData_TrainerIDToTrainerInstance[_ID].AllowedTypes[i] then
                return true;
            end
        end
    end
    return false;
end

function AiTroopTrainer.Internal:RemoveTroop(_ID, _TroopID)
    if AiArmyTrainerData_TrainerIDToTrainerInstance[_ID] then
        for i= table.getn(AiArmyTrainerData_TrainerIDToTrainerInstance[_ID].Refilling), 1, -1 do
            if AiArmyTrainerData_TrainerIDToTrainerInstance[_ID].Refilling[i] == _TroopID then
                table.remove(AiArmyTrainerData_TrainerIDToTrainerInstance[_ID].Refilling, i);
            end
        end
    end
end

function AiTroopTrainer.Internal:ControllTrainer(_Index)
    -- Control Trainer
    local Trainer = self.Data.Trainers[_Index];
    if Trainer then
        if IsExisting(Trainer.ScriptName) then
            -- Clear invalid armies
            for i= table.getn(Trainer.Armies), 1, -1 do
                if not AiArmy.Get(Trainer.Armies[i]) then
                    table.remove(Trainer.Armies, i);
                end
            end

            -- Control refilling troops
            self:ControlTroopRefilling(_Index);

            -- Assign refilled troop
            -- Adds 1 refilled troop per second to the weakest army if possible
            local ArmyID = self:GetArmyToRefill(_Index);
            if ArmyID > 0 then
                if AiArmy.IsCommandOfTypeActive(ArmyID, AiArmyCommand.Refill)
                or AiArmy.IsArmyNear(ArmyID, AiArmy.GetHomePosition(ArmyID), 1500) then
                    local PlayerID = AiArmy.GetPlayer(ArmyID);
                    if PlayerID ~= 0 then
                        local Types = AiArmy.GetAllowedTypes(ArmyID);
                        local TroopID = self:GetTroop(_Index, PlayerID, Types);
                        if TroopID > 0 then
                            AiArmy.AddTroop(ArmyID, TroopID, true);
                        end
                    end
                end
            end

            -- Control training
            -- Hires troops or adds an existing troop
            ArmyID = self:GetArmyToRefill(_Index);
            if ArmyID > 0 then
                if AiArmy.IsCommandOfTypeActive(ArmyID, AiArmyCommand.Refill)
                or AiArmy.IsArmyNear(ArmyID, AiArmy.GetHomePosition(ArmyID), 1500) then
                    local Types = AiArmy.GetAllowedTypes(ArmyID);
                    self:Train(_Index, ArmyID, Types);
                end
            end
        end
    end
end

function AiTroopTrainer.Internal:ControlTroopRefilling(_Index)
    local Trainer = self.Data.Trainers[_Index];
    for i= table.getn(Trainer.Refilling), 1, -1 do
        local TroopID = Trainer.Refilling[i];
        if not IsExisting(Trainer.Refilling[i]) then
            table.remove(self.Data.Trainers[_Index].Refilling, i);
        else
            local SpawnPos = GetPosition(Trainer.SpawnPoint);
            if GetDistance(TroopID, SpawnPos) > AiTroopTrainer.RefillDistance then
                local Task = Logic.GetCurrentTaskList(TroopID);
                if Logic.IsEntityMoving(TroopID) == false then
                    Logic.MoveSettler(TroopID, SpawnPos.X, SpawnPos.Y);
                end
            else
                local MaxAmount = Logic.LeaderGetMaxNumberOfSoldiers(TroopID);
                local CurAmount = Logic.LeaderGetNumberOfSoldiers(TroopID);
                if IsValidEntity(TroopID) and MaxAmount > CurAmount and not IsFighting(TroopID) then
                    -- TODO: Use real purchase here?
                    Tools.CreateSoldiersForLeader(TroopID, 1);
                end
            end
        end
    end
end

function AiTroopTrainer.Internal:Train(_Index, _ArmyID, _RequestedTypes)
    local TroopID = 0;
    local TypeListSize = table.getn(_RequestedTypes);
    local PlayerID = AiArmy.GetPlayer(_ArmyID);
    if PlayerID ~= 0 then
        local TrainerID = self.Data.Trainers[_Index];
        local AllowedTypes = self.Data.Trainers[_Index].AllowedTypes;
        assert(table.getn(AllowedTypes) > 0);
        -- Check can hire required type
        local HasAnyType = TypeListSize == 0;
        if not HasAnyType then
            for i= 1, table.getn(_RequestedTypes) do
                for j= 1, table.getn(AllowedTypes) do
                    if _RequestedTypes[i] == AllowedTypes[j] then
                        HasAnyType = true;
                        break;
                    end
                end
            end
        end
        -- Choose and hire type
        if HasAnyType then
            TroopID = self:GetTroop(_Index, PlayerID, _RequestedTypes);
            local TypeAmount = table.getn(AllowedTypes);
            if TroopID == 0 and TypeAmount > 0 then
                local UpgradeCategory = 0;
                -- Select unit to hire
                while UpgradeCategory == 0 do
                    local TroopIndex = math.random(1, TypeAmount);
                    local Type = self.Data.Trainers[_Index].AllowedTypes[TroopIndex];
                    local TypeFound = TypeListSize == 0;
                    if not TypeFound then
                        for i= 1, table.getn(_RequestedTypes) do
                            if _RequestedTypes[i][1] == Type then
                                TypeFound = true;
                                break;
                            end
                        end
                    end
                    if TypeFound then
                        UpgradeCategory = Type;
                        break;
                    end
                end
                -- Hire unit
                if UpgradeCategory > 0 then
                    if self:CanOrderBePlaced(_ArmyID, TrainerID, UpgradeCategory) then
                        self:PushToGlobalOrderList(TrainerID, _ArmyID, UpgradeCategory);
                    end
                end
            end
        end
    end
end

function AiTroopTrainer.Internal:GetTroop(_Index, _PlayerID, _RequestedTypes)
    for i= table.getn(self.Data.Trainers[_Index].Refilling), 1, -1 do
        local TroopID = self.Data.Trainers[_Index].Refilling[i];
        local Type = Logic.GetEntityType(TroopID);
        if not _RequestedTypes or not _RequestedTypes[1] or IsInTable(Type, _RequestedTypes) then
            if Logic.EntityGetPlayer(TroopID) == _PlayerID then
                local MaxAmount = Logic.LeaderGetMaxNumberOfSoldiers(TroopID);
                local CurAmount = Logic.LeaderGetNumberOfSoldiers(TroopID);
                if MaxAmount == CurAmount then
                    table.remove(self.Data.Trainers[_Index].Refilling, i);
                    return TroopID;
                end
            end
        end
    end
    -- At least one leader is refilling
    if self.Data.Trainers[_Index].Refilling[1] then
        return -1;
    end
    return 0;
end

-- Returns the army attached to the trainer with the least amount of troops.
function AiTroopTrainer.Internal:GetArmyToRefill(_Index)
    local LastArmyID = 0;
    local LastStrength = 999;
    local Trainer = self.Data.Trainers[_Index];
    if Trainer then
        if IsExisting(Trainer.ScriptName) then
            for i= table.getn(Trainer.Armies), 1, -1 do
                local ArmyID = Trainer.Armies[i];
                if AiArmy.IsActive(ArmyID) then
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
-- Recruting management

-- Controls the hiring from the order cache in the recruiter building.
function AiTroopTrainer.Internal:HireTroopsFromOrderQueueController()
    for TrainerID, Trainer in pairs(AiArmyTrainerData_TrainerIDToTrainerInstance) do
        local BuildingID = GetID(Trainer.ScriptName);
        if IsExisting(BuildingID) and self:CanBuildingHireUnits(BuildingID) then
            local HirelingCount = self:CountHirelingsAtTrainer(TrainerID);
            local OrderCount = self:CountOrderingsAtTrainer(TrainerID);
            if OrderCount > 0 and HirelingCount < 3 then
                local Entry = self:PopFromGlobalOrderList(TrainerID);
                -- Hire unit if army is active
                if AiArmy.IsActive(Entry[1]) then
                    local MaxLeader = AiArmy.GetMaxNumberOfLeader(Entry[1]);
                    local Leader = AiArmy.GetNumberOfLeader(Entry[1]);
                    -- Fail-Save: only recruit if not allready full
                    -- FIXME: Reinforcements must also be considered!
                    if MaxLeader - Leader > 0 then
                        if AiTroopTrainer_CannonCategoryToCannonType[Entry[2]] then
                            self:HireCannon(BuildingID, Entry[2]);
                        else
                            self:HireLeader(BuildingID, Entry[2]);
                        end
                    end
                -- Otherwise return entry to offer list
                else
                    self:PushToGlobalOrderList(TrainerID, Entry[1], Entry[2]);
                end
            end
        end
    end
end

-- Controls adding recruted leaders to the trainer.
function AiTroopTrainer.Internal:AssignHiredTroopsToTrainerController()
    for TrainerID, Trainer in pairs(AiArmyTrainerData_TrainerIDToTrainerInstance) do
        local BuildingID = GetID(Trainer.ScriptName);
        local RecruteeCount = self:CountHirelingsAtTrainer(TrainerID);
        if RecruteeCount > 0 and IsExisting(BuildingID) then
            local Entry = self:PopFromGlobalHireList(TrainerID);
            local BarracksID = Logic.LeaderGetBarrack(Entry[1]);
            -- If really training at barracks, add to trainee list
            if BarracksID == BuildingID then
                table.insert(Trainer.Trainees, Entry[1]);
            -- Otherwise add to refill list (ignoring edge case)
            else
                table.insert(Trainer.Refilling, Entry[1]);
            end
        end
    end
end

-- Adds created leaders to the hiring cache.
function AiTroopTrainer.Internal:EntityCreatedController()
    local EntityID = Event.GetEntityID();
    if Logic.IsLeader(EntityID) == 1 then
        local TrainerID = 0;
        for ID, Instance in pairs(AiArmyTrainerData_TrainerIDToTrainerInstance) do
            if GetDistance(EntityID, Instance.ScriptName) <= 1000 then
                TrainerID = ID;
                break;
            end
        end
        if TrainerID ~= 0 and Logic.LeaderGetNumberOfSoldiers(EntityID) == 0 then
            self:PushToGlobalHireList(TrainerID, EntityID);
        end
    end
end

function AiTroopTrainer.Internal:CanOrderBePlaced(_ArmyID, _TrainerID, _UpgradeCategory)
    if AiArmyTrainerData_TrainerIDToTrainerInstance[_TrainerID] then
        local Trainer = AiArmyTrainerData_TrainerIDToTrainerInstance[_TrainerID];
        local BuildingID = GetID(Trainer.ScriptName);
        if AiArmy.IsActive(_ArmyID) and self:CanBuildingHireUnits(BuildingID) then
            local MaxLeader = AiArmy.GetMaxNumberOfLeader(_ArmyID);
            local Leader = AiArmy.GetNumberOfLeader(_ArmyID);
            local Hirelings = self:CountHirelingsOfArmy(_ArmyID);
            local Orders = self:CountOrderingsOfArmy(_ArmyID);
            if Orders + Hirelings < MaxLeader - Leader then
                return IsInTable(_UpgradeCategory, Trainer.AllowedTypes);
            end
        end
    end
    return false;
end

function AiTroopTrainer.Internal:CanBuildingHireUnits(_BuildingID)
    if IsExisting(_BuildingID) then
        if InterfaceTool_IsBuildingDoingSomething(_BuildingID) == false then
            local MaxHealth = Logic.GetEntityMaxHealth(_BuildingID);
            local Health = Logic.GetEntityHealth(_BuildingID);
            if Health / MaxHealth <= 0.2 then
                return false;
            end
            local Type = Logic.GetEntityType(_BuildingID);
            if Type == Entities.PB_Foundry1 or Type == Entities.PB_Foundry2 then
                local Workers = {Logic.GetAttachedWorkersToBuilding(_BuildingID)};
                if not Workers[2] or Logic.IsSettlerAtWork(Workers[2]) == 0 then
                    return false;
                end
            else
                local x, y, z = Logic.EntityGetPos(_BuildingID);
                local PlayerID = Logic.EntityGetPlayer(_BuildingID);
                local Training = {Logic.GetPlayerEntitiesInArea(PlayerID, 0, x, y, 800, 3, 2)};
                if Training[1] >= 3 then
                    return false;
                end
            end
        end
    end
    return true;
end

function AiTroopTrainer.Internal:HireLeader(_BuildingID, _UpgradeCategory)
    local PlayerID = Logic.EntityGetPos(_BuildingID);
    self:CheatUnitCosts(PlayerID, _UpgradeCategory);
    Logic.BarracksBuyLeader(_BuildingID, _UpgradeCategory);
end

function AiTroopTrainer.Internal:HireCannon(_BuildingID, _UpgradeCategory)
    local Type = AiTroopTrainer_CannonCategoryToCannonType[_UpgradeCategory];
    if Type then
        local PlayerID = Logic.EntityGetPos(_BuildingID);
        self:CheatUnitCosts(PlayerID, _UpgradeCategory);
        ((CNetwork and (SendEvent or CSendEvent)) or GUI).BuyCannon(_BuildingID, Type);
    end
end

function AiTroopTrainer.Internal:CheatUnitCosts(_PlayerID, _UpgradeCategory)
    local CostTable = {};
    Logic.FillLeaderCostsTable(_PlayerID, _UpgradeCategory, CostTable);
    for ResType, Amount in pairs(CostTable) do
        Logic.AddToPlayersGlobalResource(_PlayerID, ResType, Amount * 17);
    end
end

function AiTroopTrainer.Internal:PushToGlobalHireList(_TrainerID, _LeaderID)
    self.Data.GlobalHireList[_TrainerID] = self.Data.GlobalHireList[_TrainerID] or {0};
    table.insert(self.Data.GlobalHireList[_TrainerID], {_LeaderID});
    self.Data.GlobalHireList[_TrainerID][1] = self.Data.GlobalHireList[_TrainerID][1] + 1;
end

function AiTroopTrainer.Internal:PopFromGlobalHireList(_TrainerID)
    self.Data.GlobalHireList[_TrainerID] = self.Data.GlobalHireList[_TrainerID] or {0};
    if self.Data.GlobalHireList[_TrainerID][1] > 0 then
        self.Data.GlobalHireList[_TrainerID][1] = self.Data.GlobalHireList[_TrainerID][1] - 1;
        return table.remove(self.Data.GlobalHireList[_TrainerID], 2);
    end
end

function AiTroopTrainer.Internal:CountHirelingsAtTrainer(_TrainerID)
    self.Data.GlobalHireList[_TrainerID] = self.Data.GlobalHireList[_TrainerID] or {0};
    return self.Data.GlobalHireList[_TrainerID][1];
end

function AiTroopTrainer.Internal:CountHirelingsOfArmy(_ArmyID)
    local Amount = 0;
    for TrainerID, Data in pairs(self.Data.GlobalHireList) do
        if Data[1] == _ArmyID then
            Amount = Amount + 1;
        end
    end
    return Amount;
end

function AiTroopTrainer.Internal:PushToGlobalOrderList(_TrainerID, _ArmyID, _UpgradeCategory)
    self.Data.GlobalOrderList[_TrainerID] = self.Data.GlobalOrderList[_TrainerID] or {0};
    table.insert(self.Data.GlobalOrderList[_TrainerID], {_ArmyID, _UpgradeCategory});
    self.Data.GlobalOrderList[_TrainerID][1] = self.Data.GlobalOrderList[_TrainerID][1] + 1;
end

function AiTroopTrainer.Internal:PopFromGlobalOrderList(_TrainerID)
    self.Data.GlobalOrderList[_TrainerID] = self.Data.GlobalOrderList[_TrainerID] or {0};
    if self.Data.GlobalOrderList[_TrainerID][1] > 0 then
        self.Data.GlobalOrderList[_TrainerID][1] = self.Data.GlobalOrderList[_TrainerID][1] - 1;
        return table.remove(self.Data.GlobalOrderList[_TrainerID], 2);
    end
end

function AiTroopTrainer.Internal:CountOrderingsAtTrainer(_TrainerID)
    self.Data.GlobalOrderList[_TrainerID] = self.Data.GlobalOrderList[_TrainerID] or {0};
    return self.Data.GlobalOrderList[_TrainerID][1];
end

function AiTroopTrainer.Internal:CountOrderingsOfArmy(_ArmyID)
    local Amount = 0;
    for TrainerID, Data in pairs(self.Data.GlobalOrderList) do
        if Data[1] == _ArmyID then
            Amount = Amount + 1;
        end
    end
    return Amount;
end

