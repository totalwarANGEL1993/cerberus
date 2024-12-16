Lib.Require("comfort/AreEnemiesInArea");
Lib.Require("comfort/ArePositionsConnected");
Lib.Require("comfort/CopyTable");
Lib.Require("comfort/CreateNameForEntity");
Lib.Require("comfort/GetMaxAmountOfPlayer");
Lib.Require("comfort/GetDistance");
Lib.Require("comfort/GetUpgradeCategoryByEntityType");
Lib.Require("comfort/IsValidEntity");
Lib.Require("comfort/IsTraining");
Lib.Require("module/trigger/Job");
Lib.Register("module/ai/AiTroopTrainer");

---
--- Troop recruiter script
---
--- Allows to define buildings as trainers. Trainers recruit troops for armies.
--- attached to them.
---
--- Version ALPHA
---

AiTroopTrainer = AiTroopTrainer or {
    RefillDistance = 1500,
    NoEnemyDistance = 3500,
};

AiArmyTrainerData_TrainerIdToTrainerInstance = {};

AiArmyTrainerConstants_CannonCategoryToType = {
    [UpgradeCategories.Cannon1] = Entities.PV_Cannon1,
    [UpgradeCategories.Cannon2] = Entities.PV_Cannon2,
    [UpgradeCategories.Cannon3] = Entities.PV_Cannon3,
    [UpgradeCategories.Cannon4] = Entities.PV_Cannon4,
};

AiArmyTrainerConstants_DefaultTypes = {
    [Entities.PB_Archery1] = {
        UpgradeCategories.LeaderBow,
        UpgradeCategories.LeaderRifle,
    },
    [Entities.PB_Archery2] = {
        UpgradeCategories.LeaderBow,
        UpgradeCategories.LeaderRifle,
    },
    [Entities.PB_Barracks1] = {
        UpgradeCategories.LeaderPoleArm,
        UpgradeCategories.LeaderSword,
    },
    [Entities.PB_Barracks2] = {
        UpgradeCategories.LeaderPoleArm,
        UpgradeCategories.LeaderSword,
    },
    [Entities.PB_Foundry1] = {
        UpgradeCategories.Cannon1,
        UpgradeCategories.Cannon2,
    },
    [Entities.PB_Foundry2] = {
        UpgradeCategories.Cannon3,
        UpgradeCategories.Cannon4,
    },
    [Entities.PB_Stable1] = {
        UpgradeCategories.LeaderCavalry,
        UpgradeCategories.LeaderHeavyCavalry,
    },
    [Entities.PB_Stable2] = {
        UpgradeCategories.LeaderCavalry,
        UpgradeCategories.LeaderHeavyCavalry,
    },
};

-- -------------------------------------------------------------------------- --
-- API

--- Creates a new trainer.
---
--- Possible fields for definition:
--- * ScriptName   (Required) Scriptname of trainer
--- * RallyPoint   (Required) Position where troops gather
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

--- Adds a new allowed upgrade category to the unit roster.
--- @param _ID integer   ID of trainer
--- @param _Type integer Type of Leader
--- @param _Exp integer  Experience points
function AiTroopTrainer.AddAllowedType(_ID, _Type, _Exp)
    if AiArmyTrainerData_TrainerIdToTrainerInstance[_ID] then
        table.insert(AiArmyTrainerData_TrainerIdToTrainerInstance[_ID].AllowedTypes, {_Type, _Exp});
    end
end

function AiTroopTrainer.IsAllowedType(_ID, _Type)
    return AiTroopTrainer.Internal:IsAllowedType(_ID, _Type);
end

--- Removes all allowed upgrade categories from the unit roster.
--- @param _ID integer ID of trainer
function AiTroopTrainer.ClearAllowedTypes(_ID)
    if AiArmyTrainerData_TrainerIdToTrainerInstance[_ID] then
        AiArmyTrainerData_TrainerIdToTrainerInstance[_ID].AllowedTypes = {};
    end
end

