Lib.Require("comfort/AverageAngle");
Lib.Require("comfort/CopyTable");
Lib.Require("comfort/GetConeCenter");
Lib.Require("comfort/GetConeEnd");
Lib.Require("comfort/GetDistance");
Lib.Require("comfort/GetEntityCategoriesAsString");
Lib.Require("comfort/GetGeometricCenter");
Lib.Require("comfort/IsFighting");
Lib.Require("comfort/IsTraining");
Lib.Require("comfort/IsInCone");
Lib.Require("comfort/IsValidEntity");
Lib.Require("comfort/IsValidPosition");
Lib.Require("module/trigger/Job");
Lib.Require("module/ai/AiArmyRefiller");
Lib.Register("module/ai/AiArmy");

---
--- AI army script
---
--- Creates an army that automatically attacks enemies in reach. It also tries
--- to not focus on a single target and makes use of max range attacks..
---
--- Everything else is very similar to what default armies are doing. A higher
--- instance of controller is advised but not explicitly required.
---
--- Version 1.3.2
---

AiArmy = AiArmy or {};

-- -------------------------------------------------------------------------- --
-- API

--- Creates an new army.
--- @param _PlayerID integer   Owner of army
--- @param _Strength integer   Max amount of leaders
--- @param _Position table     Position of army
--- @param _RodeLength integer Radius of action
--- @return integer ID ID of army
function AiArmy.New(_PlayerID, _Strength, _Position, _RodeLength)
    local Army = AiArmy.Internal.Army:New(_PlayerID, _Strength, _Position, _RodeLength);
    AiArmyData_ArmyIdToArmyInstance[Army.ID] = Army;
    return Army.ID;
end

--- Deletes an army.
---
--- Remaining members are not deleted.
---
--- @param _ID integer ID of army
function AiArmy.Delete(_ID)
    if AiArmyData_ArmyIdToArmyInstance[_ID] then
        AiArmyData_ArmyIdToArmyInstance[_ID]:Dispose();
    end
end

--- Returns the army with the ID if any.
--- @param _ID integer ID of army
--- @return table? Army Instance of army
function AiArmy.Get(_ID)
    if AiArmyData_ArmyIdToArmyInstance[_ID] then
        return AiArmyData_ArmyIdToArmyInstance[_ID];
    end
end

--- Changes the owner of the army.
--- @param _ID integer ID of army
--- @param _PlayerID integer New owner
function AiArmy.ChangePlayer(_ID, _PlayerID)
    if AiArmyData_ArmyIdToArmyInstance[_ID] then
        AiArmyData_ArmyIdToArmyInstance[_ID]:ChangePlayer(_PlayerID);
    end
end

--- Returns the owner of the army.
--- @param _ID integer ID of army
--- @return integer PlayerID ID of owner
function AiArmy.GetPlayer(_ID)
    if AiArmyData_ArmyIdToArmyInstance[_ID] then
        return AiArmyData_ArmyIdToArmyInstance[_ID].PlayerID;
    end
    return 0;
end

--- Returns the custom value saved in the army at the key.
--- @param _ID integer ID of army
--- @param _Key string Name of key
--- @return any Value Value of key
function AiArmy.GetKey(_ID, _Key)
    if AiArmyData_ArmyIdToArmyInstance[_ID] then
        return AiArmyData_ArmyIdToArmyInstance[_ID]:GetKey(_Key);
    end
end

--- Saves a custom valua in the army instance.
--- @param _ID integer ID of army
--- @param _Key string Name of key
--- @param _Value any  Value to save
function AiArmy.SetKey(_ID, _Key, _Value)
    if AiArmyData_ArmyIdToArmyInstance[_ID] then
        AiArmyData_ArmyIdToArmyInstance[_ID]:SetKey(_Key, _Value)
    end
end

--- Adds a new troop to the army.
---
--- A troop can be added as reinforcement. In that case the army will not
--- search enemies near to this troop. The troop will walk to the current
--- position of the army using attack walk.
---
--- @param _ID integer        ID of army
--- @param _TroopID integer   ID of troop
--- @param _Reinforce boolean Add as reinforcement
--- @return boolean Added Was successfully added
function AiArmy.AddTroop(_ID, _TroopID, _Reinforce)
    if AiArmyData_ArmyIdToArmyInstance[_ID] then
        return AiArmyData_ArmyIdToArmyInstance[_ID]:AddTroop(_TroopID, _Reinforce);
    end
    return false;
end

--- Spawns a troop soldiers at the location.
---
--- A troop is always added as reinforcement.
---
--- @param _ID integer    ID of army
--- @param _Type integer  Unit type to spawn
--- @param _Position any  Where to spawn
--- @param _Exp? integer  Experience of troop
--- @return boolean Added Was successfully added
function AiArmy.SpawnTroop(_ID, _Type, _Position, _Exp)
    if AiArmyData_ArmyIdToArmyInstance[_ID] then
        local Army = AiArmyData_ArmyIdToArmyInstance[_ID];
        if Army.Strength > Army:GetNumberOfLeader(true) then
            local Position = _Position;
            if type(Position) ~= "table" then
                Position = GetPosition(_Position);
            end
            local TroopID = AI.Entity_CreateFormation(Army.PlayerID, _Type, 0, 0, Position.X, Position.Y, 0, 0, _Exp or 0, 0);
            assert(TroopID ~= nil);
            for i= 1, Logic.LeaderGetMaxNumberOfSoldiers(TroopID) do
                local SoldierType = Logic.LeaderGetSoldiersType(TroopID);
                Logic.CreateEntity(SoldierType, Position.X, Position.Y, 0, Army.PlayerID);
                Tools.AttachSoldiersToLeader(TroopID, 1);
            end
            return AiArmy.AddTroop(_ID, TroopID, true);
        end
    end
    return false;
end

--- Returns if the army was initalized.
---
--- A army is automatically marked as initalized by the code when it has full
--- strength for the first time.
--- @param _ID integer ID of army
--- @return boolean Initialized Army was initalized
function AiArmy.IsInitallyFilled(_ID)
    if AiArmyData_ArmyIdToArmyInstance[_ID] then
        return AiArmyData_ArmyIdToArmyInstance[_ID]:IsInitalized();
    end
    return false;
end

--- Removes a troop from an army.
--- 
--- Returns true on success and false on failure. A failure usually means
--- either the army or the troop might not exist.
--- 
--- @param _ID integer      ID of army
--- @param _TroopID integer ID of troop
--- @return boolean Removed Was successfully removed
function AiArmy.RemoveTroop(_ID, _TroopID)
    if AiArmyData_ArmyIdToArmyInstance[_ID] then
        return AiArmyData_ArmyIdToArmyInstance[_ID]:RemoveTroop(_TroopID) ~= 0;
    end
    return false;
end

function AiArmy.GetWeakenedTroops(_ID)
    if AiArmyData_ArmyIdToArmyInstance[_ID] then
        return AiArmyData_ArmyIdToArmyInstance[_ID]:GetWeakenedTroops();
    end
end

function AiArmy.DispatchTroopsToSpawner(_ID)
    if AiArmyData_ArmyIdToArmyInstance[_ID] then
        return AiArmyData_ArmyIdToArmyInstance[_ID]:DispatchTroopsToSpawner();
    end
end

--- Returns the army ID the troop is connected to if any.
--- @param _ID integer ID of troop
--- @return integer ID ID of army
function AiArmy.GetArmyOfTroop(_ID)
    if AiArmyData_ReinforcementIdToArmyId[_ID] then
        return AiArmyData_ReinforcementIdToArmyId[_ID];
    end
    if AiArmyData_TroopIdToArmyId[_ID] then
        return AiArmyData_TroopIdToArmyId[_ID];
    end
    return 0;
end

--- Returns if the army is existing
--- 
--- @param _ID integer ID of army
--- @return boolean Army Army is existing
function AiArmy.IsExisting(_ID)
    return AiArmyData_ArmyIdToArmyInstance[_ID] ~= nil;
end

--- Returns if the army is alive.
--- 
--- A Army is alive when it has troops. Add troops to a dead army and it will
--- rise like Lazarus. ;)
--- 
--- @param _ID integer ID of army
--- @return boolean Army is alive
function AiArmy.IsAlive(_ID)
    if AiArmyData_ArmyIdToArmyInstance[_ID] then
        return AiArmyData_ArmyIdToArmyInstance[_ID]:IsAlive();
    end
    return false;
end

--- Returns the number of leader attached to the army.
--- @param _ID integer ID of army
--- @return integer Amount Leader count of army
function AiArmy.GetNumberOfLeader(_ID)
    if AiArmyData_ArmyIdToArmyInstance[_ID] then
        return AiArmyData_ArmyIdToArmyInstance[_ID]:GetNumberOfLeader(true);
    end
    return 0;
