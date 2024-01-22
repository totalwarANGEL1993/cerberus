Lib.Require("module/ai/AiTroopSpawner");
Lib.Require("module/ai/AiTroopTrainer");
Lib.Register("module/ai/AiArmyRefiller");

---
--- Army refiller mapping
---
--- This script is a facade that unifies spawners and trainers as much as
--- possible. All shared methods are automatically directed to the right
--- type. For specialized calls the internal spawner or trainer ID can be
--- obtained and passed to the appropiate original methods.
---
--- * Spawner: A spawner creates the troops using an entity as the generator.
---   If the generator is destroyed nothing will be spawned.
--- * Trainer: A trainer recruits the units at reachable military buildings.
---   They continue as long as buildings are present.
---
--- Version 1.0.0
---

AiArmyRefiller = AiArmyRefiller or {};

-- -------------------------------------------------------------------------- --
-- API

--- Creates a new spawner.
---
--- Possible fields for definition:
--- * ScriptName   (Required) Scriptname of spawner
--- * SpawnPoint   (Optional) Scriptname of position
--- * SpawnAmount  (Optional) Max amount to spawn per cycle
--- * SpawnTimer   (Optional) Time between spawn cycles
--- * Sequentially (Optional) Order of spawns is sequentially
--- * Endlessly    (Optional) Spawns repeat infinite
--- * AllowedTypes (Optional) List of types {Type, Experience}
---
--- @param _Data table Troop Spawner definition
--- @return integer ID ID of spawner
function AiArmyRefiller.CreateSpawner(_Data)
    assert(AiTroopSpawner.Get(_Data.ScriptName) == 0);
    assert(AiTroopTrainer.Get(_Data.ScriptName) == 0);
    return AiArmyRefiller.Internal:CreateSpawner(_Data);
end

--- Creates a new trainer.
---
--- If any error occurs, 0 will be returned.
---
--- Possible fields for definition:
--- * ScriptName   (Required) Scriptname of spawner
--- * SpawnPoint   (Optional) Scriptname of position
--- * AllowedTypes (Optional) List of upgrade categories
---
--- @param _Data table Troop Trainer definition
--- @return integer ID ID of trainer
function AiArmyRefiller.CreateTrainer(_Data)
    assert(AiTroopSpawner.Get(_Data.ScriptName) == 0);
    assert(AiTroopTrainer.Get(_Data.ScriptName) == 0);
    return AiArmyRefiller.Internal:CreateTrainer(_Data);
end

--- Deletes a refiller.
--- @param _ID integer ID of refiller
function AiArmyRefiller.DeleteRefiller(_ID)
    local SpawnerID = AiArmyRefiller.Internal:GetSpawnerID(_ID);
    if SpawnerID ~= 0 then
        AiTroopSpawner.Delete(SpawnerID);
    end
    local TrainerID = AiArmyRefiller.Internal:GetTrainerID(_ID);
    if TrainerID ~= 0 then
        AiTroopTrainer.Delete(TrainerID);
    end
end

--- Returns the refiller ID by the entity.
--- @param _Entity any ID or Scriptname
--- @return integer ID ID of refiller
function AiArmyRefiller.Get(_Entity)
    return AiArmyRefiller.Internal:GetByEntity(_Entity);
end

--- Checks if the refiller is alive.
--- @param _ID integer ID of refiller
--- @return boolean Alive Refiller is alive
function AiArmyRefiller.IsAlive(_ID)
    if AiArmyRefiller.IsSpawner(_ID) then
        return AiTroopSpawner.IsAlive(AiArmyRefiller.GetSpawnerID(_ID));
    end
    if AiArmyRefiller.IsTrainer(_ID) then
        return AiArmyRefiller.IsAlive(AiArmyRefiller.GetTrainerID(_ID));
    end
    return false;
end

--- Returns the ID of the internal spawner or 0 if not a spawner.
--- @param _ID integer ID of refiller
--- @return integer Spawner ID of spawner
function AiArmyRefiller.GetSpawnerID(_ID)
    return AiArmyRefiller.Internal:GetSpawnerID(_ID);
end

--- Returns the ID of the internal trainer or 0 if not a trainer.
--- @param _ID integer ID of refiller
--- @return integer Trainer ID of trainer
function AiArmyRefiller.GetTrainerID(_ID)
    return AiArmyRefiller.Internal:GetTrainerID(_ID);
end

--- Returns if the refiller is internally a spawner.
--- @param _ID integer ID of refiller
--- @return boolean IsSpawner Refiller is spawner
function AiArmyRefiller.IsSpawner(_ID)
    return AiArmyRefiller.GetSpawnerID(_ID) ~= 0;
