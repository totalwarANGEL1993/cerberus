Lib.Require("comfort/AreEnemiesInArea");
Lib.Require("comfort/GetDistance");
Lib.Require("module/trigger/Job");
Lib.Require("module/ai/AiArmy");
Lib.Register("module/ai/AiTroopSpawner");

---
--- Troop spawner script
---
--- Allows to create spawners that can supply multiple armies with new
--- troops. The unit roster is the same for all armies.
---
--- @author totalwarANGEL
--- @version 0.0.1 BETA
---

AiTroopSpawner = AiTroopSpawner or {
    RefillDistance = 1500,
    NoEnemyDistance = 3500,
};

-- -------------------------------------------------------------------------- --
-- API

--- Creates a new spawner.
---
--- Possible fields for definition:
--- * ScriptName   (Required) Scriptname of spawner
--- * SpawnPoint   (Required) Scriptname of position
--- * SpawnAmount  (Optional) Max amount to spawn per cycle
--- * SpawnTimer   (Optional) Time between spawn cycles
--- * AllowedTypes (Optional) List of types {Type, Experience}
---
--- @param _Data table Troop Spawner definition
--- @return integer ID ID of spawner
function AiTroopSpawner.Create(_Data)
    return AiTroopSpawner.Internal:CreateSpawner(_Data);
end

--- Deletes a spawner.
--- @param _ID integer ID of spawner
function AiTroopSpawner.Delete(_ID)
    AiTroopSpawner.Internal:DeleteSpawner(_ID);
end

--- Adds a new allowed type to the unit roster.
--- @param _ID integer   ID of spawner
--- @param _Type integer Type of Leader
--- @param _Exp integer  Experience points
function AiTroopSpawner.AddAllowedTypes(_ID, _Type, _Exp)
    if AiTroopSpawner.Internal.Data.Spawners[_ID] then
        table.insert(AiTroopSpawner.Internal.Data.Spawners[_ID].AllowedTypes, {_Type, _Exp});
    end
end

--- Removes all allowed types from the unit roster.
--- @param _ID integer ID of spawner
function AiTroopSpawner.ClearAllowedTypes(_ID)
    if AiTroopSpawner.Internal.Data.Spawners[_ID] then
        AiTroopSpawner.Internal.Data.Spawners[_ID].AllowedTypes = {};
    end
end

--- Adds an army to the spawner.
--- @param _ID integer        ID of spawner
--- @param _ArmyID integer    ID of army
function AiTroopSpawner.AddArmy(_ID, _ArmyID)
    AiTroopSpawner.Internal:AddArmy(_ID, _ArmyID);
end

--- Removes an army from the spawner.
--- @param _ID integer     ID of spawner
--- @param _ArmyID integer ID of army
function AiTroopSpawner.RemoveArmy(_ID, _ArmyID)
    AiTroopSpawner.Internal:RemoveArmy(_ID, _ArmyID);
end

--- Adds a troop to be refilling list.
---
--- When a troop is added to the refiller list it gets new soldiers until it
--- is full. Refilled troops are prioritized before spawning.
---
--- A troop can only be added to a respawner if it's type is supported, meaning
--- inside the list of types.
---
--- @param _ID integer      ID of spawner
--- @param _TroopID integer ID of troop
--- @return boolean Added Troop was added
function AiTroopSpawner.AddTroop(_ID, _TroopID)
    return AiTroopSpawner.Internal:AddTroop(_ID, _TroopID);
end

--- Removes a troop from the refilling list.
--- @param _ID integer      ID of spawner
--- @param _TroopID integer ID of troop
function AiTroopSpawner.RemoveTroop(_ID, _TroopID)
    AiTroopSpawner.Internal:RemoveTroop(_ID, _TroopID);
end

--- All troops that are currently refilling are removed from the spawner.
--- @param _ID integer ID of spawner
--- @return table List of troops
function AiTroopSpawner.DraftTroops(_ID)
    local Troops = {};
    if AiTroopSpawner.Internal.Data.Spawners[_ID] then
        for i= table.getn(AiTroopSpawner.Internal.Data.Spawners[_ID].Refilling), 1, -1 do
            local ID = table.remove(AiTroopSpawner.Internal.Data.Spawners[_ID].Refilling, i);
            table.insert(Troops, ID);
        end
    end
    return Troops;
end