end

--- Returns the max number of leader the army can have.
--- @param _ID integer ID of army
--- @return integer Amount Leader count of army
function AiArmy.GetMaxNumberOfLeader(_ID)
    if AiArmyData_ArmyIdToArmyInstance[_ID] then
        return AiArmyData_ArmyIdToArmyInstance[_ID].Strength;
    end
    return 0;
end

--- Returns if the army has the max amount of leaders and if the leader have
--- a full regiment of soldiers.
--- @param _ID integer ID of army
--- @return boolean FullStrength Army is full
function AiArmy.HasFullStrength(_ID)
    if AiArmyData_ArmyIdToArmyInstance[_ID] then
        local Army = AiArmyData_ArmyIdToArmyInstance[_ID];
        return Army:GetCurrentStregth(true) >= 1;
    end
    return false;
end

--- Changes the max strength of the army.
--- @param _ID integer       ID of army
--- @param _Strength integer Amount of troops
function AiArmy.SetStrength(_ID, _Strength)
    if AiArmyData_ArmyIdToArmyInstance[_ID] then
        AiArmyData_ArmyIdToArmyInstance[_ID]:SetStrength(_ID, _Strength);
    end
end

--- Returns the current location of the army.
--- @param _ID integer    ID of army
--- @return table? Location Current army location
function AiArmy.GetLocation(_ID)
    if AiArmyData_ArmyIdToArmyInstance[_ID] then
        return AiArmyData_ArmyIdToArmyInstance[_ID]:GetArmyPosition();
    end
end

--- Returns the home position of the army.
--- @param _ID integer    ID of army
--- @return table? Home Home position of army
function AiArmy.GetHomePosition(_ID)
    if AiArmyData_ArmyIdToArmyInstance[_ID] then
        return AiArmyData_ArmyIdToArmyInstance[_ID].HomePosition;
    end
end

--- Returns if the army is close to a position.
--- @param _ID integer       ID of army
--- @param _Position any     Position to check
--- @param _Distance integer Distance to position
--- @return boolean IsNear Army is near
function AiArmy.IsArmyNear(_ID, _Position, _Distance)
    if AiArmyData_ArmyIdToArmyInstance[_ID] then
        local Location = AiArmy.GetLocation(_ID);
        return GetDistance(Location, _Position) <= _Distance;
    end
    return false;
end

--- Changes the radius of action of the army.
--- 
--- @param _ID integer   ID of army
--- @param _Area integer Area size
function AiArmy.SetRodeLength(_ID, _Area)
    if AiArmyData_ArmyIdToArmyInstance[_ID] then
        return AiArmyData_ArmyIdToArmyInstance[_ID]:SetRodeLength(_Area);
    end
end

--- Returns the radius of action of the army.
--- @param _ID integer ID of army
--- @return integer RodeLength Area of action
function AiArmy.GetRodeLength(_ID)
    if AiArmyData_ArmyIdToArmyInstance[_ID] then
        local Army = AiArmyData_ArmyIdToArmyInstance[_ID];
        return Army.RodeLength;
    end
    return 0;
end

--- Returns if the army is active
--- @param _ID integer ID of army
--- @return boolean Active Army is active
function AiArmy.IsActive(_ID)
    if AiArmyData_ArmyIdToArmyInstance[_ID] then
        return AiArmyData_ArmyIdToArmyInstance[_ID].Active;
    end
    return false;
end

--- Resumes the army.
--- @param _ID integer ID of army
function AiArmy.Resume(_ID)
    if AiArmyData_ArmyIdToArmyInstance[_ID] then
        return AiArmyData_ArmyIdToArmyInstance[_ID]:SetActive(true);
    end
end

--- Pauses the army.
--- 
--- Use this if you want to defunc the army without deleting it.
--- 
--- @param _ID integer ID of army
function AiArmy.Yield(_ID)
    if AiArmyData_ArmyIdToArmyInstance[_ID] then
        return AiArmyData_ArmyIdToArmyInstance[_ID]:SetActive(false);
    end
end

--- Sets a function that overwrites which formation is given to troops.
--- @param _ID integer          ID of army
--- @param _Controller function Formation controller function
function AiArmy.SetFormationController(_ID, _Controller)
    if AiArmyData_ArmyIdToArmyInstance[_ID] then
        return AiArmyData_ArmyIdToArmyInstance[_ID]:SetFormationController(_Controller);
    end
end

--- Sets the percentage when the army is defeated.
--- @param _Threshold number Defeated threshold
function AiArmy.SetAliveThreshold(_Threshold)
    AiArmy.Internal.Army:SetAliveThreshold(_Threshold)
end

--- Returns a list of enemies of the army in the area.
--- @param _ID integer          ID of army
--- @param _Position? table     Area center
--- @param _RodeLength? integer Area size
--- @param _Categories? table   List of categories
--- @return table Enemies List of enemies
function AiArmy.GetEnemiesInCircle(_ID, _Position, _RodeLength, _Categories)
    local Enemies = {};
    if AiArmyData_ArmyIdToArmyInstance[_ID] then
        local Army = AiArmyData_ArmyIdToArmyInstance[_ID];
        local Position = _Position or Army.HomePosition;
        local Area = _RodeLength or Army.RodeLength;
        Enemies = AiArmy.Internal:GetEnemiesInCircle(Army.PlayerID, Position, Area, nil, _Categories);
    end
    return Enemies;
end

--- Returns a list of enemies of the army in the cone.
--- @param _ID integer          ID of army
--- @param _Position? table     Area center
--- @param _Angle integer       Rotation of cone
--- @param _Categories? table   List of categories
--- @return table Enemies List of enemies
function AiArmy.GetEnemiesInCone(_ID, _Position, _RodeLength, _Angle, _Categories)
    local Enemies = {};
    if AiArmyData_ArmyIdToArmyInstance[_ID] then
        local Army = AiArmyData_ArmyIdToArmyInstance[_ID];
        local Position = _Position or Army.HomePosition;
        local Area = _RodeLength or Army.RodeLength;
        Enemies = AiArmy.Internal:GetEnemiesInCone(Army.PlayerID, Position, Area, _Angle, _Categories);
    end
    return Enemies;
end

--- Returns true, if the command with the given ID is active.
--- @param _CommandID integer ID of command
--- @return boolean Active Command is active
function AiArmy.IsCommandActive(_ID, _CommandID)
    if AiArmyData_ArmyIdToArmyInstance[_ID] then
        return AiArmyData_ArmyIdToArmyInstance[_ID]:IsCommandActive(_CommandID);
    end
    return false;
end

--- Returns true, if the command with the given ID is enqueued.
--- @param _CommandID integer ID of command
--- @return boolean Enqueued Command is enqueued
function AiArmy.IsCommandEnqueued(_ID, _CommandID)
    if AiArmyData_ArmyIdToArmyInstance[_ID] then
        return AiArmyData_ArmyIdToArmyInstance[_ID]:IsCommandEnqueued(_CommandID);
    end
    return false;
end

--- Returns true, if a command of the given type enqueued.
--- @param _Command integer Type of command
--- @return boolean Active Command is active
function AiArmy.IsCommandOfTypeActive(_ID, _Command)
    if AiArmyData_ArmyIdToArmyInstance[_ID] then
        return AiArmyData_ArmyIdToArmyInstance[_ID]:IsCommandOfTypeActive(_Command);
    end
    return false;
end

--- Returns true, if a command of the given type enqueued.
--- @param _Command integer Type of command
--- @return boolean Enqueued Command is enqueued
function AiArmy.IsCommandOfTypeEnqueued(_ID, _Command)
    if AiArmyData_ArmyIdToArmyInstance[_ID] then
        return AiArmyData_ArmyIdToArmyInstance[_ID]:IsCommandOfTypeEnqueued(_Command);
    end
    return false;
end

--- Removes all commands from the command queue.
function AiArmy.ClearCommands(_ID)
    if AiArmyData_ArmyIdToArmyInstance[_ID] then
        AiArmyData_ArmyIdToArmyInstance[_ID]:ClearCommands();
    end
end

--- comment
--- @param _Command integer Type of command
--- @param ... any Parameters for command
--- @return table|nil Command Created command
function AiArmy.CreateCommand(_ID, _Command, ...)
    if AiArmyData_ArmyIdToArmyInstance[_ID] then
        return AiArmyData_ArmyIdToArmyInstance[_ID]:CreateCommand(_Command, unpack(arg));
    end
end