--- Adds an army to the trainer.
---
--- The player ID of the army must match the player ID of the trainer!
--- 
--- @param _ID integer        ID of trainer
--- @param _ArmyID integer    ID of army
function AiTroopTrainer.AddArmy(_ID, _ArmyID)
    AiTroopTrainer.Internal:AddArmy(_ID, _ArmyID);
end

--- Removes an army from the Trainer.
--- @param _ID integer     ID of trainer
--- @param _ArmyID integer ID of army
function AiTroopTrainer.RemoveArmy(_ID, _ArmyID)
    AiTroopTrainer.Internal:RemoveArmy(_ID, _ArmyID);
end

--- Adds a troop to be refilling list.
---
--- When a troop is added to the refiller list it gets new soldiers until it
--- is full. Refilled troops are prioritized before hiring.
---
--- A troop can only be added to a trainer if it's upgrade category is
--- supported, meaning inside the list of categories.
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
--- @return table IdList List of Trainer IDs
function AiTroopTrainer.GetTrainersOfArmy(_ArmyID)
    local SpawnerIDs = {};
    for i= 1, table.getn(AiTroopTrainer.Internal.Data.Trainers) do
        local Trainer = AiTroopTrainer.Internal.Data.Trainers[i];
        for j= 1, table.getn(Trainer.Armies) do
            if Trainer.Armies[j] == _ArmyID then
                table.insert(SpawnerIDs, Trainer.ID);
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

--- Checks if the trainer is alive.
--- @param _ID integer ID of trainer
--- @return boolean Alive Trainer is alive
function AiTroopTrainer.IsAlive(_ID)
    if AiArmyTrainerData_TrainerIdToTrainerInstance[_ID] then
        return IsExisting(AiArmyTrainerData_TrainerIdToTrainerInstance[_ID].ScriptName);
    end
    return false;
end

-- -------------------------------------------------------------------------- --
-- Internal

AiTroopTrainer.Internal = AiTroopTrainer.Internal or {
    Data = {
        TrainerIdSequence = 0,
        CreatedLookup = {},
        ArmiesLookup = {},
        Armies = {},
        Trainers = {},
    },
}

function AiTroopTrainer.Internal:Install()
    if not self.IsInstalled then
        self.IsInstalled = true;

        for PlayerID = 1, GetMaxAmountOfPlayer() do
            self.Data.ArmiesLookup[PlayerID] = {};
        end

        self.ControllerJobID = Job.Turn(function()
            AiTroopTrainer.Internal:ControlTrainers();
        end);

        self.CreationJobID = Job.Create(function()
            local EntityID = Event.GetEntityID();
            AiTroopTrainer.Internal:ControlCreatedUnit(EntityID);
        end);
    end
end

function AiTroopTrainer.Internal:CreateTrainer(_Data)
    self:Install();
    self.Data.TrainerIdSequence = self.Data.TrainerIdSequence +1;
    local ID = self.Data.TrainerIdSequence;

    local PlayerID = Logic.EntityGetPlayer(GetID(_Data.ScriptName));
    local BuildingType = Logic.GetEntityType(GetID(_Data.ScriptName));
    PlayerID = (PlayerID == 0 and 8) or PlayerID;
    local ArmyID = self:GetArmyForLocation(PlayerID, _Data.RallyPoint);
    if ArmyID == -1 then
        return -1;
    end

    local AllowedTypes = AiArmyTrainerConstants_DefaultTypes[BuildingType];
    local FallbackTypes = AiArmyTrainerConstants_DefaultTypes[Entities.PB_Barracks1];
    local Trainer = {
        ID           = ID,
        ArmyID       = ArmyID,
        ScriptName   = _Data.ScriptName,
        SpawnPoint   = _Data.SpawnPoint,
        RallyPoint   = _Data.RallyPoint,
        AllowedTypes = _Data.AllowedTypes or AllowedTypes or FallbackTypes,
        Refilling    = {},
        Armies       = {},
    };
    if Trainer.SpawnPoint == nil then
        local Position = GetPosition(Trainer.ScriptName);
        local EntityID  = AI.Entity_CreateFormation(PlayerID, Entities.PU_Serf, 0, 0, Position.X, Position.Y, 0, 0, 0, 0);
        Position = GetPosition(EntityID);
        DestroyEntity(EntityID);
        EntityID = Logic.CreateEntity(Entities.XD_ScriptEntity, Position.X, Position.Y, 0, PlayerID);
        Trainer.SpawnPoint = Trainer.ScriptName.. "Spawn";
        Logic.SetEntityName(EntityID, Trainer.SpawnPoint);
    end
    Trainer.AllowedTypes.Index = 0;
    AiArmyTrainerData_TrainerIdToTrainerInstance[ID] = Trainer;
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
    local Trainer = AiArmyTrainerData_TrainerIdToTrainerInstance[_ID];
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
    if AiArmyTrainerData_TrainerIdToTrainerInstance[_ID] then
        local ScriptName = AiArmyTrainerData_TrainerIdToTrainerInstance[_ID].ScriptName;
        local TrainerPlayerID = GetPlayer(ScriptName);
        local ArmyPlayerID = AiArmy.GetPlayer(_ArmyID);
        assert(TrainerPlayerID == ArmyPlayerID, "Trainer player ID must match army player ID!");
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