end

--- Returns if the refiller is internally a trainer.
--- @param _ID integer ID of refiller
--- @return boolean IsTrainer Refiller is trainer
function AiArmyRefiller.IsTrainer(_ID)
    return AiArmyRefiller.GetTrainerID(_ID) ~= 0;
end

--- Changes the owner of the refiller and all currently attached troops.
--- @param _ID integer ID of refiller
--- @param _PlayerID integer New owner
function AiArmyRefiller.ChangePlayer(_ID, _PlayerID)
    local SpawnerID = AiArmyRefiller.Internal:GetSpawnerID(_ID);
    if SpawnerID ~= 0 then
        AiTroopSpawner.ChangePlayer(SpawnerID, _PlayerID);
    end
    local TrainerID = AiArmyRefiller.Internal:GetTrainerID(_ID);
    if TrainerID ~= 0 then
        AiTroopTrainer.ChangePlayer(TrainerID, _PlayerID);
    end
end

--- Adds a new allowed type to the unit roster.
---
--- Experiance only works for spawners.
--- @param _ID integer   ID of refiller
--- @param _Type integer Type or upgrade cytegory
--- @param _Exp integer  Experience points
function AiArmyRefiller.AddAllowedType(_ID, _Type, _Exp)
    local SpawnerID = AiArmyRefiller.Internal:GetSpawnerID(_ID);
    if SpawnerID ~= 0 then
        AiTroopSpawner.AddAllowedType(SpawnerID, _Type, _Exp);
    end
    local TrainerID = AiArmyRefiller.Internal:GetTrainerID(_ID);
    if TrainerID ~= 0 then
        AiTroopTrainer.AddAllowedType(TrainerID, _Type, _Exp);
    end
end

--- Removes all allowed types from the unit roster.
--- @param _ID integer ID of refiller
function AiArmyRefiller.ClearAllowedTypes(_ID)
    local SpawnerID = AiArmyRefiller.Internal:GetSpawnerID(_ID);
    if SpawnerID ~= 0 then
        AiTroopSpawner.ClearAllowedTypes(SpawnerID);
    end
    local TrainerID = AiArmyRefiller.Internal:GetTrainerID(_ID);
    if TrainerID ~= 0 then
        AiTroopTrainer.ClearAllowedTypes(TrainerID);
    end
end

--- Adds an army to the refiller.
--- @param _ID integer        ID of refiller
--- @param _ArmyID integer    ID of army
function AiArmyRefiller.AddArmy(_ID, _ArmyID)
    local SpawnerID = AiArmyRefiller.Internal:GetSpawnerID(_ID);
    if SpawnerID ~= 0 then
        AiTroopSpawner.AddArmy(SpawnerID, _ArmyID);
    end
    local TrainerID = AiArmyRefiller.Internal:GetTrainerID(_ID);
    if TrainerID ~= 0 then
        AiTroopTrainer.AddArmy(TrainerID, _ArmyID);
    end
end

--- Removes an army from the refiller.
--- @param _ID integer     ID of refiller
--- @param _ArmyID integer ID of army
function AiArmyRefiller.RemoveArmy(_ID, _ArmyID)
    local SpawnerID = AiArmyRefiller.Internal:GetSpawnerID(_ID);
    if SpawnerID ~= 0 then
        AiTroopSpawner.RemoveArmy(SpawnerID, _ArmyID);
    end
    local TrainerID = AiArmyRefiller.Internal:GetTrainerID(_ID);
    if TrainerID ~= 0 then
        AiTroopTrainer.RemoveArmy(TrainerID, _ArmyID);
    end
end

--- Adds a troop to be refilling list.
---
--- When a troop is added to the refiller list it gets new soldiers until it
--- is full. Refilled troops are prioritized before spawning.
---
--- A troop can only be added to a refiller if it's type is supported, meaning
--- inside the list of types.
---
--- @param _ID integer      ID of refiller
--- @param _TroopID integer ID of troop
--- @return boolean Added Troop was added
function AiArmyRefiller.AddTroop(_ID, _TroopID)
    local SpawnerID = AiArmyRefiller.Internal:GetSpawnerID(_ID);
    if SpawnerID ~= 0 then
        return AiTroopSpawner.AddTroop(SpawnerID, _TroopID);
    end
    local TrainerID = AiArmyRefiller.Internal:GetTrainerID(_ID);
    if TrainerID ~= 0 then
        return AiTroopTrainer.AddTroop(TrainerID, _TroopID);
    end
    return false;
end