--- Pushes a command to the command queue.
--- @param _Command table Command to push
--- @param _Repeat boolean Command is enqueued after finish
--- @param _Index integer? Optional position in queue
function AiArmy.PushCommand(_ID, _Command, _Repeat, _Index)
    if AiArmyData_ArmyIdToArmyInstance[_ID] then
        AiArmyData_ArmyIdToArmyInstance[_ID]:PushCommand(_Command, _Repeat, _Index);
    end
end

--- Removes the current command.
--- @return table|nil Command Popped commad
function AiArmy.PopCommand(_ID)
    if AiArmyData_ArmyIdToArmyInstance[_ID] then
        return AiArmyData_ArmyIdToArmyInstance[_ID]:PopCommand();
    end
end

-- -------------------------------------------------------------------------- --
-- Game Callbacks

--- Called when a command has concluded.
--- @param _ArmyID integer      ID of army
--- @param _CommandID integer   ID of command
--- @param _CommandType integer Type of command
--- @param ... any              List of parameters
function GameCallback_Logic_OnCommandDone(_ArmyID, _CommandID, _CommandType, ...)
end

--- Called when a command was aborted.
--- @param _ArmyID integer      ID of army
--- @param _CommandID integer   ID of command
--- @param _CommandType integer Type of command
--- @param ... any              List of parameters
function GameCallback_Logic_OnCommandAborted(_ArmyID, _CommandID, _CommandType, ...)
end

--- Called each time the execution of an command begins.
--- @param _ArmyID integer      ID of army
--- @param _CommandID integer   ID of command
--- @param _CommandType integer Type of command
--- @param ... any              List of parameters
function GameCallback_Logic_OnCommandExecution(_ArmyID, _CommandID, _CommandType, ...)
end

-- -------------------------------------------------------------------------- --
-- Internal

AiArmy.Internal = AiArmy.Internal or {
    Data = {},
};

function AiArmy.Internal:Install()
    if not self.isInstalled then
        self.isInstalled = true;

        AiArmyControllerJobId = Job.Turn(function ()
            AiArmy.Internal:Controller();
        end);
    end
end

function AiArmy.Internal:Controller()
    local Turn = Logic.GetCurrentTurn();

    local QualifyingArmies = {};
    for k,v in pairs(AiArmyData_ArmyIdToArmyInstance) do
        if v.Active then
            --- @diagnostic disable-next-line: undefined-field
            if math.mod(Turn, 10) == v.Tick and v.LastTick+19 < Turn then
                table.insert(QualifyingArmies, v);
            end
        end
    end

    for i= table.getn(QualifyingArmies), 1, -1 do
        local Army = QualifyingArmies[i];
        Army:SetLastTick(Turn);
        Army:DebugShowCurrentPosition();
        Army:ManageArmyMembers();
        Army:ExecuteCommand();
    end
end

function AiArmy.Internal:GetEnemiesInCone(_PlayerID, _Position, _Area, _Angle, _CategoryList)
    local Enemies = {};
    local AreaCenter = GetConeCenter(_Position, _Area, _Angle);

    -- Debug
    -- local ConeCenterID = 0;
    -- local ConeEndID = 0;
    -- Logic.DestroyEffect(gvDebugConeCenter or 0);
    -- Logic.DestroyEffect(gvDebugConeEnd or 0);
    -- local AreaEnd = GetConeEnd(_Position, _Area, _Angle);
    -- if IsValidPosition(AreaCenter) then
    --     ConeCenterID = Logic.CreateEffect(GGL_Effects.FXTerrainPointer, AreaCenter.X, AreaCenter.Y, 0)
    -- end
    -- if IsValidPosition(AreaEnd) then
    --     ConeEndID = Logic.CreateEffect(GGL_Effects.FXTerrainPointer, AreaEnd.X, AreaEnd.Y, 0)
    -- end
    -- gvDebugConeCenter = ConeCenterID;
    -- gvDebugConeEnd = ConeEndID;

    if IsValidPosition(AreaCenter) then
        if not AreEntitiesOfDiplomacyStateInArea(_PlayerID, AreaCenter, _Area, Diplomacy.Hostile, _CategoryList) then
            return Enemies;
        end
        for _,ID in ipairs(self:GetEnemiesInCircle(_PlayerID, AreaCenter, _Area, nil, _CategoryList)) do
            if IsInCone(ID, _Position, _Area, _Angle, 50) then
                table.insert(Enemies, ID);
            end
        end
    end
    return Enemies;
end

function AiArmy.Internal:GetEnemiesInConeFortificationFilter(_PlayerID, _Position, _Area, _Angle)
    local CategoryList = {"Wall"};
    return self:GetEnemiesInCone(_PlayerID, _Position, _Area, _Angle, CategoryList)
end

function AiArmy.Internal:GetEnemiesInConeRegularFilter(_PlayerID, _Position, _Area, _Angle)
    local CategoryList = {"Cannon", "DefendableBuilding", "Hero", "Leader", "MilitaryBuilding", "Serf"};
    return self:GetEnemiesInCone(_PlayerID, _Position, _Area, _Angle, CategoryList);
end

function AiArmy.Internal:GetEnemiesInCircle(_PlayerID, _Position, _Area, _TroopID, _CategoryList)
    local AreaCenter;
    local Enemies = {};

    -- Check in vecinity of troop
    if _TroopID and IsExisting(_TroopID) then
        if AreEntitiesOfDiplomacyStateInArea(_PlayerID, GetPosition(_TroopID), _Area, Diplomacy.Hostile, _CategoryList) then
            AreaCenter = GetPosition(_TroopID);
        end
    -- Check in vecinity of position
    else
        if not AreEntitiesOfDiplomacyStateInArea(_PlayerID, _Position, _Area, Diplomacy.Hostile, _CategoryList) then
            return Enemies;
        end
        AreaCenter = _Position;
    end

    -- Create central entity
    local AreaCenterID = Logic.CreateEntity(Entities.XD_Rock1, AreaCenter.X, AreaCenter.Y, 0, 0);
    -- Obtain IDs of enemies
    local PlayerID = (_TroopID and Logic.EntityGetPlayer(_TroopID)) or _PlayerID;
    Enemies = GetEntitiesOfDiplomacyStateInArea(PlayerID, AreaCenter, _Area, Diplomacy.Hostile, _CategoryList);
    for i= table.getn(Enemies), 1, -1 do
        local TypeName = Logic.GetEntityTypeName(Logic.GetEntityType(Enemies[i]));
        if not IsValidEntity(Enemies[i])
        or Logic.CheckEntitiesDistance(AreaCenterID, Enemies[i], _Area) == 0
        or string.find(TypeName, "PU_Hero3_Trap") then
            table.remove(Enemies, i);
        end
    end
    -- Destroy central entity
    DestroyEntity(AreaCenterID);

    return Enemies;
end

function AiArmy.Internal:GetEnemiesFortificationFilter(_PlayerID, _Position, _Area, _TroopID)
    local CategoryList = {"Wall"};
    return self:GetEnemiesInCircle(_PlayerID, _Position, _Area, _TroopID, CategoryList);
end

function AiArmy.Internal:GetEnemiesRegularFilter(_PlayerID, _Position, _Area, _TroopID)
    local CategoryList = {"Cannon", "DefendableBuilding", "Hero", "Leader", "MilitaryBuilding", "Serf"};
    return self:GetEnemiesInCircle(_PlayerID, _Position, _Area, _TroopID, CategoryList);
end

-- Returns the best target for the troop from the target list.
function AiArmy.Internal:PriorityTarget(_TroopID, _Enemies)
    local EnemiesList = CopyTable(_Enemies);
    if table.getn(EnemiesList) > 1 then
        table.sort(EnemiesList, function(a, b)
            local Priority1 = AiArmy.Internal:GetAttackingCosts(_TroopID, a);
            local Priority2 = AiArmy.Internal:GetAttackingCosts(_TroopID, b);
            return Priority1 < Priority2;
        end);
    end
    return EnemiesList[1];
end

function AiArmy.Internal:GetAttackingCosts(_TroopID, _EnemyID)
    -- Obtain base priority factor
    local EnemyType = Logic.GetEntityType(_EnemyID);
    local Priorities = self:GetPriorityFactorMap(_TroopID);
    local Factor = 1.0;
    if Priorities[EnemyType] then
        Factor = Factor * (1/Priorities[EnemyType]);
    else
        for k, v in pairs(GetEntityCategoriesAsString(_EnemyID)) do
            if Priorities[v] then
                Factor = Factor * (1/Priorities[v]);
            end
        end
    end
    -- Adjust factor by threat potency
    -- (Leaders with more soldiers will do more damage and are higher up on
    -- the kill list)
    if Factor > 0 and Logic.IsLeader(_EnemyID) == 1 then
        local Maximum = Logic.LeaderGetMaxNumberOfSoldiers(_EnemyID);
        if Maximum > 0 then
            local Current = Logic.LeaderGetNumberOfSoldiers(_EnemyID);
            Factor = Factor * (1/((Current+1)/(Maximum+1)));
        else
            Factor = Factor * 10;
        end
    end
    -- Set costs by distance
    if Factor > 0 then
        local Costs = GetDistance(_TroopID, _EnemyID);
        return Factor * Costs;
    end
    return Logic.WorldGetSize();