--- Returns all spawners the army is connected to.
--- @param _ArmyID integer ID of army
--- @return table IdList List of Spawner IDs
function AiTroopSpawner.GetSpawnersOfArmy(_ArmyID)
    local SpawnerIDs = {};
    for i= 1, table.getn(AiTroopSpawner.Internal.Data.Spawners) do
        local Spawner = AiTroopSpawner.Internal.Data.Spawners[i];
        for j= 1, table.getn(Spawner.Armies) do
            if Spawner.Armies[j] == _ArmyID then
                table.insert(SpawnerIDs, Spawner.ID);
            end
        end
    end
    return SpawnerIDs;
end

-- -------------------------------------------------------------------------- --
-- Internal

AiTroopSpawner.Internal = AiTroopSpawner.Internal or {
    Data = {
        SpawnerIdSequence = 0,
        Spawners = {},
    },
}

function AiTroopSpawner.Internal:Install()
    if not self.IsInstalled then
        self.IsInstalled = true;

        self.ControllerJobID = Job.Second(function()
            for i= table.getn(self.Data.Spawners), 1, -1 do
                self:ControllSpawner(i);
            end
        end);
    end
end

function AiTroopSpawner.Internal:CreateSpawner(_Data)
    self:Install();
    self.Data.SpawnerIdSequence = self.Data.SpawnerIdSequence +1;
    local ID = self.Data.SpawnerIdSequence;

    local Spawner = {
        ID           = ID,
        ScriptName   = _Data.ScriptName,
        SpawnPoint   = _Data.SpawnPoint,
        MaxSpawn     = _Data.SpawnAmount or 1,
        Timer        = _Data.SpawnTimer or 60,
        TimerMax     = _Data.SpawnTimer or 60,
        AllowedTypes = _Data.AllowedTypes or {},
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
    table.insert(self.Data.Spawners, Spawner);
    return ID;
end

function AiTroopSpawner.Internal:DeleteSpawner(_ID)
    for i= table.getn(self.Data.Spawners), 1, -1 do
        if self.Data.Spawners[i].ID == _ID then
            table.remove(self.Data.Spawners, i);
        end
    end
end

function AiTroopSpawner.Internal:AddArmy(_Index, _ArmyID)
    if self.Data.Spawners[_Index] then
        self:RemoveArmy(_Index, _ArmyID);
        table.insert(self.Data.Spawners[_Index].Armies, _ArmyID);
    end
end

function AiTroopSpawner.Internal:RemoveArmy(_Index, _ArmyID)
    if self.Data.Spawners[_Index] then
        for i= table.getn(self.Data.Spawners[_Index].Armies), 1, -1 do
            if self.Data.Spawners[_Index].Armies[i] == _ArmyID then
                table.remove(self.Data.Spawners[_Index].Armies, i);
            end
        end
    end
end

function AiTroopSpawner.Internal:AddTroop(_Index, _TroopID)
    if self.Data.Spawners[_Index] then
        local Type = Logic.GetEntityType(_TroopID);
        for i= 1, table.getn(self.Data.Spawners[_Index].AllowedTypes) do
            if Type == self.Data.Spawners[_Index].AllowedTypes[i] then
                self:RemoveTroop(_Index, _TroopID);
                table.insert(self.Data.Spawners[_Index].Refilling, _TroopID);
                return true;
            end
        end
    end
    return false;
end

function AiTroopSpawner.Internal:RemoveTroop(_Index, _TroopID)
    if self.Data.Spawners[_Index] then
        for i= table.getn(self.Data.Spawners[_Index].Refilling), 1, -1 do
            if self.Data.Spawners[_Index].Refilling[i] == _TroopID then
                table.remove(self.Data.Spawners[_Index].Refilling, i);
            end
        end
    end
end

function AiTroopSpawner.Internal:ControllSpawner(_Index)
    local Spawner = self.Data.Spawners[_Index];
    if Spawner then
        if IsExisting(Spawner.ScriptName) then
            -- Clear invalid armies
            for i= table.getn(self.Data.Spawners[_Index].Armies), 1, -1 do
                if not AiArmy.Get(self.Data.Spawners[_Index].Armies[i]) then
                    table.remove(self.Data.Spawners[_Index].Armies, i);
                end
            end
            -- Assign refilled troop
            -- Adds 1 refilled troop per second to the weakest army if possible
            local ArmyID = self:GetArmyAwardedRespawn(_Index);
            local PlayerID = AiArmy.GetPlayer(ArmyID);
            if PlayerID ~= 0 then
                local TroopID = self:GetTroop(_Index, PlayerID);
                if TroopID ~= 0 then
                    AiArmy.AddTroop(ArmyID, TroopID, true);
                end
            end
            -- Control respawn
            -- Respawns 1 troop per cycle or adds an existing troop
            if self:Tick(_Index) then
                for i= 1, Spawner.MaxSpawn do
                    ArmyID = self:GetArmyAwardedRespawn(_Index);
                    if ArmyID > 0 then
                        local ID = self:Spawn(_Index, ArmyID);
                        AiArmy.AddTroop(ArmyID, ID, true);
                    end
                end
            end
        end
    end
end

function AiTroopSpawner.Internal:ControlTroopRefilling(_Index)
    local Spawner = self.Data.Spawners[_Index];
    for i= table.getn(Spawner.Refilling), 1, -1 do
        local TroopID = Spawner.Refilling[i];
        if not IsExisting(Spawner.Refilling[i]) then
            table.remove(self.Data.Spawners[_Index].Refilling, i);
        else
            local PlayerID = Logic.EntityGetPlayer(TroopID);
            local SpawnPos = GetPosition(Spawner.SpawnPoint);
            if GetDistance(TroopID, SpawnPos) > AiTroopSpawner.RefillDistance then
                Logic.MoveSettler(TroopID, SpawnPos.X, SpawnPos.Y);
            else
                if not AreEnemiesInArea(Logic.EntityGetPlayer(TroopID), SpawnPos, AiTroopSpawner.NoEnemyDistance) then
                    local MaxAmount = Logic.LeaderGetMaxNumberOfSoldiers(TroopID);
                    local CurAmount = Logic.LeaderGetNumberOfSoldiers(TroopID);
                    if MaxAmount > CurAmount then
                        local SoldierType = Logic.LeaderGetSoldiersType(ID);
                        Logic.CreateEntity(SoldierType, SpawnPos.X, SpawnPos.Y, 0, PlayerID);
                        Tools.AttachSoldiersToLeader(ID, 1);
                    end
                end
            end
        end
    end
end

function AiTroopSpawner.Internal:Tick(_Index)
    local Spawn = self.Data.Spawners[_Index];
    self.Data.Spawners[_Index].Timer = Spawn.Timer -1;
    if Spawn.Timer < 0 then
        self.Data.Spawners[_Index].Timer = Spawn.TimerMax;
        return true;
    end
    return false;
end

function AiTroopSpawner.Internal:Spawn(_Index, _ArmyID)
    local TroopID = 0;
    local PlayerID = AiArmy.GetPlayer(_ArmyID);
    if PlayerID ~= 0 then
        TroopID = self:GetTroop(_Index, PlayerID);
        local TypeAmount = table.getn(self.Data.Spawners[_Index].AllowedTypes);
        if TroopID == 0 and TypeAmount > 0 then
            TroopID = self:CreateTroop(_Index, PlayerID, math.random(1, TypeAmount));
        end
    end
    return TroopID;
end

function AiTroopSpawner.Internal:CreateTroop(_Index, _PlayerID, _Selected)
    local Position = GetPosition(self.Data.Spawners[_Index].SpawnPoint);
    local TypeData = self.Data.Spawners[_Index].AllowedTypes[_Selected];
    local TroopID  = AI.Entity_CreateFormation(_PlayerID, TypeData[1], 0, 0, Position.X, Position.Y, 0, 0, TypeData[2] or 0, 0);
    if TroopID ~= 0 then
        local MaxAmount = Logic.LeaderGetMaxNumberOfSoldiers(TroopID);
        local CurAmount = Logic.LeaderGetNumberOfSoldiers(TroopID);
        for i= 1, math.min(16, MaxAmount - CurAmount) do
            Tools.CreateSoldiersForLeader(TroopID, 1);
        end
    end
    return TroopID;
end

function AiTroopSpawner.Internal:GetTroop(_Index, _PlayerID)
    for i= table.getn(self.Data.Spawners[_Index].Refilling), 1, -1 do
        local TroopID = self.Data.Spawners[_Index].Refilling[i];
        if Logic.EntityGetPlayer(TroopID) == _PlayerID then
            local MaxAmount = Logic.LeaderGetMaxNumberOfSoldiers(TroopID);
            local CurAmount = Logic.LeaderGetNumberOfSoldiers(TroopID);
            if MaxAmount == CurAmount then
                table.remove(self.Data.Spawners[_Index].Refilling, i);
                return TroopID;
            end
        end
    end
    return 0;
end

-- Returns the army attached to the spawner with the least amount of troops.
function AiTroopSpawner.Internal:GetArmyAwardedRespawn(_Index)
    local LastArmyID = 0;
    local LastStrength = 999;
    local Spawner = self.Data.Spawners[_Index];
    if Spawner then
        if IsExisting(Spawner.ScriptName) then
            for i= table.getn(Spawner.Armies), 1, -1 do
                local ArmyID = Spawner.Armies[i];
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