--- Checks if a troop can be added to a refiller.
--- @param _ID integer      ID of refiller
--- @param _TroopID integer ID of troop
--- @return boolean Addable Troop can be added
function AiArmyRefiller.CanTroopBeAdded(_ID, _TroopID)
    local SpawnerID = AiArmyRefiller.Internal:GetSpawnerID(_ID);
    if SpawnerID ~= 0 then
        return AiTroopSpawner.CanTroopBeAdded(SpawnerID, _TroopID);
    end
    local TrainerID = AiArmyRefiller.Internal:GetTrainerID(_ID);
    if TrainerID ~= 0 then
        return AiTroopTrainer.CanTroopBeAdded(TrainerID, _TroopID);
    end
    return false;
end

--- Removes a troop from the refilling list.
--- @param _ID integer      ID of refiller
--- @param _TroopID integer ID of troop
function AiArmyRefiller.RemoveTroop(_ID, _TroopID)
    local SpawnerID = AiArmyRefiller.Internal:GetSpawnerID(_ID);
    if SpawnerID ~= 0 then
        AiTroopSpawner.RemoveTroop(_ID, _TroopID);
    end
    local TrainerID = AiArmyRefiller.Internal:GetTrainerID(_ID);
    if TrainerID ~= 0 then
        AiTroopTrainer.RemoveTroop(TrainerID, _TroopID);
    end
end

--- Returns the refiller IDs of all mapped spawners and refillers. Rouge ones
--- not known to this facade are not returned.
--- @param _ArmyID integer ID of army
--- @return table IdList List of Spawner IDs
function AiArmyRefiller.GetRefillersOfArmy(_ArmyID)
    return AiArmyRefiller.Internal:GetRefillersOfArmy(_ArmyID);
end

-- -------------------------------------------------------------------------- --
-- Internal

AiArmyRefiller.Internal = AiArmyRefiller.Internal or {
    Data = {
        RefillerIdSequence = 0,
        Refillers = {
            Spawner = {},
            Trainer = {},
        },
    },
}

function AiArmyRefiller.Internal:Install()
    if not self.IsInstalled then
        self.IsInstalled = true;
    end
end

function AiArmyRefiller.Internal:CreateSpawner(_Data)
    self:Install();

    self.Data.RefillerIdSequence = self.Data.RefillerIdSequence +1;
    local ID = self.Data.RefillerIdSequence;

    local SpawnerID = AiTroopSpawner.Create(_Data);
    self.Data.Refillers.Spawner[ID] = {SpawnerID};
    return ID;
end

function AiArmyRefiller.Internal:CreateTrainer(_Data)
    self:Install();

    self.Data.RefillerIdSequence = self.Data.RefillerIdSequence +1;
    local ID = self.Data.RefillerIdSequence;

    local TrainerID = AiTroopTrainer.Create(_Data);
    self.Data.Refillers.Trainer[ID] = {TrainerID};
    return ID;
end

function AiArmyRefiller.Internal:GetSpawnerID(_ID)
    if self.Data.Refillers.Spawner[_ID] then
        return self.Data.Refillers.Spawner[_ID][1];
    end
    return 0;
end

function AiArmyRefiller.Internal:GetTrainerID(_ID)
    if self.Data.Refillers.Trainer[_ID] then
        return self.Data.Refillers.Trainer[_ID][1];
    end
    return 0;
end

function AiArmyRefiller.Internal:GetRefillersOfArmy(_ArmyID)
    local RefillerIDs = {};
    local SpawnerIDs = AiTroopSpawner.GetSpawnersOfArmy(_ArmyID);
    for i= table.getn(SpawnerIDs), 1, -1 do
        for k, v in pairs(self.Data.Refillers.Spawner) do
            if v[1] == SpawnerIDs[i] then
                table.insert(RefillerIDs, k);
            end
        end
    end
    local TrainerIDs = AiTroopTrainer.GetTrainersOfArmy(_ArmyID);
    for i= table.getn(TrainerIDs), 1, -1 do
        for k, v in pairs(self.Data.Refillers.Trainer) do
            if v[1] == TrainerIDs[i] then
                table.insert(RefillerIDs, k);
            end
        end
    end
    return RefillerIDs;
end

function AiArmyRefiller.Internal:GetByEntity(_Entity)
    for k, v in pairs(self.Data.Refillers.Spawner) do
        local SpawnerID = AiTroopSpawner.Get(v[1]);
        if SpawnerID ~= 0 and AiTroopSpawner.Get(_Entity) == SpawnerID then
            return k;
        end
    end
    for k, v in pairs(self.Data.Refillers.Trainer) do
        local TrainerID = AiTroopTrainer.Get(v[1]);
        if TrainerID ~= 0 and AiTroopTrainer.Get(_Entity) == TrainerID then
            return k;
        end
    end
    return 0;
end