end

function AiArmy.Internal:GetPriorityFactorMap(_TroopID)
    local Config = AiArmyConstants.Targeting;
    local Army = AiArmy.Get(AiArmy.GetArmyOfTroop(_TroopID));
    if Army and Army.Targeting then
        Config = Army.Targeting;
    end

    local Type = Logic.GetEntityType(_TroopID);
    if Config[Type] then
        return Config[Type];
    end
    if Logic.IsEntityInCategory(_TroopID, EntityCategories.EvilLeader) == 1
    or Type == Entities.CU_Evil_LeaderSkirmisher then
        return Config.LongRange;
    end
    if Logic.IsEntityInCategory(_TroopID, EntityCategories.Rifle) == 1
    or Type == Entities.PU_Hero10 then
        return Config.Rifle;
    end
    if Logic.IsEntityInCategory(_TroopID, EntityCategories.LongRange) == 1
    or Type == Entities.PU_Hero5 then
        return Config.LongRange;
    end
    if Logic.IsEntityInCategory(_TroopID, EntityCategories.Spear) == 1 then
        return Config.Spear;
    end
    if Logic.IsEntityInCategory(_TroopID, EntityCategories.CavalryHeavy) == 1 then
        return Config.CavalryHeavy;
    end
    if Logic.IsEntityInCategory(_TroopID, EntityCategories.Cannon) == 1 then
        return Config.Cannon;
    end
    return Config.Sword;
end

-- -------------------------------------------------------------------------- --
-- Model

AiArmyCommand = {
    Idle = 1,
    Stop = 2,
    Wait = 3,
    Move = 4,
    Battle = 5,
    Siege = 6,
    Regroup = 7,
    Fallback = 8,
    Refill = 9,
    Finish = 10,
    Custom = 11,
}

AiArmy.Internal.Army = AiArmy.Internal.Army or {
    ID               = 0,
    Active           = true,
    Initalized       = false,
    PlayerID         = 1,
    Strength         = 8,
    RodeLength  	 = 3000,
    HomePosition     = nil,
    DefeatThreshold  = 0.20,
    LastTick         = 0,

    Reinforcements   = {0},
    Troops           = {0},
    CleanUp          = {0},

    Targeting        = nil,
    Targets          = {},

    Commands         = {Sequence = 0},
    Data             = {},
    Debug            = {
        ShowPosition = false,
        Position     = 0,
    },
};

AiArmyData_TroopIdToArmyId = AiArmyData_TroopIdToArmyId  or {};
AiArmyData_ReinforcementIdToArmyId = AiArmyData_ReinforcementIdToArmyId  or {};
AiArmyData_ArmyIdToArmyInstance = AiArmyData_ArmyIdToArmyInstance  or {};
AiArmyData_IdSequence = AiArmyData_IdSequence  or 0;

function AiArmy.Internal.Army:New(_PlayerID, _Strength, _Position, _RodeLength)
    AiArmyData_IdSequence = AiArmyData_IdSequence +1;
    AiArmy.Internal:Install();

    local Army = CopyTable(self);
    Army.ID = AiArmyData_IdSequence;
    Army.PlayerID = _PlayerID;
    --- @diagnostic disable-next-line: undefined-field
    Army.Tick = math.mod(self.ID, 10);
    Army.HomePosition = _Position;
    Army.RodeLength = _RodeLength;
    Army.Strength = _Strength;
    Army.FormationController = nil;
    return Army;
end

function AiArmy.Internal.Army:Dispose()
    self:Abandon(false);
    AiArmyData_ArmyIdToArmyInstance[self.ID] = nil;
end

-- -------------------------------------------------------------------------- --

function AiArmy.Internal.Army:CreateCommand(_Command, ...)
    local Sequence = AiArmy.Internal.Army.Commands.Sequence;
    AiArmy.Internal.Army.Commands.Sequence = Sequence + 1;
    local Command = {ID = Sequence, _Command, {unpack(arg)}};
    return Command;
end

function AiArmy.Internal.Army:PushCommand(_Command, _Repeat, _Index)
    if _Index then
        table.insert(self.Commands, _Index, {_Command, _Repeat});
    end
    table.insert(self.Commands, {_Command, _Repeat});
end

function AiArmy.Internal.Army:PopCommand()
    return table.remove(self.Commands, 1);
end

function AiArmy.Internal.Army:GetCurrentCommand()
    return self.Commands[1];
end

function AiArmy.Internal.Army:IsCommandActive(_ID)
    return self.Commands[1] and self.Commands[1][1].ID == _ID;
end

function AiArmy.Internal.Army:IsCommandOfTypeActive(_Command)
    return self.Commands[1] and self.Commands[1][1][1] == _Command;
end

function AiArmy.Internal.Army:IsCommandEnqueued(_ID)
    for i= 1, table.getn(self.Commands) do
        if self.Commands[i][1].ID == _ID then
            return true;
        end
    end
    return false;
end

function AiArmy.Internal.Army:IsCommandOfTypeEnqueued(_Command)
    for i= 1, table.getn(self.Commands) do
        if self.Commands[i][1][1] == _Command then
            return true;
        end
    end
    return false;
end

function AiArmy.Internal.Army:ClearCommands()
    -- Delete targets
    for i= 2, self.Troops[1] +1 do
        self:LockOn(self.Troops[i], nil);
    end
    -- Delete commands
    for i= 1, table.getn(self.Commands) do
        GameCallback_Logic_OnCommandAborted(
            self.ID,
            self.Commands[i][1].ID,
            self.Commands[i][1][1],
            unpack(self.Commands[i][1][2])
        );
    end
    self.Commands = {};
end

function AiArmy.Internal.Army:ExecuteCommand()
    -- Add default command
    if not self.Commands[1] then
        self:PushCommand(
            self:CreateCommand(AiArmyCommand.Idle, self:GetArmyPosition()),
            false
        );
    end

    -- Execute command
    local CommandDone = false;
    local CommandType = self.Commands[1][1][1];
    local CommandData = self.Commands[1][1][2];

    GameCallback_Logic_OnCommandExecution(
        self.ID,
        self.Commands[1][1].ID,
        CommandType,
        unpack(CommandData)
    );

    if CommandType == AiArmyCommand.Idle then
        CommandDone = self:ExecuteIdleCommand(CommandData) == true;
    end
    if CommandType == AiArmyCommand.Wait then
        CommandDone = self:ExecuteWaitCommand(CommandData) == true;
    end
    if CommandType == AiArmyCommand.Stop then
        CommandDone = self:ExecuteStopCommand(CommandData) == true;
    end
    if CommandType == AiArmyCommand.Move then
        CommandDone = self:ExecuteMoveCommand(CommandData) == true;
    end
    if CommandType == AiArmyCommand.Battle then
        CommandDone = self:ExecuteBattleCommand(CommandData) == true;
    end
    if CommandType == AiArmyCommand.Siege then
        CommandDone = self:ExecuteSiegeCommand(CommandData) == true;
    end
    if CommandType == AiArmyCommand.Regroup then
        CommandDone = self:ExecuteRegroupCommand(CommandData) == true;
    end
    if CommandType == AiArmyCommand.Refill then
        CommandDone = self:ExecuteRefillCommand(CommandData) == true;
    end
    if CommandType == AiArmyCommand.Fallback then
        CommandDone = self:ExecuteFallbackCommand(CommandData) == true;
    end
    if CommandType == AiArmyCommand.Finish then
        CommandDone = self:ExecuteFinishCommand(CommandData) == true;
    end
    if CommandType == AiArmyCommand.Custom then
        CommandDone = self:ExecuteCustomCommand(CommandData) == true;
    end

    -- Remove (and restart) command
    if CommandDone and self.Commands[1] and self.Commands[1][1][1] == CommandType then
        local Command = table.remove(self.Commands, 1);
        self:PushCommand(Command[1], true);

        GameCallback_Logic_OnCommandDone(
            self.ID,
            Command.ID,
            CommandType,
            unpack(CommandData)
        );
    end
end

