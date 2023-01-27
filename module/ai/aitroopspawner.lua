Lib.Require("comfort/AreEnemiesInArea");
Lib.Require("comfort/GetDistance");
Lib.Require("comfort/StartInlineTrigger");
Lib.Require("module/ai/AiArmy");
Lib.Register("module/ai/AiTroopSpawner");

---
--- Troop spawner script
---
--- Allows to create spawners that can supply multiple armies with their
--- troop. The unit roster is the same for all armies.
---
--- @author totalwarANGEL
--- @version 0.0.1 BETA
---

AiTroopSpawner = AiTroopSpawner or {};

-- -------------------------------------------------------------------------- --
-- API

--- Creates a new spawner.
---
--- Possible fields for definition:
--- * ScriptName   (Required) Scriptname of spawner
--- * SpawnPoint   (Required) Scriptname of position
--- * MaxSpawn     (Optional) Max amount to spawn per cycle
--- * AllowedTypes (Optional) List of types {Type, Experience}
---
--- @param _Data table Troop Spawner definition
--- @return number ID ID of spawner
function AiTroopSpawner.Create(_Data)
    return AiTroopSpawner.Internal:CreateSpawner(_Data);
end

--- Deletes a spawner.
--- @param _ID number ID of spawner
function AiTroopSpawner.Delete(_ID)
    AiTroopSpawner.Internal:DeleteSpawner(_ID)
end

--- Adds a new allowed type to the unit roster.
--- @param _ID number   ID of spawner
--- @param _Type number Type of Leader
--- @param _Exp number  Experience points
function AiTroopSpawner.AddAllowedTypes(_ID, _Type, _Exp)
    if AiTroopSpawner.Internal.Spawner[_ID] then
        table.insert(AiTroopSpawner.Internal.Spawner[_ID].AllowedTypes, {_Type, _Exp});
    end
end

--- Removes all allowed types from the unit roster.
--- @param _ID number ID of spawner
function AiTroopSpawner.ClearAllowedTypes(_ID)
    if AiTroopSpawner.Internal.Spawner[_ID] then
        AiTroopSpawner.Internal.Spawner[_ID].AllowedTypes = {};
    end
end

--- Adds an army to the spawner.
--- @param _ID number        ID of spawner
--- @param _ArmyID number    ID of army
--- @param _SpawnTime number Respawntime in seconds
function AiTroopSpawner.AddArmy(_ID, _ArmyID, _SpawnTime)
    AiTroopSpawner.Internal:AddArmy(_ID, _ArmyID, _SpawnTime);
end

--- Removes an army from the spawner.
--- @param _ID number     ID of spawner
--- @param _ArmyID number 
function AiTroopSpawner.RemoveArmy(_ID, _ArmyID)
    AiTroopSpawner.Internal:RemoveArmy(_ID, _ArmyID);
end

--- Adds a troop to be refilling list.
---
--- When a troop is added to the refiller list it gets new soldiers until it
--- is full. Refilled troops are prioritized before spawning.
---
--- @param _ID number ID of spawner
--- @param _TroopID number
function AiTroopSpawner.AddTroop(_ID, _TroopID)
    AiTroopSpawner.Internal:AddTroop(_ID, _TroopID);
end

--- Removes a troop from the refilling list.
--- @param _ID number ID of spawner
--- @param _TroopID number
function AiTroopSpawner.RemoveTroop(_ID, _TroopID)
    AiTroopSpawner.Internal:RemoveTroop(_ID, _TroopID);
end

--- All troops that are currently refilling are removed from the spawner.
--- @param _ID number ID of spawner
--- @return table List of troops
function AiTroopSpawner.DraftTroops(_ID)
    local Troops = {};
    if AiTroopSpawner.Internal.Spawners[_ID] then
        for i= table.getn(AiTroopSpawner.Internal.Spawners[_ID].Refilling), 1, -1 do
            local ID = table.remove(AiTroopSpawner.Internal.Spawner[_ID].Refilling, i);
            table.insert(Troops, ID);
        end
    end
    return Troops;
end

-- -------------------------------------------------------------------------- --
-- Internal

AiTroopSpawner.Internal = AiTroopSpawner.Internal or {
    Data = {
        SpawnerIdSequence = 0,
    },
    Spawners = {},
}

function AiTroopSpawner.Internal:Install()
    if not self.IsInstalled then
        self.IsInstalled = true;

        self.ControllerJobID = StartSimpleSecondsTrigger(function()
            for i= 1, table.getn(AiTroopSpawner.Internal.Spawners) do
                AiTroopSpawner.Internal:ControllSpawner(i);
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
        MaxSpawn     = _Data.MaxSpawnAmount or 1,
        AllowedTypes = _Data.AllowedTypes or {},
        Refilling    = {},
        Armies       = {},
    }
    Spawner.AllowedTypes.Index = 0;

    table.insert(AiTroopSpawner.Internal.Spawners, Spawner);
    return ID;
end

function AiTroopSpawner.Internal:DeleteSpawner(_ID)
    for i= table.getn(AiTroopSpawner.Internal.Spawner), 1, -1 do
        if AiTroopSpawner.Internal.Spawner[i].ID == _ID then
            table.remove(AiTroopSpawner.Internal.Spawner, i);
        end
    end
end

function AiTroopSpawner.Internal:AddArmy(_Index, _ArmyID, _SpawnTime)
    if AiTroopSpawner.Internal.Spawners[_Index] then
        table.insert(AiTroopSpawner.Internal.Spawners[_Index].Armies, {
            ID       = _ArmyID,
            TimerMax = _SpawnTime,
            Timer    = _SpawnTime
        });
    end
