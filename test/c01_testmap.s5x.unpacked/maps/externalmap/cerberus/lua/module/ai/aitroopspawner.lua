Lib.Require("comfort/GetDistance");
Lib.Require("module/trigger/Job");
Lib.Register("module/ai/AiTroopSpawner");

---
--- Troop spawner script
---
--- Allows to create spawners that can supply multiple armies with new
--- troops. The unit roster is the same for all armies.
---
--- Version 1.2.0
---

AiTroopSpawner = AiTroopSpawner or {
    RefillDistance = 1500,
    NoEnemyDistance = 3500,
};

AiArmySpawnerData_SpawnerIdToSpawnerInstance = {};

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
function AiTroopSpawner.Create(_Data)
    return AiTroopSpawner.Internal:CreateSpawner(_Data);
end

--- Deletes a spawner.
--- @param _ID integer ID of spawner
function AiTroopSpawner.Delete(_ID)
    AiTroopSpawner.Internal:DeleteSpawner(_ID);
end

--- Returns the spawner ID by the entity.
--- @param _Entity any ID or Scriptname
--- @return integer ID ID of spawner
function AiTroopSpawner.Get(_Entity)
    return AiTroopSpawner.Internal:GetByEntity(_Entity);
end

--- Adds a new allowed type to the unit roster.
--- @param _ID integer   ID of spawner
--- @param _Type integer Type of Leader
--- @param _Exp integer  Experience points
function AiTroopSpawner.AddAllowedType(_ID, _Type, _Exp)
    if AiArmySpawnerData_SpawnerIdToSpawnerInstance[_ID] then
        table.insert(AiArmySpawnerData_SpawnerIdToSpawnerInstance[_ID].AllowedTypes, {_Type, _Exp});
    end
end

--- Removes all allowed types from the unit roster.
--- @param _ID integer ID of spawner
function AiTroopSpawner.ClearAllowedTypes(_ID)
    if AiArmySpawnerData_SpawnerIdToSpawnerInstance[_ID] then
        AiArmySpawnerData_SpawnerIdToSpawnerInstance[_ID].AllowedTypes = {};
    end
end

--- Adds an army to the spawner.
---
--- The player ID of the army must match the player ID of the spawner!
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

--- Checks if a troop can be added to a spawner.
--- @param _ID integer      ID of spawner
--- @param _TroopID integer ID of troop
--- @return boolean Addable Troop can be added
function AiTroopSpawner.CanTroopBeAdded(_ID, _TroopID)
    return AiTroopSpawner.Internal:CanTroopBeAdded(_ID, _TroopID);
end

--- Removes a troop from the refilling list.
--- @param _ID integer      ID of spawner
--- @param _TroopID integer ID of troop
function AiTroopSpawner.RemoveTroop(_ID, _TroopID)
    AiTroopSpawner.Internal:RemoveTroop(_ID, _TroopID);
end

--- Changes the time to the next respawn of the spawner.
--- @param _ID integer   ID of spawner
--- @param _Time integer Time to respawn
function AiTroopSpawner.SetSpawnTime(_ID, _Time)
    assert(_Time > 0, "Time must be larger than 0!");
    if AiArmySpawnerData_SpawnerIdToSpawnerInstance[_ID] then
        AiArmySpawnerData_SpawnerIdToSpawnerInstance[_ID].TimerMax = _Time;
        AiArmySpawnerData_SpawnerIdToSpawnerInstance[_ID].Timer = _Time;
    end
end

--- Changes the maximum troops a spawner can spawn per cycle.
--- @param _ID integer     ID of spawner
--- @param _Amount integer Maximum quantity
function AiTroopSpawner.SetSpawnAmount(_ID, _Amount)
    assert(_Amount > 0, "Amount must be larger than 0!");
    if AiArmySpawnerData_SpawnerIdToSpawnerInstance[_ID] then
        AiArmySpawnerData_SpawnerIdToSpawnerInstance[_ID].MaxSpawn = _Amount;
    end
end

--- All troops that are currently refilling are removed from the spawner.
--- @param _ID integer ID of spawner
--- @return table List of troops
function AiTroopSpawner.DraftTroops(_ID)
    local Troops = {};
    if AiArmySpawnerData_SpawnerIdToSpawnerInstance[_ID] then
        for i= table.getn(AiArmySpawnerData_SpawnerIdToSpawnerInstance[_ID].Refilling), 1, -1 do
            local ID = table.remove(AiArmySpawnerData_SpawnerIdToSpawnerInstance[_ID].Refilling, i);
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