--- Commands the army to do nothing.
--- @param _Data table Command Parameter
--- @return boolean Done Command is done
function AiArmy.Internal.Army:ExecuteIdleCommand(_Data)
    self:NormalizedArmySpeed();

    local Position = _Data[3] or self:GetArmyPosition();
    if type(Position) ~= "table" then
        Position = GetPosition(Position);
    end
    -- Finish command if army is defeated
    if self:GetCurrentStregth(true) <= self.DefeatThreshold then
        self:ClearCommands();
        self:PushCommand(self:CreateCommand(AiArmyCommand.Fallback), false);
        self:PushCommand(self:CreateCommand(AiArmyCommand.Refill), false);
        return true;
    end
    -- Check if enemies are near
    local AreaSize = _Data[4] or self.RodeLength;
    local Enemies = AiArmy.Internal:GetEnemiesRegularFilter(self.PlayerID, Position, AreaSize);
    if Enemies[1] then
        self:PushCommand(self:CreateCommand(AiArmyCommand.Battle, Position, AreaSize), false, 1);
        self:ExecuteCommand();
        return false;
    end
    -- Move troops back to army position if necessary and finish command
    Position = _Data[1] or self:GetArmyPosition();
    for i= self.Troops[1] +1, 2, -1 do
        if GetDistance(self.Troops[i], Position) > 1200 then
            Logic.MoveSettler(self.Troops[i], Position.X, Position.Y, -1);
        end
    end
    return true;
end

--- Commands the army to wait at a position for a period of time.
--- @param _Data table Command Parameter
--- @return boolean Done Command is done
function AiArmy.Internal.Army:ExecuteWaitCommand(_Data)
    local Position = _Data[3] or self:GetArmyPosition();
    if type(Position) ~= "table" then
        Position = GetPosition(Position);
    end
    -- Finished command after timer ran out
    if Logic.GetTime() > _Data[1] + _Data[2] then
        return true;
    end
    -- Finish command if army is defeated
    if self:GetCurrentStregth(true) <= self.DefeatThreshold then
        self:ClearCommands();
        self:PushCommand(self:CreateCommand(AiArmyCommand.Fallback), false);
        self:PushCommand(self:CreateCommand(AiArmyCommand.Refill), false);
        return true;
    end
    -- Check if enemies are near
    local AreaSize = _Data[4] or self.RodeLength;
    local Enemies = AiArmy.Internal:GetEnemiesRegularFilter(self.PlayerID, Position, AreaSize);
    if Enemies[1] then
        self:PushCommand(self:CreateCommand(AiArmyCommand.Battle, Position, AreaSize), false, 1);
        self:ExecuteCommand();
        return false;
    end
    -- Move troops back to army position if necessary
    self:NormalizedArmySpeed();
    for i= self.Troops[1] +1, 2, -1 do
        if GetDistance(self.Troops[i], Position) > 1200 then
            Logic.MoveSettler(self.Troops[i], Position.X, Position.Y, -1);
        end
    end
    return false;
end

--- Commands the army to hold position.
--- @param _Data table Command Parameter
--- @return boolean Done Command is done
function AiArmy.Internal.Army:ExecuteStopCommand(_Data)
    -- Stop each troop and finish command
    for i= self.Troops[1] +1, 2, -1 do
        Logic.SettlerStand(self.Troops[i]);
    end
    return true;
end

--- comment
--- @param _Data table Command Parameter
--- @return boolean Done Command is done
function AiArmy.Internal.Army:ExecuteMoveCommand(_Data)
    local Position = self:GetArmyPosition();
    local Rotation = self:GetArmyRotation();
    -- Finish command if army has arrived
    if GetDistance(self:GetArmyPosition(), _Data[1]) <= (_Data[2] or 1000) then
        return true;
    end
    -- Finish command if army is defeated
    if self:GetCurrentStregth(true) <= self.DefeatThreshold then
        self:ClearCommands();
        self:PushCommand(self:CreateCommand(AiArmyCommand.Fallback), false);
        self:PushCommand(self:CreateCommand(AiArmyCommand.Refill), false);
        return true;
    end
    -- Regroup army if necessary
    if self:IsScattered() then
        self:PushCommand(self:CreateCommand(AiArmyCommand.Regroup), false, 1);
        self:PushCommand(self:CreateCommand(AiArmyCommand.Stop), false, 1);
        self:ExecuteCommand();
        return false;
    end
    -- Check if enemies are in vision cone and attack them
    local AreaSize = self.RodeLength * 1.5;
    local Enemies = AiArmy.Internal:GetEnemiesInConeRegularFilter(
        self.PlayerID, Position, AreaSize, Rotation
    );
    if Enemies[1] then
        local Location = GetGeometricCenter(unpack(Enemies));
        self:PushCommand(self:CreateCommand(AiArmyCommand.Battle, Location, self.RodeLength), false, 1);
        self:ExecuteCommand();
        return false;
    end
    -- Check if enemies are near to army and attack them
    Enemies = AiArmy.Internal:GetEnemiesRegularFilter(
        self.PlayerID, Position, self.RodeLength
    );
    if Enemies[1] then
        self:PushCommand(self:CreateCommand(AiArmyCommand.Battle, Position, self.RodeLength), false, 1);
        self:ExecuteCommand();
        return false;
    end
    self:NormalizedArmySpeed();
    Position = (type(_Data[1]) == "table" and _Data[1]) or GetPosition(_Data[1]);
    -- Check if army should attack wall
    if ArePositionsConnected(Position, Position) then
        for i= self.Troops[1] +1, 2, -1 do
            if Logic.IsEntityMoving(self.Troops[i]) == false or _Data[3] then
                Logic.MoveSettler(self.Troops[i], Position.X, Position.Y, -1);
            end
        end
    else
        self:PushCommand(self:CreateCommand(AiArmyCommand.Siege, Position, AreaSize), false, 1);
        self:ExecuteCommand();
    end
    return false;
end

--- Commands the army to attack enemies in it's vicinity.
--- @param _Data table Command Parameter
--- @return boolean Done Command is done
function AiArmy.Internal.Army:ExecuteBattleCommand(_Data)
    local Rotation = self:GetArmyRotation();
    local Position = _Data[1] or self:GetArmyPosition();
    if type(Position) ~= "table" then
        Position = GetPosition(Position);
    end
    -- Finish command if army is defeated
    if self:GetCurrentStregth(true) <= self.DefeatThreshold then
        self:ClearCommands();
        self:PushCommand(self:CreateCommand(AiArmyCommand.Fallback), false);
        self:PushCommand(self:CreateCommand(AiArmyCommand.Refill), false);
        return true;
    end
    -- Finish command if army has defeated enemies
    local Enemies = AiArmy.Internal:GetEnemiesRegularFilter(self.PlayerID, Position, (_Data[2] or self.RodeLength));
    if not Enemies[1] then
        return true;
    end
    -- Control fighting
    self:ResetArmySpeed();
    for j= 2, self.Troops[1] +1 do
        if GetDistance(Position, self.Troops[j]) > (_Data[2] or self.RodeLength) then
            --- @diagnostic disable-next-line: undefined-field
            Logic.MoveSettler(self.Troops[j], Position.X, Position.Y);
            self:LockOn(self.Troops[j], nil);
        else
            -- Move back
            if GetDistance(self.Troops[j], Position) > (_Data[2] or self.RodeLength) then
                --- @diagnostic disable-next-line: undefined-field
                Logic.MoveSettler(self.Troops[j], Position.X, Position.Y);
            -- Attack enemies
            else
                if not self.Targets[self.Troops[j]] then
                    if Enemies[1] then
                        local TargetID = AiArmy.Internal:PriorityTarget(self.Troops[j], Enemies);
                        self:LockOn(self.Troops[j], TargetID);
                        Logic.GroupAttack(self.Troops[j], TargetID);
                    end
                end
            end
        end
    end
    return false;
end