function AiTroopTrainer.Internal:RemoveTroop(_ID, _TroopID)
    if AiArmyTrainerData_TrainerIdToTrainerInstance[_ID] then
        for i= table.getn(AiArmyTrainerData_TrainerIdToTrainerInstance[_ID].Refilling), 1, -1 do
            if AiArmyTrainerData_TrainerIdToTrainerInstance[_ID].Refilling[i] == _TroopID then
                table.remove(AiArmyTrainerData_TrainerIdToTrainerInstance[_ID].Refilling, i);
            end
        end
    end
end

function AiTroopTrainer.Internal:CanTroopBeAdded(_ID, _TroopID)
    local Type = Logic.GetEntityType(_TroopID);
    return self:IsAllowedType(_ID, Type);
end

function AiTroopTrainer.Internal:IsAllowedType(_ID, _Type)
    if AiArmyTrainerData_TrainerIdToTrainerInstance[_ID] then
        for i= 1, table.getn(AiArmyTrainerData_TrainerIdToTrainerInstance[_ID].AllowedTypes) do
            local UpCat = GetUpgradeCategoryByEntityType(_Type);
            if UpCat == AiArmyTrainerData_TrainerIdToTrainerInstance[_ID].AllowedTypes[i] then
                return true;
            end
        end
    end
    return false;
end

function AiTroopTrainer.Internal:IsBuildingBusy(_ID)
    if AiArmyTrainerData_TrainerIdToTrainerInstance[_ID] then
        local Trainer = AiArmyTrainerData_TrainerIdToTrainerInstance[_ID];
        local EntityID = GetID(Trainer.ScriptName);
        if Logic.IsEntityInCategory(EntityID, EntityCategories.Barracks) == 1 then
            return table.getn(Trainer.Refilling) >= 3;
        else
            return InterfaceTool_IsBuildingDoingSomething(EntityID) == true;
        end
        return false;
    end
end

function AiTroopTrainer.Internal:GetArmyForLocation(_PlayerID, _Anchor)
    for i= table.getn(self.Data.ArmiesLookup[_PlayerID]), 1, -1 do
        local Data = self.Data.ArmiesLookup[_PlayerID];
        if ArePositionsConnected(_Anchor, Data.Anchor) then
            return Data.ID;
        end
    end
    local ArmyID = table.getn(self.Data.ArmiesLookup[_PlayerID]);
    if ArmyID > 8 then
        return -1;
    end
    AI.Player_EnableAi(_PlayerID);
    AI.Army_SetAnchor(_PlayerID, ArmyID, _Anchor.X, _Anchor.Y, 0);

    local Army = {
        PlayerID = _PlayerID,
        ID = ArmyID,
        Anchor = _Anchor,
    };
    self.Data.ArmiesLookup[_PlayerID][ArmyID] = Army;
    return ArmyID;
end