--- Changes the owner of the spawner.
--- @param _ID integer ID of spawner
--- @param _PlayerID integer New owner
function AiTroopSpawner.ChangePlayer(_ID, _PlayerID)
    return AiTroopSpawner.Internal:ChangePlayer(_ID, _PlayerID);
end

--- Checks if the spawner is alive.
--- @param _ID integer ID of spawner
--- @return boolean Alive Spawner is alive
function AiTroopSpawner.IsAlive(_ID)
    if AiArmySpawnerData_SpawnerIdToSpawnerInstance[_ID] then
        return IsExisting(AiArmySpawnerData_SpawnerIdToSpawnerInstance[_ID].ScriptName);
    end
    return false;
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
            for i= table.getn(AiTroopSpawner.Internal.Data.Spawners), 1, -1 do
                AiTroopSpawner.Internal:ControllSpawner(i);
            end
        end);
    end
end

function AiTroopSpawner.Internal:CreateSpawner(_Data)
    self:Install();
    self.Data.SpawnerIdSequence = self.Data.SpawnerIdSequence +1;
    local ID = self.Data.SpawnerIdSequence;

    local AllowedTypes = _Data.AllowedTypes or {};
    for i= 1, table.getn(AllowedTypes) do
        if type(AllowedTypes[i]) ~= "table" then
            AllowedTypes[i] = {AllowedTypes[i], 0};
        end
    end

    local Spawner = {
        ID           = ID,
        ScriptName   = _Data.ScriptName,
        SpawnPoint   = _Data.SpawnPoint,
        MaxSpawn     = _Data.SpawnAmount or 1,
        Timer        = _Data.SpawnTimer or 60,
        TimerMax     = _Data.SpawnTimer or 60,
        AllowedTypes = AllowedTypes,
        Refilling    = {},
        Armies       = {},
    }
    if _Data.Endlessly then
        Spawner.Endlessly = _Data.Endlessly == true;
    end
    if _Data.Sequentially then
        Spawner.Sequentially = _Data.Sequentially == true;
    end
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
    AiArmySpawnerData_SpawnerIdToSpawnerInstance[ID] = Spawner;
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

function AiTroopSpawner.Internal:GetByEntity(_Entity)
    local EntityID = GetID(_Entity);
    for i= table.getn(self.Data.Spawners), 1, -1 do
        if GetID(self.Data.Spawners[i].ScriptName) == EntityID then
            return self.Data.Spawners[i].ID;
        end
    end
    return 0;
end

function AiTroopSpawner.Internal:ChangePlayer(_ID, _PlayerID)
    local Spawner = AiArmySpawnerData_SpawnerIdToSpawnerInstance[_ID];
    if Spawner then
        local Refilling = {};
        for k,v in pairs(Spawner.Refilling) do
            table.insert(Refilling, ChangePlayer(v, _PlayerID));
        end
        Spawner.Refilling = Refilling;

        ChangePlayer(Spawner.ScriptName, _PlayerID);
    end
end

function AiTroopSpawner.Internal:AddArmy(_ID, _ArmyID)
    if AiArmySpawnerData_SpawnerIdToSpawnerInstance[_ID] then
        local ScriptName = AiArmySpawnerData_SpawnerIdToSpawnerInstance[_ID].ScriptName;
        local SpawnerPlayerID = GetPlayer(ScriptName);
        local ArmyPlayerID = AiArmy.GetPlayer(_ArmyID);
        assert(SpawnerPlayerID == ArmyPlayerID, "Spawner player ID must match army player ID!");
        self:RemoveArmy(_ID, _ArmyID);
        table.insert(AiArmySpawnerData_SpawnerIdToSpawnerInstance[_ID].Armies, _ArmyID);
    end
end