--- Commands the army to attack walls in it's vicinity.
--- @param _Data table Command Parameter
--- @return boolean Done Command is done
function AiArmy.Internal.Army:ExecuteSiegeCommand(_Data)
    local Position = _Data[1] or self:GetArmyPosition();
    if type(Position) ~= "table" then
        Position = GetPosition(Position);
    end
    -- Finish command if army is defeated
    if self:GetCurrentStregth(true) <= self.DefeatThreshold then
        self:ClearCommands();
        self:PushCommand(self:CreateCommand(AiArmyCommand.Fallback), false);
        self:PushCommand(self:CreateCommand(AiArmyCommand.Refill), false);
        return true;
    end
    -- Finish command if army has broke the walls
    local AreaSize = (_Data[2] or self.RodeLength) * 1.25;
    local Enemies = AiArmy.Internal:GetEnemiesFortificationFilter(self.PlayerID, Position, AreaSize);
    if not Enemies[1] then
        return true;
    end
    -- Control fighting
    self:ResetArmySpeed();
    local CloseEnemies = AiArmy.Internal:GetEnemiesRegularFilter(self.PlayerID, Position, AreaSize);
    for j= 2, self.Troops[1] +1 do
        -- Move back to center of spread to far
        if GetDistance(Position, self.Troops[j]) > AreaSize then
            Logic.MoveSettler(self.Troops[j], Position.X, Position.Y);
            self:LockOn(self.Troops[j], nil);
        -- Attack wall or defend army
        else
            if Logic.IsEntityInCategory(self.Troops[j], EntityCategories.Melee) == 1 then
                if not self.Targets[self.Troops[j]] and CloseEnemies[1] then
                    local TargetID = AiArmy.Internal:PriorityTarget(self.Troops[j], CloseEnemies);
                    local Location = GetPosition(TargetID);
                    self:LockOn(self.Troops[j], TargetID);
                    Logic.GroupAttackMove(self.Troops[j], Location.X, Location.Y);
                end
            else
                if not self.Targets[self.Troops[j]] then
                    local TargetID = AiArmy.Internal:PriorityTarget(self.Troops[j], Enemies);
                    self:LockOn(self.Troops[j], TargetID);
                    Logic.GroupAttack(self.Troops[j], TargetID);
                end
            end
        end
    end
    return false;
end

--- Commands the army to gather at current position.
--- @param _Data table Command Parameter
--- @return boolean Done Command is done
function AiArmy.Internal.Army:ExecuteRegroupCommand(_Data)
    local Position = self:GetArmyPosition();
    -- Regroup army and finish command
    for i= self.Troops[1] +1, 2, -1 do
        if Logic.IsEntityMoving(self.Troops[i]) == false then
            Logic.MoveSettler(self.Troops[i], Position.X, Position.Y, -1);
        end
    end
    return true;
end

--- Commands the army to wait for refill.
--- @param _Data table Command Parameter
--- @return boolean Done Command is done
function AiArmy.Internal.Army:ExecuteRefillCommand(_Data)
    local Position = self:GetArmyPosition();
    -- Finish command if army has refillers left
    local RefillerList = AiArmyRefiller.GetRefillersOfArmy(self.ID);
    if table.getn(RefillerList) == 0 then
        return true;
    end
    -- Finish command if army has full strength
    if self:GetCurrentStregth(true) >= 1 then
        return true;
    end
    -- Check if enemies are near
    local Enemies = AiArmy.Internal:GetEnemiesRegularFilter(self.PlayerID, Position, self.RodeLength);
    if Enemies[1] then
        self:PushCommand(self:CreateCommand(AiArmyCommand.Battle, Position), false, 1);
        self:ExecuteCommand();
        return false;
    end
    -- Regroup if army has spread to much
    if self:IsScattered() then
        self:PushCommand(self:CreateCommand(AiArmyCommand.Regroup), false, 1);
        self:PushCommand(self:CreateCommand(AiArmyCommand.Stop), false, 1);
        self:ExecuteCommand();
    end
    return false;
end

--- Commands army to retreat to home position.
--- @param _Data table Command Parameter
--- @return boolean Done Command is done
function AiArmy.Internal.Army:ExecuteFallbackCommand(_Data)
    local Position = _Data[1] or self.HomePosition;
    if type(Position) ~= "table" then
        Position = GetPosition(Position);
    end
    -- Finish command if army is completly wiped
    if self:GetCurrentStregth(true) <= 0 then
        self:DispatchTroopsToSpawner();
        return true;
    end
    -- Finish command if army arrived at home position
    if GetDistance(self:GetArmyPosition(), Position) <= 1200 then
        self:DispatchTroopsToSpawner();
        return true;
    end
    -- Move back to home position
    self:ResetArmySpeed();
    for i= self.Troops[1] +1, 2, -1 do
        if Logic.IsEntityMoving(self.Troops[i]) == false then
            --- @diagnostic disable-next-line: undefined-field
            Logic.MoveSettler(self.Troops[i], self.HomePosition.X, self.HomePosition.Y, -1);
        end
    end
    return false;
end

--- Commands the army to do more than nothing.
---
--- This command can be used to indicate that a command sequence is finished.
--- @param _Data table Command Parameter
--- @return boolean Done Command is done
function AiArmy.Internal.Army:ExecuteFinishCommand(_Data)
    return true;
end

--- Executes a custom command.
--- @param _Data table Command Parameter
--- @return boolean Done Command is done
function AiArmy.Internal.Army:ExecuteCustomCommand(_Data)
    if _Data[1](self, unpack(_Data)) then
        return true;
    end
    return false;
end

-- -------------------------------------------------------------------------- --

function AiArmy.Internal.Army:ChangePlayer(_PlayerID)
    -- Change troops
    local Troops = {0};
    for i= self.Troops[1] +1, 2, -1 do
        local ID = ChangePlayer(Troops[i], _PlayerID);
        Troops[1] = Troops[1] -1;
        table.insert(Troops, ID);
    end
    self.Troops = Troops;
    -- Change reinforcement
    local Reinforcements = {0};
    for i= self.Reinforcements[1] +1, 2, 1 do
        local ID = ChangePlayer(Reinforcements[i], _PlayerID);
        Reinforcements[1] = Reinforcements[1] + 1;
        table.insert(Reinforcements, ID);
    end
    self.Reinforcements = Reinforcements;
    -- Save player
    self.PlayerID = _PlayerID;
end

function AiArmy.Internal.Army:ManageArmyMembers()
    -- Update reinforcements
    for j= self.Reinforcements[1] +1, 2, -1 do
        if not IsValidEntity(self.Reinforcements[j]) then
            local ID = table.remove(self.Reinforcements, j);
            AiArmyData_ReinforcementIdToArmyId[ID] = nil;
        elseif GetDistance(self.Reinforcements[j], self:GetArmyPosition()) <= 2000 then
            local ID = table.remove(self.Reinforcements, j);
            AiArmyData_ReinforcementIdToArmyId[ID] = nil;
            self:AddTroop(ID, false);
        else
            if Logic.IsEntityMoving(self.Reinforcements[j]) == false then
                local Position = self:GetArmyPosition();
                Logic.GroupAttackMove(self.Reinforcements[j], Position.X, Position.Y);
            end
        end
    end

    -- Update current troops
    for j= self.Troops[1] +1, 2, -1 do
        if not IsValidEntity(self.Troops[j]) then
            self:LockOn(self.Troops[j], nil);
            local ID = table.remove(self.Troops, j);
            self.Troops[1] = self.Troops[1] -1;
            AiArmyData_TroopIdToArmyId[ID] = nil;
        end
    end

    -- Update troop cleanup
    for j= self.CleanUp[1] +1, 2, -1 do
        local Alive = IsValidEntity(self.CleanUp[j]);
        local Fighting = IsFighting(self.CleanUp[j]);
        local Moving = Logic.IsEntityMoving(self.CleanUp[j]);
        if not Alive or not Fighting or not Moving then
            local ID = table.remove(self.CleanUp, j);
            self.CleanUp[1] = self.CleanUp[1] -1;
            AiArmyData_TroopIdToArmyId[ID] = nil;
            self:LockOn(ID, nil);
            if not Fighting and not Moving then
                local Soldiers = {Logic.GetSoldiersAttachedToLeader(ID)};
                for i= Soldiers[1] +1, 1, -1 do
                    SetHealth(Soldiers[i], 0);
                end
                SetHealth(ID, 0);
            end
        end
    end

    -- Update troop targets
    for k,v in pairs(self.Targets) do
        if not IsValidEntity(v[1]) or not IsValidEntity(v[2]) or Logic.GetTime() > v[3]+15 then
            self.Targets[k] = nil;
        end
    end
end

function AiArmy.Internal.Army:AddTroop(_ID, _Reinforcement)
    if self:GetNumberOfLeader(true) < self.Strength then
        if AiArmyData_TroopIdToArmyId[_ID] then
            return false;
        end
        if AiArmyData_ReinforcementIdToArmyId[_ID] then
            return false;
        end

        if IsValidEntity(_ID) then
            if self.FormationController then
                self:FormationController(_ID);
            else
                self:ChoseFormation(_ID);
            end
        end
        if _Reinforcement then
            AiArmyData_ReinforcementIdToArmyId[_ID] = self.ID;
            table.insert(self.Reinforcements, _ID);
            self.Reinforcements[1] = self.Reinforcements[1] +1;
        else
            AiArmyData_TroopIdToArmyId[_ID] = self.ID;
            table.insert(self.Troops, _ID);
            self.Troops[1] = self.Troops[1] +1;
        end
        if not self:IsInitalized() then
            self:SetInitalized(self:GetCurrentStregth(true) >= 1);
        end
        return true;
    end
    return false;