end

function AiTroopSpawner.Internal:RemoveArmy(_Index, _ArmyID)
    if AiTroopSpawner.Internal.Spawners[_Index] then
        for i= table.getn(AiTroopSpawner.Internal.Spawners[_Index].Armies), 1, -1 do
            if AiTroopSpawner.Internal.Spawners[_Index].Armies[i].ID == _ArmyID then
                table.remove(AiTroopSpawner.Internal.Spawner[_Index].Armies, i);
            end
        end
    end
end

function AiTroopSpawner.Internal:AddTroop(_Index, _TroopID)
    if AiTroopSpawner.Internal.Spawners[_Index] then
        table.insert(AiTroopSpawner.Internal.Spawners[_Index].Refilling, _TroopID);
    end
end

function AiTroopSpawner.Internal:RemoveTroop(_Index, _TroopID)
    if AiTroopSpawner.Internal.Spawners[_Index] then
        for i= table.getn(AiTroopSpawner.Internal.Spawners[_Index].Refilling), 1, -1 do
            if AiTroopSpawner.Internal.Spawners[_Index].Refilling[i] == _TroopID then
                table.remove(AiTroopSpawner.Internal.Spawner[_Index].Refilling, i);
            end
        end
    end
end

function AiTroopSpawner.Internal:ControllSpawner(_Index)
    local Spawner = AiTroopSpawner.Internal.Spawners[_Index];
    if Spawner then
        if IsExisting(Spawner.ScriptName) then
            for i= table.getn(Spawner.Armies), 1, -1 do
                local ArmyID = Spawner.Armies[i].ID;
                if not AiArmy.Get(ArmyID) then
                -- if not AiArmy.IsAlive(ArmyID) then
                    table.remove(AiTroopSpawner.Internal.Spawners[_Index].Armies, i);
                else
                    AiTroopSpawner.Internal:ControlTroopRefilling(_Index);
                    if AiArmy.GetNumberOfLeader(ArmyID) < AiArmy.GetMaxNumberOfLeader(ArmyID) then
                        if AiTroopSpawner.Internal:Tick(_Index, i) then
                            for j= 1, Spawner.MaxSpawn do
                                local ID = self:Spawn(_Index, ArmyID);
                                AiArmy.AddTroop(ArmyID, ID, true);
                            end
                        end
                    end
                end
            end
        else
            table.remove(AiTroopSpawner.Internal.Spawners, _Index);
        end
    end
end

function AiTroopSpawner.Internal:ControlTroopRefilling(_Index)
    local Spawner = AiTroopSpawner.Internal.Spawners[_Index];
    for i= table.getn(Spawner.Refilling), 1, -1 do
        local TroopID = Spawner.Refilling[i];
        if not IsExisting(Spawner.Refilling[i]) then
            table.remove(AiTroopSpawner.Internal.Spawners[_Index].Refilling, i);
        else
            local PlayerID = Logic.EntityGetPlayer(TroopID);
            local SpawnPos = GetPosition(Spawner.SpawnPoint);
            if GetDistance(TroopID, SpawnPos) > 1000 then
                Logic.MoveSettler(TroopID, SpawnPos.X, SpawnPos.Y);
            else
                if not AreEnemiesInArea(Logic.EntityGetPlayer(TroopID), SpawnPos, 3500) then
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

function AiTroopSpawner.Internal:Tick(_Index, _Army)
    local ArmySpawn = AiTroopSpawner.Internal.Spawners[_Index].Armies[_Army];
    AiTroopSpawner.Internal.Spawners[_Index].Armies[_Army].Timer = ArmySpawn.Timer -1;
    if ArmySpawn.Timer < 0 then
        AiTroopSpawner.Internal.Spawners[_Index].Armies[_Army].Timer = ArmySpawn.TimerMax;
        return true;
    end
    return false;
end

function AiTroopSpawner.Internal:Spawn(_Index, _ArmyID)
    local TroopID = 0;
    local Army = AiArmy.Get(_ArmyID);
    if Army then
        TroopID = self:GetTroop(_Index, Army.PlayerID);
        local TypeAmount = table.getn(AiTroopSpawner.Internal.Spawners[_Index].AllowedTypes);
        if TroopID == 0 and TypeAmount > 0 then
            TroopID = self:CreateTroop(_Index, Army.PlayerID, math.random(1, TypeAmount));
        end
    end
    return TroopID;
end

function AiTroopSpawner.Internal:CreateTroop(_Index, _PlayerID, _Selected)
    local Position = GetPosition(AiTroopSpawner.Internal.Spawners[_Index].SpawnPoint);
    local TypeData = AiTroopSpawner.Internal.Spawners[_Index].AllowedTypes[_Selected];
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
    for i= table.getn(AiTroopSpawner.Internal.Spawners[_Index].Refilling), 1, -1 do
        local TroopID = AiTroopSpawner.Internal.Spawners[_Index].Refilling[i];
        if Logic.EntityGetPlayer(TroopID) == _PlayerID then
            local MaxAmount = Logic.LeaderGetMaxNumberOfSoldiers(TroopID);
            local CurAmount = Logic.LeaderGetNumberOfSoldiers(TroopID);
            if MaxAmount == CurAmount then
                table.remove(AiTroopSpawner.Internal.Spawners[_Index].Refilling, i);
                return TroopID;
            end
        end
    end
    return 0;
end

