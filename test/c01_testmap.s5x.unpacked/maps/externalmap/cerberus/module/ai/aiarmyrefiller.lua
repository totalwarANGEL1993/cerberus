Lib.Require("module/ai/AiArmyRefiller");
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
--- * AllowedTypes (Optional) List of types {Type, Experience}
---
--- @param _Data table Troop Spawner definition
--- @return integer ID ID of spawner
function AiArmyRefiller.CreateSpawner(_Data)
    return AiArmyRefiller.Internal:CreateSpawner(_Data);
end

--- Creates a new trainer.
---
--- Possible fields for definition:
--- * ScriptName   (Required) Scriptname of spawner
--- * SpawnPoint   (Optional) Scriptname of position
--- * AllowedTypes (Optional) List of upgrade categories
---
--- @param _Data table Troop Trainer definition
--- @return integer ID ID of trainer
function AiArmyRefiller.CreateTrainer(_Data)
    return AiArmyRefiller.Internal:CreateTrainer(_Data);
end

--- Deletes a refiller.
--- @param _ID integer ID of refiller
function AiTroopSpawner.DeleteRefiller(_ID)
    local SpawnerID = AiArmyRefiller.Internal:GetSpawnerID(_ID);
    if SpawnerID ~= 0 then
        AiTroopSpawner.Delete(SpawnerID);
    end
    local TrainerID = AiArmyRefiller.Internal:GetTrainerID(_ID);
    if TrainerID ~= 0 then
        AiTroopTrainer.Delete(TrainerID);
    end
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
    return AiArmyRefiller.GetInternalSpawnerID(_ID) ~= 0;
end

--- Returns if the refiller is internally a trainer.
--- @param _ID integer ID of refiller
--- @return boolean IsTrainer Refiller is trainer
function AiArmyRefiller.IsTrainer(_ID)
    return AiArmyRefiller.GetInternalTrainerID(_ID) ~= 0;
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
        AiTroopSpawner.AddAllowedTypes(SpawnerID, _Type, _Exp);
    end
    local TrainerID = AiArmyRefiller.Internal:GetTrainerID(_ID);
    if TrainerID ~= 0 then
        AiTroopTrainer.AddAllowedTypes(TrainerID, _Type, _Exp);
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

    self.Data.SpawnerIdSequence = self.Data.SpawnerIdSequence +1;
    local ID = self.Data.SpawnerIdSequence;

    local SpawnerID = AiTroopSpawner.Create(_Data);
    self.Data.Refillers.Spawner[ID] = {SpawnerID};
    return ID;
end

function AiArmyRefiller.Internal:CreateTrainer(_Data)
    self:Install();

    self.Data.SpawnerIdSequence = self.Data.SpawnerIdSequence +1;
    local ID = self.Data.SpawnerIdSequence;

    local TrainerID = AiTroopTrainer.Create(_Data);
    self.Data.Refillers.Trainer[ID] = {TrainerID};
    return ID;
end

function AiArmyRefiller.Internal:GetSpawnerID(_ID)
    if self.Data.Refillers.Spawner[_ID] then
        return self.Data.Refillers.Spawner[_ID];
    end
    return 0;
end

function AiArmyRefiller.Internal:GetTrainerID(_ID)
    if self.Data.Refillers.Trainer[_ID] then
        return self.Data.Refillers.Trainer[_ID];
    end
    return 0;
end