end

function AiArmy.Internal.Army:RemoveTroop(_ID)
    for i= self.Reinforcements[1] +1, 2, -1 do
        if self.Reinforcements[i] == _ID then
            AiArmyData_ReinforcementIdToArmyId[_ID] = nil;
            local ID = table.remove(self.Reinforcements, i);
            self.Reinforcements[1] = self.Reinforcements[1] -1;
            return ID;
        end
    end
    for i= table.getn(self.Troops), 1, -1 do
        if self.Troops[i] == _ID then
            AiArmyData_TroopIdToArmyId[_ID] = nil;
            local ID = table.remove(self.Troops, i);
            self.Troops[1] = self.Troops[1] -1;
            return ID;
        end
    end
    return 0;
end

function AiArmy.Internal.Army:GetWeakenedTroops()
    local ToRemove = {};
    for i= self.Reinforcements[1] +1, 2, -1 do
        local MaxHealth = Logic.GetEntityMaxHealth(self.Reinforcements[i]);
        local Health = Logic.GetEntityHealth(self.Reinforcements[i]);
        local MaxSoldiers = Logic.LeaderGetMaxNumberOfSoldiers(self.Reinforcements[i]);
        local Soldiers = Logic.LeaderGetNumberOfSoldiers(self.Reinforcements[i]);
        if Soldiers < MaxSoldiers or Health < MaxHealth then
            table.insert(ToRemove, self.Reinforcements[i]);
        end
    end
    for i= self.Troops[1] +1, 2, -1 do
        local MaxHealth = Logic.GetEntityMaxHealth(self.Troops[i]);
        local Health = Logic.GetEntityHealth(self.Troops[i]);
        local MaxSoldiers = Logic.LeaderGetMaxNumberOfSoldiers(self.Troops[i]);
        local Soldiers = Logic.LeaderGetNumberOfSoldiers(self.Troops[i]);
        if Soldiers < MaxSoldiers or Health < MaxHealth then
            table.insert(ToRemove, self.Troops[i]);
        end
    end
    return ToRemove;
end

function AiArmy.Internal.Army:Abandon(_KillLater)
    for i= self.Reinforcements[1] +1, 2, -1 do
        local ID = self:RemoveTroop(self.Reinforcements[i]);
        if _KillLater and ID ~= 0 and IsExisting(ID) then
            table.insert(self.CleanUp, ID);
            self.CleanUp[1] = self.CleanUp[1] +1;
        end
    end
    for i= self.Troops[1] +1, 2, -1 do
        local ID = self:RemoveTroop(self.Troops[i]);
        if _KillLater and ID ~= 0 and IsExisting(ID) then
            table.insert(self.CleanUp, ID);
            self.CleanUp[1] = self.CleanUp[1] +1;
        end
    end
end

function AiArmy.Internal.Army:DispatchTroopsToSpawner()
    local RefillerList = AiArmyRefiller.GetRefillersOfArmy(self.ID);
    local RefillerCount = table.getn(RefillerList);
    if RefillerCount == 0 then
        self:Abandon(true);
        return {};
    end
    local WeakenedList = self:GetWeakenedTroops();
    for i= table.getn(WeakenedList), 1, -1 do
        local PossibleRefillerIDs = {};
        for j= RefillerCount, 1, -1 do
            if AiArmyRefiller.CanTroopBeAdded(RefillerList[j], WeakenedList[i]) then
                table.insert(PossibleRefillerIDs, RefillerList[j]);
            end
        end
        if RefillerCount == 1 then
            if AiArmyRefiller.AddTroop(PossibleRefillerIDs[1], WeakenedList[i]) == true then
                AiArmy.RemoveTroop(self.ID, WeakenedList[i]);
            end
        else
            local Index = math.random(1, RefillerCount);
            if AiArmyRefiller.AddTroop(PossibleRefillerIDs[Index], WeakenedList[i]) then
                AiArmy.RemoveTroop(self.ID, WeakenedList[i]);
            end
        end
    end
    return WeakenedList;
end

function AiArmy.Internal.Army:LockOn(_TroopID, _TargetID)
    if _TargetID ~= nil then
        self.Targets[_TroopID] = {_TroopID, _TargetID, Logic.GetTime()};
    else
        for k,v in pairs(self.Targets) do
            if v[1] == _TroopID then
                self.Targets[k] = nil;
            end
        end
    end
end

function AiArmy.Internal.Army:SetActive(_Active)
    self.Active = _Active == true;
end

function AiArmy.Internal.Army:SetTargeting(_Targeting)
    self.Targeting = _Targeting;
end

function AiArmy.Internal.Army:SetRodeLength(_RodeLength)
    self.RodeLength = _RodeLength;
end

function AiArmy.Internal.Army:SetFormationController(_FormationController)
    self.FormationController = _FormationController;
end

function AiArmy.Internal.Army:SetStrength(_Strength)
    self.Strength = _Strength;
end

function AiArmy.Internal.Army:SetAliveThreshold(_Threshold)
    self.DefeatThreshold = _Threshold;
end

function AiArmy.Internal.Army:SetLastTick(_Time)
    self.LastTick = _Time;
end

-- -------------------------------------------------------------------------- --

function AiArmy.Internal.Army:GetNumberOfLeader(_WithReinforcments)
    local Amount = self.Troops[1];
    if _WithReinforcments then
        Amount = Amount + self.Reinforcements[1];
    end
    return Amount;
end

function AiArmy.Internal.Army:GetArmyRotation()
    if self:GetNumberOfLeader(false) > 0 then
        local Orientations = {};
        for i= 2, self.Troops[1] +1 do
            if Logic.IsLeader(self.Troops[i]) == 1 then
                local SoldierList = {Logic.GetSoldiersAttachedToLeader(self.Troops[i])};
                for j= 2, SoldierList[1] +1 do
                    local Orientation = Logic.GetEntityOrientation(SoldierList[j]);
                    table.insert(Orientations, Orientation);
                end
            end
            local Orientation = Logic.GetEntityOrientation(self.Troops[i]);
            table.insert(Orientations, Orientation);
        end
        return AverageAngle(unpack(Orientations));
    end
    return 0;
end

--- @return table
function AiArmy.Internal.Army:GetArmyPosition()
    if self.Troops[1] == 0 then
        return self.HomePosition;
    end
    local Troops = {};
    for i= 2, self.Troops[1] +1, 1 do
        table.insert(Troops, self.Troops[i]);
    end
    return GetGeometricCenter(unpack(Troops));
end

function AiArmy.Internal.Army:IsAlive()
    return self:GetNumberOfLeader(true) > 0 and self:GetCurrentStregth(true) > self.DefeatThreshold;
end

function AiArmy.Internal.Army:GetCurrentStregth(_WithReinforcments)
    local CurStrength = 0;
    local Troops = {};
    for i= 2, self.Troops[1] +1, 1 do
        table.insert(Troops, self.Troops[i]);
    end
    if _WithReinforcments then
        for i= 2, self.Reinforcements[1] +1, 1 do
            table.insert(Troops, self.Reinforcements[i]);
        end
    end
    for i= table.getn(Troops), 1, -1 do
        local StrValue = 1;
        if Logic.IsLeader(Troops[i]) == 1 then
            local MaxSoldiers = Logic.LeaderGetMaxNumberOfSoldiers(Troops[i]);
            if MaxSoldiers > 0 then
                StrValue = (Logic.LeaderGetNumberOfSoldiers(Troops[i])/MaxSoldiers);
            end
        end
        CurStrength = CurStrength + StrValue;
    end
    return CurStrength / self.Strength;
end

function AiArmy.Internal.Army:IsScattered()
    for i= 2, self.Troops[1] +1 do
        if IsExisting(self.Troops[i]) then
            if GetDistance(self:GetArmyPosition(), self.Troops[i]) > 1000 then
                return true;
            end
        end
    end
    return false;
end

function AiArmy.Internal.Army:ChoseFormation(_TroopID)
    if Logic.IsEntityInCategory(_TroopID, EntityCategories.EvilLeader) == 1 then
        return;
    elseif Logic.IsEntityInCategory(_TroopID, EntityCategories.CavalryHeavy) == 1 then
        Logic.LeaderChangeFormationType(_TroopID, 6);
        return;
    end
    Logic.LeaderChangeFormationType(_TroopID, 4);
end