function AiTroopSpawner.Internal:RemoveArmy(_ID, _ArmyID)
    if AiArmySpawnerData_SpawnerIdToSpawnerInstance[_ID] then
        for i= table.getn(AiArmySpawnerData_SpawnerIdToSpawnerInstance[_ID].Armies), 1, -1 do
            if AiArmySpawnerData_SpawnerIdToSpawnerInstance[_ID].Armies[i] == _ArmyID then
                table.remove(AiArmySpawnerData_SpawnerIdToSpawnerInstance[_ID].Armies, i);
            end
        end
    end
end

function AiTroopSpawner.Internal:AddTroop(_ID, _TroopID)
    if self:CanTroopBeAdded(_ID, _TroopID) then
        self:RemoveTroop(_ID, _TroopID);
        table.insert(AiArmySpawnerData_SpawnerIdToSpawnerInstance[_ID].Refilling, _TroopID);
        return true;
    end
    return false;
end

function AiTroopSpawner.Internal:CanTroopBeAdded(_ID, _TroopID)
    if AiArmySpawnerData_SpawnerIdToSpawnerInstance[_ID] then
        local Type = Logic.GetEntityType(_TroopID);
        for i= 1, table.getn(AiArmySpawnerData_SpawnerIdToSpawnerInstance[_ID].AllowedTypes) do
            if Type == AiArmySpawnerData_SpawnerIdToSpawnerInstance[_ID].AllowedTypes[i][1] then
                return true;
            end
        end
    end
    return false;
end

function AiTroopSpawner.Internal:RemoveTroop(_ID, _TroopID)
    if AiArmySpawnerData_SpawnerIdToSpawnerInstance[_ID] then
        for i= table.getn(AiArmySpawnerData_SpawnerIdToSpawnerInstance[_ID].Refilling), 1, -1 do
            if AiArmySpawnerData_SpawnerIdToSpawnerInstance[_ID].Refilling[i] == _TroopID then
                table.remove(AiArmySpawnerData_SpawnerIdToSpawnerInstance[_ID].Refilling, i);
            end
        end
    end
end

function AiTroopSpawner.Internal:ControllSpawner(_Index)
    -- Control spawner
    local Spawner = self.Data.Spawners[_Index];
    if Spawner then
        if IsExisting(Spawner.ScriptName) then
            -- Clear invalid armies
            for i= table.getn(Spawner.Armies), 1, -1 do
                if not AiArmy.Get(Spawner.Armies[i]) then
                    table.remove(Spawner.Armies, i);
                end
            end

            -- Control refilling troops
            self:ControlTroopRefilling(_Index);

            -- Assign refilled troop
            -- Adds 1 refilled troop per second to the weakest army if possible
            local ArmyID = self:GetArmyAwardedRespawn(_Index);
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

            -- Control respawn
            -- Respawns n troops per cycle or adds an existing troop
            ArmyID = self:GetArmyAwardedRespawn(_Index);
            if ArmyID > 0 then
                local DoSpawn = true;
                if AiArmy.IsInitallyFilled(ArmyID) == true then
                    DoSpawn = self:Tick(_Index) == true;
                end
                if DoSpawn then
                    for i= 1, Spawner.MaxSpawn do
                        if AiArmy.IsCommandOfTypeActive(ArmyID, AiArmyCommand.Refill)
                        or AiArmy.IsArmyNear(ArmyID, AiArmy.GetHomePosition(ArmyID), 1500) then
                            local Types = AiArmy.GetAllowedTypes(ArmyID);
                            local ID = self:Spawn(_Index, ArmyID, Types);
                            if ID > 0 then
                                AiArmy.AddTroop(ArmyID, ID, true);
                            end
                        end
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
            local SpawnPos = GetPosition(Spawner.SpawnPoint);
            if GetDistance(TroopID, SpawnPos) > AiTroopSpawner.RefillDistance then
                local Task = Logic.GetCurrentTaskList(TroopID);
                if (not Task or not string.find(Task, "WALK")) then
                    Logic.MoveSettler(TroopID, SpawnPos.X, SpawnPos.Y);
                end
            else
                local MaxAmount = Logic.LeaderGetMaxNumberOfSoldiers(TroopID);
                local CurAmount = Logic.LeaderGetNumberOfSoldiers(TroopID);
                if MaxAmount > CurAmount and not IsFighting(TroopID) and IsValidEntity(TroopID) then
                    Tools.CreateSoldiersForLeader(TroopID, 1);
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