function AiTroopTrainer.Internal:GetTroop(_Index, _PlayerID, _RequestedTypes)
    for i= table.getn(self.Data.Trainers[_Index].Refilling), 1, -1 do
        local TroopID = self.Data.Trainers[_Index].Refilling[i];
        local Type = Logic.GetEntityType(TroopID);
        if not _RequestedTypes[1] or self:IsInTroopTable(Type, _RequestedTypes) then
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
    if self.Data.Trainers[_Index].Refilling[1] then
        return -1;
    end
    return 0;
end

function AiTroopTrainer.Internal:IsInTroopTable(_Type, _RequestedTypes)
    local RequestedTypes = CopyTable(_RequestedTypes);
    for i= table.getn(RequestedTypes), 1, -1 do
        if RequestedTypes[i] == _Type then
            return true;
        end
    end
    return false;
end

function AiTroopTrainer.Internal:GetArmyForRespawn(_Index)
    local SelectedArmyID = 0;
    local LastStrength = 9999;
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
                            SelectedArmyID = ArmyID;
                        end
                    end
                end
            end
        end
    end
    return SelectedArmyID;
end

function AiTroopTrainer.Internal:ControlTrainers()
    -- Add created units to trainer
    for LeaderID, _ in pairs(self.Data.CreatedLookup) do
        local BarrackID = Logic.LeaderGetBarrack(LeaderID);
        if BarrackID ~= 0 then
            local ScriptName = Logic.GetEntityName(BarrackID);
            local TrainerID = self:GetByEntity(ScriptName);
            local Trainer = AiArmyTrainerData_TrainerIdToTrainerInstance[TrainerID];
            self:AddTroop(TrainerID, LeaderID);
            for i= 1, table.getn(Trainer.Armies) do
                local ArmyID = Trainer.Armies[i];
                if AiArmy.GetNumberOfLeader(ArmyID) < AiArmy.GetMaxNumberOfLeader(ArmyID) then
                    if AiArmy.IsCommandOfTypeActive(ArmyID, AiArmyCommand.Refill)
                    or AiArmy.IsArmyNear(ArmyID, AiArmy.GetHomePosition(ArmyID), 1500) then
                        AiArmy.AddTroop(ArmyID, LeaderID, true);
                        break;
                    end
                end
            end
        end
        self.Data.CreatedLookup[LeaderID] = nil;
    end
    -- Control trainers
    for i= table.getn(self.Data.Trainers), 1, -1 do
        local DataMod = math.mod(self.Data.Trainers[i].ID, 10);
        local TimeMod = math.mod(Logic.GetCurrentTurn(), 10);
        if DataMod == TimeMod then
            self:ControlTrainer(i);
        end
    end
end

function AiTroopTrainer.Internal:ControlTrainer(_Index)
    local Trainer = self.Data.Trainers[_Index];
    -- Check is existing
    if not IsExisting(Trainer.ScriptName) then
        return;
    end

    local Position = GetPosition(Trainer.SpawnPoint);
    local PlayerID = Logic.EntityGetPlayer(GetID(Trainer.ScriptName));
    PlayerID = (PlayerID == 0 and 8) or PlayerID;
    local TroopID = 0;

    -- Control refilling troops
    self:ControlTroopRefilling(_Index);

    -- Get troop
    local ArmyID = self:GetArmyForRespawn(_Index);
    if ArmyID > 0 then
        if AiArmy.IsCommandOfTypeActive(ArmyID, AiArmyCommand.Refill)
        or AiArmy.IsArmyNear(ArmyID, AiArmy.GetHomePosition(ArmyID), 1500) then
            if PlayerID ~= 0 then
                local Types = AiArmy.GetAllowedTypes(ArmyID);
                TroopID = self:GetTroop(_Index, PlayerID, Types);
                if TroopID > 0 then
                    AiArmy.AddTroop(ArmyID, TroopID, true);
                    return;
                end
            end
        end
    end

    -- Buy troop
    for i= table.getn(Trainer.Armies), 1, -1 do
        ArmyID = Trainer.Armies[i];
        if AiArmy.GetNumberOfLeader(ArmyID) < AiArmy.GetMaxNumberOfLeader(ArmyID) then
            if AiArmy.IsCommandOfTypeActive(ArmyID, AiArmyCommand.Refill)
            or AiArmy.IsArmyNear(ArmyID, AiArmy.GetHomePosition(ArmyID), 1500) then
                if not self:IsBuildingBusy(Trainer.ID) then
                    local Types = AiArmy.GetAllowedCategories(ArmyID);
                    if Types[1] == nil then
                        Types = Trainer.AllowedTypes;
                    end
                    local TypeCount = table.getn(Types);
                    local RandomIndex = math.random(1, TypeCount);
                    local UpCat = Types[RandomIndex];
                    UpCat = AiArmyTrainerConstants_CannonCategoryToType[UpCat] or UpCat;
                    AI.Army_SetAnchor(PlayerID, Trainer.ArmyID, Position.X, Position.Y, 0);
                    AI.Army_BuyLeader(PlayerID, Trainer.ArmyID, UpCat);
                    return;
                end
            end
        end
    end