function AiArmy.Internal.Army:NormalizedArmySpeed()
    -- FIXME: Use server functions if available
    local TroopSpeed = 0;
    local AbsoluteTroopAmount = 0;
    local Dividend = 0;
    local TroopSpeedTable = {};
    -- Get unit speeds
    for i= 2, self.Troops[1] +1, 1 do
        local First = self:GetTroopSpeedConfigKey(self.Troops[i]);
        First = (AiArmyConstants.SpeedWeighting[First] and First) or "_Others";
        TroopSpeedTable[First] = TroopSpeedTable[First] or {};
        TroopSpeedTable[First][1] = AiArmyConstants.SpeedWeighting[First];
        TroopSpeedTable[First][2] = (TroopSpeedTable[First][2] or 0) +1;
        AbsoluteTroopAmount = AbsoluteTroopAmount +1;
    end
    -- Calculate army
    for k, v in pairs(TroopSpeedTable) do
        Dividend = Dividend + (v[1]*v[2]*AiArmyConstants.BaseSpeed[k]);
    end
    Dividend = Dividend + AiArmyConstants.SpeedWeighting["_Others"];
    TroopSpeed = Dividend/(AbsoluteTroopAmount+1);
    -- Set speed factor
    for i= 2, self.Troops[1] +1, 1 do
        local First = self:GetTroopSpeedConfigKey(self.Troops[i]);
        local NewSpeed = (TroopSpeed >= 250 and TroopSpeed) or 250;
        self:SetTroopSpeed(self.Troops[i], NewSpeed/AiArmyConstants.BaseSpeed[First]);
    end
end

function AiArmy.Internal.Army:ResetArmySpeed()
    for i= 2, self.Troops[1] +1, 1 do
        self:SetTroopSpeed(self.Troops[i], 1.0);
    end
end

function AiArmy.Internal.Army:SetTroopSpeed(_TroopID, _Factor)
    if IsValidEntity(_TroopID) then
        Logic.SetSpeedFactor(_TroopID, _Factor);
        if Logic.IsLeader(_TroopID) == 1 then
            local Soldiers = {Logic.GetSoldiersAttachedToLeader(_TroopID)};
            for i= 2, Soldiers[1]+1, 1 do
                if IsValidEntity(_TroopID) then
                    Logic.SetSpeedFactor(Soldiers[i], _Factor);
                end
            end
        end
    end
end

function AiArmy.Internal.Army:GetTroopSpeedConfigKey(_TroopID)
    if IsValidEntity(_TroopID) then
        local TypeName = Logic.GetEntityTypeName(Logic.GetEntityType(_TroopID));
        if AiArmyConstants.BaseSpeed[TypeName] then
            return TypeName;
        else
            for k, v in pairs(GetEntityCategoriesAsString(_TroopID)) do
                if AiArmyConstants.BaseSpeed[v] then
                    return v;
                end
            end
        end
    end
    return "_Others";
end

function AiArmy.Internal.Army:DebugSetShowCurrentPosition(_Flag)
    self.Debug.ShowPosition = _Flag == true;
end

function AiArmy.Internal.Army:DebugShowCurrentPosition()
    DestroyEntity(self.Debug.Position);
    if self.Debug.ShowPosition then
        local Position = self:GetArmyPosition();
        local ID = Logic.CreateEntity(Entities.XD_CoordinateEntity, Position.X, Position.Y, 0, self.PlayerID);
        self.Debug.Position = ID;
    end
end

function AiArmy.Internal.Army:IsInitalized()
    return self.Initalized == true;
end

function AiArmy.Internal.Army:SetInitalized(_Value)
    self.Initalized = _Value == true;
end

function AiArmy.Internal.Army:GetKey(_Key)
    return self.Data[_Key];
end

function AiArmy.Internal.Army:SetKey(_Key, _Value)
    self.Data[_Key] = _Value;
end

-- -------------------------------------------------------------------------- --
-- Config

--- Levels of targeting
---
AiArmyTargetingBehavior = {
    Sword = {
        ["Hero"] = 1.0,
        ["Rifle"] = 0.9,
        ["LongRange"] = 0.8,
        ["Cannon"] = 0.6,
        ["Spear"] = 0.4,
        ["DefendableBuilding"] = 0,
        ["CavalryHeavy"] = 0,
        ["CavalryLight"] = 0,
    },
    Spear = {
        ["Hero"] = 1.0,
        ["CavalryHeavy"] = 0.9,
        ["CavalryLight"] = 0.8,
        ["MilitaryBuilding"] = 0.4,
        ["DefendableBuilding"] = 0,
        ["Sword"] = 0,
        ["Cannon"] = 0,
    },
    CavalryHeavy = {
        ["Hero"] = 1.0,
        ["Cannon"] = 0.9,
        ["Rifle"] = 0.8,
        ["LongRange"] = 0.8,
        ["Sword"] = 0.8,
        ["MilitaryBuilding"] = 0,
        ["DefendableBuilding"] = 0,
        ["Spear"] = 0,
    },
    LongRange = {
        ["Hero"] = 1.0,
        ["Cannon"] = 0.9,
        ["CavalryHeavy"] = 0.8,
        ["CavalryLight"] = 0.6,
        ["Spear"] = 0.6,
        ["DefendableBuilding"] = 0,
        ["Rifle"] = 0,
        ["Sword"] = 0,
    },
    Rifle = {
        ["Hero"] = 1.0,
        ["Cannon"] = 0.9,
        ["EvilLeader"] = 0.9,
        ["LongRange"] = 0.8,
        ["Spear"] = 0.7,
        ["CavalryHeavy"] = 0.4,
        ["Sword"] = 0.4,
        ["DefendableBuilding"] = 0,
        ["MilitaryBuilding"] = 0,
    },

    -- Types -----------

    [Entities.PV_Cannon1] = {
        ["Hero"] = 1.0,
        ["CavalryLight"] = 1.0,
        ["EvilLeader"] = 1.0,
        ["LongRange"] = 1.0,
        ["Spear"] = 1.0,
        ["Sword"] = 0.8,
        ["Cannon"] = 0.5,
        ["CavalryHeavy"] = 0.5,
        ["DefendableBuilding"] = 0,
        ["MilitaryBuilding"] = 0,
    },
    [Entities.PV_Cannon2] = {
        ["Hero"] = 1.0,
        ["MilitaryBuilding"] = 1.0,
        ["Cannon"] = 0.5,
        ["EvilLeader"] = 0.3,
        ["LongRange"] = 0.3,
        ["DefendableBuilding"] = 0,
        ["CavalryHeavy"] = 0,
        ["CavalryLight"] = 0,
        ["Sword"] = 0,
        ["Spear"] = 0,
    },
    [Entities.PV_Cannon3] = {
        ["Hero"] = 1.0,
        ["CavalryLight"] = 1.0,
        ["EvilLeader"] = 1.0,
        ["LongRange"] = 1.0,
        ["Spear"] = 1.0,
        ["Sword"] = 0.8,
        ["Cannon"] = 0.5,
        ["CavalryHeavy"] = 0.5,
        ["DefendableBuilding"] = 0,
        ["MilitaryBuilding"] = 0,
    },
    [Entities.PV_Cannon4] = {
        ["Hero"] = 1.0,
        ["MilitaryBuilding"] = 1.0,
        ["Cannon"] = 0.5,
        ["EvilLeader"] = 0.3,
        ["LongRange"] = 0.3,
        ["DefendableBuilding"] = 0,
        ["CavalryHeavy"] = 0,
        ["CavalryLight"] = 0,
        ["Sword"] = 0,
        ["Spear"] = 0,
    },
    -- Becase they are basically siege cannons...
    [Entities.PU_LeaderRifle2] = {
        ["Hero"] = 1.0,
        ["MilitaryBuilding"] = 1.0,
        ["Cannon"] = 0.5,
        ["EvilLeader"] = 0.3,
        ["LongRange"] = 0.3,
        ["DefendableBuilding"] = 0,
        ["CavalryHeavy"] = 0,
        ["CavalryLight"] = 0,
        ["Sword"] = 0,
        ["Spear"] = 0,
    },
}

AiArmyConstants = {
    Targeting = AiArmyTargetingBehavior,

    -- Holds the basic speed of the units.
    BaseSpeed = {
        ["Bow"] = 320,
        ["CavalryLight"] = 500,
        ["CavalryHeavy"] = 500,
        ["Hero"] = 400,
        ["Rifle"] = 320,

        ["PV_Cannon1"] = 240,
        ["PV_Cannon2"] = 260,
        ["PV_Cannon3"] = 220,
        ["PV_Cannon4"] = 180,

        ["_Others"] = 360,
    },

    -- Configures how much a singular base speed influences the calculated
    -- average speed of the army.
    -- The factor must be between 0 and 1.
    SpeedWeighting = {
        ["CavalryLight"] = 0.4,
        ["CavalryHeavy"] = 0.4,

        ["PV_Cannon3"] = 0.3,
        ["PV_Cannon4"] = 0.1,

        ["_Others"] = 1.0
    }
}