function AiTroopSpawner.Internal:Spawn(_Index, _ArmyID, _RequestedTypes)
    assert(table.getn(_RequestedTypes) > 0);
    local TroopID = 0;
    local PlayerID = AiArmy.GetPlayer(_ArmyID);
    if PlayerID ~= 0 then
        local AllowedTypes = self.Data.Spawners[_Index].AllowedTypes;
        -- Check can spawn type
        local HasAnyType = false;
        for i= 1, table.getn(_RequestedTypes) do
            for j= 1, table.getn(AllowedTypes) do
                if _RequestedTypes[i][1] == AllowedTypes[j][1] then
                    HasAnyType = true;
                    break;
                end
            end
        end
        -- Spawn type
        if HasAnyType then
            TroopID = self:GetTroop(_Index, PlayerID, _RequestedTypes);
            local TypeAmount = table.getn(AllowedTypes);
            if TroopID == 0 and TypeAmount > 0 then
                local MaximumLeader = AiArmy.GetMaxNumberOfLeader(_ArmyID);
                local CurrentLeader = AiArmy.GetNumberOfLeader(_ArmyID);
                if CurrentLeader < MaximumLeader then
                    local TroopIndex = 0;
                    if self.Data.Spawners[_Index].Sequentially then
                        while TroopIndex == 0 do
                            self.Data.Spawners[_Index].AllowedTypes.Index = AllowedTypes.Index + 1
                            TroopIndex = AllowedTypes.Index;
                            if not AllowedTypes[AllowedTypes.Index] then
                                if self.Data.Spawners[_Index].Endlessly then
                                    self.Data.Spawners[_Index].AllowedTypes.Index = 0;
                                    TroopIndex = 0;
                                else
                                    TroopIndex = 0;
                                    break;
                                end
                            end
                            if _RequestedTypes[1] then
                                local TypeFound = false;
                                for i= 1, table.getn(_RequestedTypes) do
                                    local Type = self.Data.Spawners[_Index].AllowedTypes[AllowedTypes.Index];
                                    if Type and _RequestedTypes[i][1] == Type[1] then
                                        TypeFound = true;
                                    end
                                end
                                if TypeFound then
                                    break;
                                end
                                TroopIndex = 0;
                            end
                        end
                    else
                        while TroopIndex == 0 do
                            TroopIndex = math.random(1, TypeAmount);
                            local Type = self.Data.Spawners[_Index].AllowedTypes[TroopIndex][1];
                            local TypeFound = false;
                            for i= 1, table.getn(_RequestedTypes) do
                                if _RequestedTypes[i][1] == Type then
                                    TypeFound = true;
                                end
                            end
                            if TypeFound then
                                break;
                            end
                            TroopIndex = 0;
                        end
                    end
                    if TroopIndex > 0 then
                        TroopID = self:CreateTroop(_Index, PlayerID, TroopIndex);
                    end
                end
            end
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

function AiTroopSpawner.Internal:IsRefilling(_Index)
    return self.Data.Spawners[_Index].Refilling[1] ~= nil;
end

function AiTroopSpawner.Internal:GetTroop(_Index, _PlayerID, _RequestedTypes)
    for i= table.getn(self.Data.Spawners[_Index].Refilling), 1, -1 do
        local TroopID = self.Data.Spawners[_Index].Refilling[i];
        local Type = Logic.GetEntityType(TroopID);
        if not _RequestedTypes[1] or self:IsInTroopTable(Type, _RequestedTypes) then
            if Logic.EntityGetPlayer(TroopID) == _PlayerID then
                local MaxAmount = Logic.LeaderGetMaxNumberOfSoldiers(TroopID);
                local CurAmount = Logic.LeaderGetNumberOfSoldiers(TroopID);
                if MaxAmount == CurAmount then
                    table.remove(self.Data.Spawners[_Index].Refilling, i);
                    return TroopID;
                end
            end
        end
    end
    if self.Data.Spawners[_Index].Refilling[1] then
        return -1;
    end
    return 0;
end

function AiTroopSpawner.Internal:IsInTroopTable(_Type, _RequestedTypes)
    local RequestedTypes = CopyTable(_RequestedTypes);
    for i= table.getn(RequestedTypes), 1, -1 do
        if RequestedTypes[i][1] == _Type then
            return true;
        end
    end
    return false;
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