end

function AiTroopTrainer.Internal:ControlTroopRefilling(_Index)
    local Trainer = self.Data.Trainers[_Index];
    if IsExisting(Trainer.ScriptName) then
        for i= table.getn(Trainer.Refilling), 1, -1 do
            local TroopID = Trainer.Refilling[i];
            local BarrackID = Logic.LeaderGetBarrack(TroopID);
            if not IsExisting(TroopID) then
                table.remove(self.Data.Trainers[_Index].Refilling, i);
            elseif BarrackID == 0 then
                local MaxAmount = Logic.LeaderGetMaxNumberOfSoldiers(TroopID);
                local CurAmount = Logic.LeaderGetNumberOfSoldiers(TroopID);
                if CurAmount >= MaxAmount then
                    if AiArmy.GetArmyOfTroop(TroopID) ~= 0 then
                        table.remove(self.Data.Trainers[_Index].Refilling, i);
                    end
                else
                    local SpawnPos = GetPosition(Trainer.SpawnPoint);
                    if GetDistance(TroopID, SpawnPos) > AiTroopTrainer.RefillDistance then
                        if Logic.IsEntityMoving(TroopID) == false then
                            Logic.MoveSettler(TroopID, SpawnPos.X, SpawnPos.Y);
                        end
                    else
                        if MaxAmount > CurAmount and not IsFighting(TroopID) and IsValidEntity(TroopID) then
                            local PlayerID = Logic.EntityGetPlayer(TroopID);
                            local SoldierType = Logic.LeaderGetSoldiersType(TroopID);
                            local Position = GetPosition(Trainer.SpawnPoint);
                            local SoldierID = Logic.CreateEntity(SoldierType, Position.X, Position.Y, 0, PlayerID);
                            if IsExisting(SoldierID) then
                                Logic.LeaderGetOneSoldier(TroopID);
                            end
                        end
                    end
                end
            end
        end
    end
end

function AiTroopTrainer.Internal:ControlCreatedUnit(_EntityID)
    if Logic.IsEntityInCategory(_EntityID, EntityCategories.Cannon) == 1 then
        local PlayerID = Logic.EntityGetPlayer(_EntityID);
        local x, y, z = Logic.EntityGetPos(_EntityID);
        local Foundry1 = {Logic.GetPlayerEntitiesInArea(PlayerID, Entities.PB_Foundry1, x, y, 900, 16)};
        local Foundry2 = {Logic.GetPlayerEntitiesInArea(PlayerID, Entities.PB_Foundry2, x, y, 900, 16)};
        table.remove(Foundry1, 1);
        table.remove(Foundry2, 1);
        local CannonFactories = CopyTable(Foundry2, Foundry1);
        for i= 1, table.getn(CannonFactories) do
            if Logic.IsConstructionComplete(CannonFactories[i]) == 1 then
                local TrainerID = self:GetByEntity(CannonFactories[i]);
                self:AddTroop(TrainerID, _EntityID);
                break;
            end
        end
    elseif Logic.IsLeader(_EntityID) ~= 0 then
        AiTroopTrainer.Internal.Data.CreatedLookup[_EntityID] = true;
    end
end

