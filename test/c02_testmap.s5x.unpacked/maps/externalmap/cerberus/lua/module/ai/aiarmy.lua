Lib.Require("comfort/CopyTable");
Lib.Require("comfort/GetDistance");
Lib.Require("comfort/GetEnemiesInArea");
Lib.Require("comfort/GetEntityCategoriesAsString");
Lib.Require("comfort/GetGeometricCenter");
Lib.Require("comfort/GetReachablePosition");
Lib.Require("comfort/IsFighting");
Lib.Require("comfort/IsValidEntity");
Lib.Require("module/trigger/Job");
Lib.Register("module/ai/AiArmy");

---
--- AI army script
---
--- Creates an army that automatically attacks enemies in reach. It also tries
--- to not focus on a single target and makes use of max range attacks if told
--- to do so via the targeting behavior.
---
--- Everything else is very similar to what default armies are doing. A higher
--- instance of controller is advised but not explicitly required.
---
--- Version 1.3.1
---

AiArmy = AiArmy or {
    --- States the army can be in.
    ---
    --- * `WAITING`  - Army is waiting for orders
    --- * `ADVANCE`  - Army is walking to the target position
    --- * `REGROUP`  - Army is gathering at the currend position
    --- * `BATTLE`   - Army is batteling enemies around the anchor
    --- * `REFILL`   - Army is waiting for full strength
    --- * `FALLBACK` - Army is retreating home unorganized
    Behavior = {
        WAITING = 1,
        ADVANCE = 2,
        REGROUP = 3,
        BATTLE = 4,
        REFILL = 5,
        FALLBACK = 6,
    },
};

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

--- Forcefully changes the behavior of the army.
--- (Do not use unless you know what you are doing!)
--- @param _ID integer    ID of army
--- @param _State integer ID of behavior
function AiArmy.SetBehavior(_ID, _State)
    if AiArmyData_ArmyIdToArmyInstance[_ID] then
        AiArmyData_ArmyIdToArmyInstance[_ID]:SetBehavior(_State);
    end
end

--- Returns the current behavior of the army.
--- @param _ID integer ID of army
--- @return integer ID of behavior
function AiArmy.GetBehavior(_ID)
    if AiArmyData_ArmyIdToArmyInstance[_ID] then
        return AiArmyData_ArmyIdToArmyInstance[_ID].Behavior;
    end
    return 0;
end

--- Changes the target position of the army.
---
--- The army will automatically walk to the position if possible. The army will
--- automatically attack enemies. They do not need a command to do so.
---
--- @param _ID integer     ID of army
--- @param _Position table Target position of army
function AiArmy.SetPosition(_ID, _Position)
    if AiArmyData_ArmyIdToArmyInstance[_ID] then
        local Position = _Position;
        if type(Position) ~= "table" then
            Position = GetPosition(_Position);
        end
        AiArmyData_ArmyIdToArmyInstance[_ID]:SetPosition(Position);
    end
end

--- Returns the current target position of the army.
--- @param _ID integer    ID of army
--- @return table? Target Target position
function AiArmy.GetPosition(_ID)
    if AiArmyData_ArmyIdToArmyInstance[_ID] then
        return AiArmyData_ArmyIdToArmyInstance[_ID].Position;
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

--- Changes the radius of action of the army.
--- 
--- If the anchor for a battle is already set it will still use the old
--- area of action until the battle has concluded.
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
        return Army.Anchor.RodeLength or Army.RodeLength;
    end
    return 0;
end

--- Sets a function that overwrites which formation is given to troops.
--- @param _ID integer          ID of army
--- @param _Controller function Formation controller function
function AiArmy.SetFormationController(_ID, _Controller)
    if AiArmyData_ArmyIdToArmyInstance[_ID] then
        return AiArmyData_ArmyIdToArmyInstance[_ID]:SetFormationController(_Controller);
    end
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

--- Sets the percentage when the army is defeated.
--- @param _Threshold number Defeated threshold
function AiArmy.SetAliveThreshold(_Threshold)
    AiArmy.Internal.Army:SetAliveThreshold(_Threshold)
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

--- Commands an army to hold position. 
--- (Use this inside a job.)
--- @param _ID integer    ID of army
--- @param _Target table Position to defend
function AiArmy.Defend(_ID, _Target)
    if AiArmyData_ArmyIdToArmyInstance[_ID] then
        local Army = AiArmyData_ArmyIdToArmyInstance[_ID];
        Army:SetBehavior(AiArmy.Behavior.WAITING);
        Army:SetPosition(_Target);
    end
end

--- Commands an army to advance to a position. 
--- (Use this inside a job.)
--- @param _ID integer   ID of army
--- @param _Target table Position to attack
function AiArmy.Advance(_ID, _Target)
    if AiArmyData_ArmyIdToArmyInstance[_ID] then
        local Army = AiArmyData_ArmyIdToArmyInstance[_ID];
        Army:SetBehavior(AiArmy.Behavior.ADVANCE);
        Army:SetPosition(_Target);
    end
end

--- Commands an army to retreat to the home position. 
--- @param _ID integer ID of army
function AiArmy.Retreat(_ID)
    if AiArmyData_ArmyIdToArmyInstance[_ID] then
        local Army = AiArmyData_ArmyIdToArmyInstance[_ID];
        Army:SetBehavior(AiArmy.Behavior.ADVANCE);
        Army:SetPosition(Army.HomePosition);
        Army:SetAnchor(nil, nil);
    end
end

--- Commands an army to haistly retreat to the home position. 
--- (Use this inside a job.)
---
--- Enemies are ignored.
---
--- @param _ID integer ID of army
function AiArmy.Fallback(_ID)
    if AiArmyData_ArmyIdToArmyInstance[_ID] then
        local Army = AiArmyData_ArmyIdToArmyInstance[_ID];
        if Army.Position then
            for j= 1, table.getn(Army.Reinforcements) do
                Logic.SettlerStand(Army.Reinforcements[j]);
            end
            for j= 1, table.getn(Army.Troops) do
                Logic.SettlerStand(Army.Troops[j]);
            end
        end
        Army:SetBehavior(AiArmy.Behavior.FALLBACK);
        Army:SetPosition(nil);
        Army:SetAnchor(nil, nil);
        Army:ResetArmySpeed();
    end
end

--- Returns a list of enemies of the army.
--- @param _ID integer          ID of army
--- @param _Position? table     Area center
--- @param _RodeLength? integer Area size
--- @param _Categories? table   List of categories
--- @return table Enemies List of enemies
function AiArmy.GetEnemies(_ID, _Position, _RodeLength, _Categories)
    local Enemies = {};
    if AiArmyData_ArmyIdToArmyInstance[_ID] then
        local Army = AiArmyData_ArmyIdToArmyInstance[_ID];
        local Position = _Position or Army.Anchor.Position or Army.Position or Army.HomePosition;
        local Area = _RodeLength or Army.Anchor.RodeLength or Army.RodeLength;
        Enemies = AiArmy.Internal:GetEnemiesInTerritory(Army.PlayerID, Position, Area, nil, _Categories);
    end
    return Enemies;
end

--- Returns a list of enemies of the army but without walls.
--- @param _ID integer          ID of army
--- @param _Position? table     Area center
--- @param _RodeLength? integer Area size
--- @return table Enemies List of enemies
function AiArmy.GetEnemiesWithoutWalls(_ID, _Position, _RodeLength)
    return AiArmy.GetEnemies(_ID, _Position, _RodeLength, {
        "Cannon", "Headquarters", "Hero", "Leader", "MilitaryBuilding", "Serf","VillageCenter"
    });
end

--- Changes the default how troops target enemies.
---
--- #### Options:
--- `AiArmyTargetingBehavior.Dumb`
--- - Always attack clostest enemy
---
--- `AiArmyTargetingBehavior.Rational`
--- - Select enemies first troop is strong against
--- - Otherwise attack clostest enemy
---
--- `AiArmyTargetingBehavior.Clever`
--- - Select enemies first troop is strong against
--- - Otherwise attack clostest enemy
--- - Avoid enemies if the troop is weak to
---
--- `AiArmyTargetingBehavior.Tactical`
--- - Troops will snipe hostile heroes
--- - Select enemies first troop is strong against
--- - Different levels of prioritization
--- - Avoid enemies if the troop is weak to
function AiArmy.ConfigureGlobalTargeting(_Config)
    AiArmy.Internal:ChangeDefaultTroopTargetingConfig(_Config);
end

--- Configures targeting for a specific army.
---
--- #### Options:
--- `AiArmyTargetingBehavior.Dumb`
--- - Always attack clostest enemy
---
--- `AiArmyTargetingBehavior.Rational`
--- - Select enemies first the troop is strong against
--- - Otherwise attack clostest enemy
---
--- `AiArmyTargetingBehavior.Clever`
--- - Select enemies first the troop is strong against
--- - Otherwise attack clostest enemy
--- - Avoid enemies if the troop is weak to
---
--- `AiArmyTargetingBehavior.Tactical`
--- - Troops will snipe hostile heroes
--- - Select enemies first the troop is strong against
--- - Different levels of prioritization
--- - Avoid enemies if the troop is weak to
--- @param _ID integer ID of army
--- @param _Config table Configuration
function AiArmy.ConfigureTargeting(_ID, _Config)
    if AiArmyData_ArmyIdToArmyInstance[_ID] then
        AiArmyData_ArmyIdToArmyInstance[_ID]:SetTargeting(_Config);
    end
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

function AiArmy.Internal:IsTroopAlive(_TroopID)
    if not IsExisting(_TroopID) then
        return false;
    end
    local Task = Logic.GetCurrentTaskList(_TroopID);
    if Task and string.find(Task, "DIE") then
        return false;
    end
    return Logic.GetEntityHealth(_TroopID) > 0;
end

function AiArmy.Internal:IsTroopFighting(_TroopID)
    return IsFighting(_TroopID);
end

function AiArmy.Internal:IsTroopTraining(_TroopID)
    local Task = Logic.GetCurrentTaskList(_TroopID);
    if Task and string.find(Task, "TRAIN") then
        return true;
    end
    return false;
end

function AiArmy.Internal:IsTroopMoving(_TroopID)
    return Logic.IsEntityMoving(_TroopID) == true;
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
        Army:ManageArmyMembers();

        if not Army:IsAlive() and Army.Behavior ~= AiArmy.Behavior.FALLBACK then
            for j= 1, table.getn(Army.Reinforcements) do
                Logic.SettlerStand(Army.Reinforcements[j]);
            end
            for j= 1, table.getn(Army.Troops) do
                Logic.SettlerStand(Army.Troops[j]);
            end
            Army:SetBehavior(AiArmy.Behavior.FALLBACK);
            Army:SetAnchor(nil, nil);
            Army:SetPosition(nil);
            Army:ResetArmySpeed();
            return;
        end
        Army:DebugShowCurrentPosition();

        if Army.Behavior == AiArmy.Behavior.WAITING then
            Army:WaitBehavior();
        elseif Army.Behavior == AiArmy.Behavior.REFILL then
            Army:RefillBehavior();
        elseif Army.Behavior == AiArmy.Behavior.ADVANCE then
            Army:AdvanceBehavior();
        elseif Army.Behavior == AiArmy.Behavior.BATTLE then
            Army:BattleBehavior();
        elseif Army.Behavior == AiArmy.Behavior.REGROUP then
            Army:RegroupBehavior();
        elseif Army.Behavior == AiArmy.Behavior.FALLBACK then
            Army:FallbackBehavior();
        end
    end
end

-- Checks for enemies in the area and removes not reachable.
function AiArmy.Internal:GetEnemiesInTerritory(_PlayerID, _Position, _Area, _TroopID, _CategoryList)
    local AreaCenter;
    local Enemies = {};

    -- Check in vecinity of troop
    if _TroopID and IsExisting(_TroopID) then
        if AreEntitiesOfDiplomacyStateInArea(_PlayerID, GetPosition(_TroopID), math.min(_Area,3000), Diplomacy.Hostile, _CategoryList) then
            AreaCenter = GetPosition(_TroopID);
        end
    -- Check in vecinity of position
    else
        if not AreEntitiesOfDiplomacyStateInArea(_PlayerID, _Position, math.min(_Area,3000), Diplomacy.Hostile, _CategoryList) then
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
        or not Logic.CheckEntitiesDistance(AreaCenterID, Enemies[i], _Area)
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
    return self:GetEnemiesInTerritory(_PlayerID, _Position, _Area, _TroopID, CategoryList);
end

function AiArmy.Internal:GetEnemiesNoFortificationFilter(_PlayerID, _Position, _Area, _TroopID)
    local CategoryList = {"Cannon", "DefendableBuilding", "Hero", "Leader", "MilitaryBuilding", "Serf"};
    return self:GetEnemiesInTerritory(_PlayerID, _Position, _Area, _TroopID, CategoryList);
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

function AiArmy.Internal:ChangeDefaultTroopTargetingConfig(_Config)
    AiArmyConstants.Targeting = _Config;
end

-- -------------------------------------------------------------------------- --
-- Model

AiArmy.Internal.Army = AiArmy.Internal.Army or {
    ID               = 0,
    Active           = true,
    Initalized       = false,
    PlayerID         = 1,
    Behavior         = 0;
    Strength         = 8,
    RodeLength  	 = 3000,
    HomePosition     = nil,
    Position         = nil,
    DefeatThreshold  = 0.20,
    LastTick         = 0,

    Targeting        = nil,
    Targets          = {},
    Reinforcements   = {},
    Troops           = {},
    CleanUp          = {},

    Data             = {},
    Anchor           = {
        Position     = nil,
        RodeLength   = nil,
    },
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
    Army.Behavior = AiArmy.Behavior.WAITING;
    --- @diagnostic disable-next-line: undefined-field
    Army.Tick = math.mod(self.ID, 10);
    Army.HomePosition = _Position;
    Army.RodeLength = _RodeLength;
    Army.Strength = _Strength;
    Army.FormationController = nil;
    return Army;
end

function AiArmy.Internal.Army:Dispose()
    self:Abadon(false);
    AiArmyData_ArmyIdToArmyInstance[self.ID] = nil;
end

-- -------------------------------------------------------------------------- --

--- Army is waiting to be refilled.
---
--- * Enemies found
---   - Set behavior: AiArmy.Behavior.BATTLE
---   - Set anchor: Enemy position
--- * Troops scattered
---   - Move troops to army center
function AiArmy.Internal.Army:WaitBehavior()
    self:ResetArmySpeed();
    local ArmyPosition = self:GetArmyPosition();
    local Enemies = AiArmy.Internal:GetEnemiesInTerritory(self.PlayerID, ArmyPosition, self.RodeLength);
    if Enemies[1] then
        self:SetBehavior(AiArmy.Behavior.BATTLE);
        self:SetAnchor(GetPosition(Enemies[1]), self.RodeLength);
    else
        if self:IsScattered() then
            local Position = (self.Position ~= nil and self.Position) or ArmyPosition;
            local Reachable = GetReachablePosition(self.Troops[1], Position);
            for j= 1, table.getn(self.Troops) do
                Logic.MoveSettler(self.Troops[j], Reachable.X, Reachable.Y);
            end
        end
    end
end

--- Army haistly retreats to home position.
---
--- * Not close to home
---   - Troops move to home position
function AiArmy.Internal.Army:FallbackBehavior()
    if GetDistance(self:GetArmyPosition(), self.HomePosition) > 1000 then
        for j= 1, table.getn(self.Troops) do
            if Logic.IsEntityMoving(self.Troops[j]) == false then
                ---@diagnostic disable-next-line: undefined-field
                Logic.MoveSettler(self.Troops[j], self.HomePosition.X, self.HomePosition.Y);
            end
        end
    else
        for j= 1, table.getn(self.Troops) do
            --- @diagnostic disable-next-line: undefined-field
            Logic.MoveSettler(self.Troops[j], self.HomePosition.X, self.HomePosition.Y);
        end
        self:SetBehavior(AiArmy.Behavior.REFILL);
    end
end

--- Army is waiting to be refilled.
---
--- Soldiers of weakened troops will be refilled at the home position.
--- 
--- * Enemies found
---   - Set behavior: AiArmy.Behavior.BATTLE
---   - Set anchor: Enemy position
--- * Army full
---   - Set behavior: AiArmy.Behavior.WAITING
function AiArmy.Internal.Army:RefillBehavior()
    self:ResetArmySpeed();
    local ArmyPosition = self:GetArmyPosition();
    local Enemies = AiArmy.Internal:GetEnemiesInTerritory(self.PlayerID, ArmyPosition, self.RodeLength);
    if Enemies[1] then
        self:SetBehavior(AiArmy.Behavior.BATTLE);
        self:SetAnchor(ArmyPosition, self.RodeLength);
    else
        if self:GetCurrentStregth() >= 1 then
            self:SetBehavior(AiArmy.Behavior.WAITING);
        else
            for i= table.getn(self.Troops), 1, -1 do
                -- Move to home position
                if  Logic.IsEntityMoving(self.Troops[i]) == false
                and GetDistance(self.Troops[i], self.HomePosition) > 1000 then
                    --- @diagnostic disable-next-line: undefined-field
                    Logic.MoveSettler(self.Troops[i], self.HomePosition.X, self.HomePosition.Y);
                end
                -- Respawn soldiers
                if not IsFighting(self.Troops[i])
                and GetDistance(self.Troops[i], self.HomePosition) <= 1500 then
                    local MaxAmount = Logic.LeaderGetMaxNumberOfSoldiers(self.Troops[i]);
                    local CurAmount = Logic.LeaderGetNumberOfSoldiers(self.Troops[i]);
                    if MaxAmount > CurAmount then
                        Tools.CreateSoldiersForLeader(self.Troops[i], 1);
                    end
                end
            end
        end
    end
end

--- Army is advancing to the position.
---
--- * Enemies found
---   - Set behavior: AiArmy.Behavior.BATTLE
---   - Set anchor: Enemy position
---   - Calls battle behavior immediately
--- * Scattered while walking
---   - Set behavior: AiArmy.Behavior.REGROUP
---   - Calls regroup behavior immediately
--- * Move to positon
---   - Walk to position
--- * Position reached
---   - Set behavior: AiArmy.Behavior.WAITING
function AiArmy.Internal.Army:AdvanceBehavior()
    self:NormalizedArmySpeed();
    local ArmyPosition = self:GetArmyPosition();

    local EncounteredEnemy = 0;
    for j= 1, table.getn(self.Troops) do
        -- Check is blocked
        local Exploration = Logic.GetEntityExplorationRange(self.Troops[j]) + 8;
        local SearchFortification = false;
        if self.Position ~= nil and not ArePositionsConnected(ArmyPosition, self.Position) then
            SearchFortification = true;
        end
        -- Search enemies
        local Enemies = {};
        if SearchFortification then
            Enemies = AiArmy.Internal:GetEnemiesFortificationFilter(self.PlayerID, GetPosition(self.Troops[j]), Exploration * 100);
        else
            Enemies = AiArmy.Internal:GetEnemiesNoFortificationFilter(self.PlayerID, GetPosition(self.Troops[j]), Exploration * 100);
        end
        if Enemies[1] then
            EncounteredEnemy = Enemies[1];
            break;
        end
    end

    if EncounteredEnemy ~= 0 then
        self:SetBehavior(AiArmy.Behavior.BATTLE);
        local Reachable = GetReachablePosition(self.Troops[1], EncounteredEnemy, self.Troops[1]);
        self:SetAnchor(Reachable, self.RodeLength);
        self:BattleBehavior();
    else
        if self:IsScattered() then
            self:SetBehavior(AiArmy.Behavior.REGROUP);
            self:RegroupBehavior();
            return;
        elseif self.Position == nil then
            self:SetBehavior(AiArmy.Behavior.WAITING);
        else
            local Reachable = GetReachablePosition(self.Troops[1], ArmyPosition, self.Troops[1]);
            if GetDistance(Reachable, self.Position) > 1000 then
                for j= 1, table.getn(self.Troops) do
                    if Logic.IsEntityMoving(self.Troops[j]) == false then
                        Logic.MoveSettler(self.Troops[j], self.Position.X, self.Position.Y);
                    end
                end
            else
                self:SetBehavior(AiArmy.Behavior.WAITING);
                self:SetPosition(nil);
            end
        end
    end
end

--- Controls the battle against enemies.
--- 
--- * No enemies found
---   - Set behavior: AiArmy.Behavior.REGROUP
---   - Delete anchor
--- * Battle the enemies
---   - Each troop searches enemies
---   - Move troop to anchor if to far apart
---   - Move troop to anchor if no enemy
function AiArmy.Internal.Army:BattleBehavior()
    local ArmyPosition = self:GetArmyPosition();

    -- Check is blocked
    local SearchFortification = false;
    if self.Position ~= nil and not ArePositionsConnected(ArmyPosition, self.Position) then
        SearchFortification = true;
    end
    -- Search enemies
    local Enemies = {};
    if SearchFortification then
        Enemies = AiArmy.Internal:GetEnemiesFortificationFilter(self.PlayerID, self.Anchor.Position, self.Anchor.RodeLength);
    else
        Enemies = AiArmy.Internal:GetEnemiesNoFortificationFilter(self.PlayerID, self.Anchor.Position, self.Anchor.RodeLength);
    end

    if not Enemies[1] then
        self:SetAnchor(nil, nil);
        self:SetBehavior(AiArmy.Behavior.REGROUP);
    else
        self:ResetArmySpeed();
        for j= 1, table.getn(self.Troops) do
            if GetDistance(self.Anchor.Position, self.Troops[j]) > self.Anchor.RodeLength then
                --- @diagnostic disable-next-line: undefined-field
                Logic.MoveSettler(self.Troops[j], self.Anchor.Position.X, self.Anchor.Position.Y);
                self:LockOn(self.Troops[j], nil);
            else
                if not self.Targets[self.Troops[j]] then
                    -- -- Check is blocked
                    -- SearchFortification = false;
                    -- if self.Position ~= nil and not ArePositionsConnected(ArmyPosition, self.Anchor.Position) then
                    --     SearchFortification = true;
                    -- end
                    -- -- Search enemies
                    -- if SearchFortification then
                    --     Enemies = AiArmy.Internal:GetEnemiesFortificationFilter(self.PlayerID, self.Anchor.Position, self.Anchor.RodeLength, self.Troops[j]);
                    -- else
                    --     Enemies = AiArmy.Internal:GetEnemiesNoFortificationFilter(self.PlayerID, self.Anchor.Position, self.Anchor.RodeLength, self.Troops[j]);
                    -- end
                    -- Attack enemies
                    if Enemies[1] then
                        local TargetID = AiArmy.Internal:PriorityTarget(self.Troops[j], Enemies);
                        self:LockOn(self.Troops[j], TargetID);
                        Logic.GroupAttack(self.Troops[j], TargetID);
                    else
                        if GetDistance(ArmyPosition, self.Anchor.Position) > 1000 then
                            --- @diagnostic disable-next-line: undefined-field
                            Logic.MoveSettler(self.Troops[j], self.Anchor.Position.X, self.Anchor.Position.Y);
                        end
                    end
                end
            end
        end
    end
end

--- Controls the regrouping of the army.
---
--- * Enemies encountered
---   - Set behavior: AiArmy.Behavior.BATTLE
---   - Set anchor: Position of enemy
--- * Army is scattered
---   - Move troops to army center
--- * Army in formation
---   - If army has position --> AiArmy.Behavior.ADVANCE
---   - If not --> AiArmy.Behavior.WAITING
function AiArmy.Internal.Army:RegroupBehavior()
    local ArmyPosition = self:GetArmyPosition();
    self:NormalizedArmySpeed();
    local Enemies = AiArmy.Internal:GetEnemiesInTerritory(self.PlayerID, ArmyPosition, self.RodeLength);
    if Enemies[1] then
        self:SetBehavior(AiArmy.Behavior.BATTLE);
        self:SetAnchor(ArmyPosition, self.RodeLength);
    else
        if self:IsScattered() then
            local Reachable = GetReachablePosition(self.Troops[1], ArmyPosition);
            for j= 1, table.getn(self.Troops) do
                Logic.MoveSettler(self.Troops[j], Reachable.X, Reachable.Y);
            end
        else
            if self.Position then
                self:SetBehavior(AiArmy.Behavior.ADVANCE);
            else
                self:SetBehavior(AiArmy.Behavior.WAITING);
            end
        end
    end
end

-- -------------------------------------------------------------------------- --

function AiArmy.Internal.Army:ChangePlayer(_PlayerID)
    -- Change troops
    local Troops = {};
    for k,v in pairs(self.Troops) do
        local ID = ChangePlayer(v, _PlayerID);
        table.insert(Troops, ID);
    end
    self.Troops = Troops;
    -- Change reinforcement
    local Reinforcements = {};
    for k,v in pairs(self.Troops) do
        local ID = ChangePlayer(v, _PlayerID);
        table.insert(Reinforcements, ID);
    end
    self.Reinforcements = Reinforcements;
    -- Save player
    self.PlayerID = _PlayerID;
end

function AiArmy.Internal.Army:ManageArmyMembers()
    -- Update reinforcements
    for j= table.getn(self.Reinforcements), 1, -1 do
        if not AiArmy.Internal:IsTroopAlive(self.Reinforcements[j]) then
            local ID = table.remove(self.Reinforcements, j);
            AiArmyData_ReinforcementIdToArmyId[ID] = nil;
        elseif GetDistance(self.Reinforcements[j], self:GetArmyPosition()) <= 2000 then
            local ID = table.remove(self.Reinforcements, j);
            AiArmyData_ReinforcementIdToArmyId[ID] = nil;
            self:AddTroop(ID, false);
        else
            if Logic.IsEntityMoving(self.Reinforcements[j]) == false then
                local Position = self:GetArmyPosition();
                local Reachable = GetReachablePosition(self.Troops[1], Position, self.HomePosition);
                Logic.GroupAttackMove(self.Reinforcements[j], Reachable.X, Reachable.Y);
            end
        end
    end

    -- Update current troops
    for j= table.getn(self.Troops), 1, -1 do
        if not AiArmy.Internal:IsTroopAlive(self.Troops[j]) then
            self:LockOn(self.Troops[j], nil);
            local ID = table.remove(self.Troops, j);
            AiArmyData_TroopIdToArmyId[ID] = nil;
        end
    end

    -- Update troop cleanup
    for j= table.getn(self.CleanUp), 1, -1 do
        local Alive = AiArmy.Internal:IsTroopAlive(self.CleanUp[j]);
        local Fighting = AiArmy.Internal:IsTroopFighting(self.CleanUp[j]);
        local Moving = AiArmy.Internal:IsTroopMoving(self.CleanUp[j]);
        if not Alive or not Fighting or not Moving then
            AiArmyData_TroopIdToArmyId[ID] = nil;
            local ID = table.remove(self.CleanUp, j);
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
    for j= table.getn(self.Targets), 1, -1 do
        if not AiArmy.Internal:IsTroopAlive(self.Targets[j][2])
        or self.Targets[j][3] == nil
        or Logic.GetTime() > self.Targets[j][3]+15 then
            table.remove(self.Targets, j);
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

        if AiArmy.Internal:IsTroopAlive(_ID) then
            -- AI.Army_EnableLeaderAi(_ID, 0);
            if self.FormationController then
                self:FormationController(_ID);
            else
                self:ChoseFormation(_ID);
            end
        end
        if _Reinforcement then
            AiArmyData_ReinforcementIdToArmyId[_ID] = self.ID;
            table.insert(self.Reinforcements, _ID);
        else
            AiArmyData_TroopIdToArmyId[_ID] = self.ID;
            table.insert(self.Troops, _ID);
        end
        if not self:IsInitalized() then
            self:SetInitalized(self:GetCurrentStregth(true) >= 1);
        end
        return true;
    end
    return false;
end

function AiArmy.Internal.Army:RemoveTroop(_ID)
    for i= table.getn(self.Reinforcements), 1, -1 do
        if self.Reinforcements[i] == _ID then
            -- if AiArmy.Internal:IsTroopAlive(_ID) then
            --     AI.Army_EnableLeaderAi(_ID, 1);
            -- end
            AiArmyData_ReinforcementIdToArmyId[_ID] = nil;
            return table.remove(self.Troops, i);
        end
    end
    for i= table.getn(self.Troops), 1, -1 do
        if self.Troops[i] == _ID then
            -- if AiArmy.Internal:IsTroopAlive(_ID) then
            --     AI.Army_EnableLeaderAi(_ID, 1);
            -- end
            AiArmyData_TroopIdToArmyId[_ID] = nil;
            return table.remove(self.Troops, i);
        end
    end
    return 0;
end

function AiArmy.Internal.Army:GetWeakenedTroops()
    local Removed = {};
    for i= table.getn(self.Reinforcements), 1, -1 do
        local MaxHealth = Logic.GetEntityMaxHealth(self.Reinforcements[i]);
        local Health = Logic.GetEntityHealth(self.Reinforcements[i]);
        local MaxSoldiers = Logic.LeaderGetMaxNumberOfSoldiers(self.Reinforcements[i]);
        local Soldiers = Logic.LeaderGetNumberOfSoldiers(self.Reinforcements[i]);
        if Soldiers < MaxSoldiers or Health < MaxHealth then
            table.insert(Removed, self.Troops[i]);
        end
    end
    for i= table.getn(self.Troops), 1, -1 do
        local MaxHealth = Logic.GetEntityMaxHealth(self.Troops[i]);
        local Health = Logic.GetEntityHealth(self.Troops[i]);
        local MaxSoldiers = Logic.LeaderGetMaxNumberOfSoldiers(self.Troops[i]);
        local Soldiers = Logic.LeaderGetNumberOfSoldiers(self.Troops[i]);
        if Soldiers < MaxSoldiers or Health < MaxHealth then
            table.insert(Removed, self.Troops[i]);
        end
    end
    return Removed;
end

function AiArmy.Internal.Army:Abadon(_KillLater)
    for i= table.getn(self.Reinforcements), 1, -1 do
        local ID = self:RemoveTroop(self.Reinforcements[i]);
        if _KillLater and ID ~= 0 and IsExisting(ID) then
            table.insert(self.CleanUp, ID);
        end
    end
    for i= table.getn(self.Troops), 1, -1 do
        local ID = self:RemoveTroop(self.Troops[i]);
        if _KillLater and ID ~= 0 and IsExisting(ID) then
            table.insert(self.CleanUp, ID);
        end
    end
end

function AiArmy.Internal.Army:LockOn(_TroopID, _TargetID)
    if _TargetID ~= nil then
        table.insert(self.Targets, {_TroopID, _TargetID, Logic.GetTime()});
    else
        for i= table.getn(self.Targets), 1, -1 do
            if self.Targets[i][1] == _TroopID then
                table.remove(self.Targets, i);
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

function AiArmy.Internal.Army:SetBehavior(_State)
    self.Behavior = _State;
end

function AiArmy.Internal.Army:SetPosition(_Position)
    self.Position = _Position;
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

function AiArmy.Internal.Army:SetAnchor(_Position, _RodeLength)
    self.Anchor.RodeLength = _RodeLength;
    self.Anchor.Position = _Position;
end

function AiArmy.Internal.Army:SetLastTick(_Time)
    self.LastTick = _Time;
end

function AiArmy.Internal.Army:GetNumberOfLeader(_WithReinforcments)
    local Amount = table.getn(self.Troops);
    if _WithReinforcments then
        Amount = Amount + table.getn(self.Reinforcements);
    end
    return Amount;
end

--- @return table
function AiArmy.Internal.Army:GetArmyPosition()
    if self.Behavior ~= AiArmy.Behavior.REFILL then
        if self:GetNumberOfLeader(false) > 0 then
            return GetGeometricCenter(unpack(self.Troops)) or self.HomePosition;
        end
    end
    return self.HomePosition;
end

function AiArmy.Internal.Army:IsAlive()
    return self:GetNumberOfLeader(true) > 0 and self:GetCurrentStregth(true) > self.DefeatThreshold;
end

function AiArmy.Internal.Army:GetCurrentStregth(_WithReinforcments)
    local CurStrength = 0;
    local Troops = CopyTable(self.Troops, {});
    if _WithReinforcments then
        Troops = CopyTable(self.Reinforcements, Troops);
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
    for i= 1, table.getn(self.Troops) do
        if IsExisting(self.Troops[i]) then
            if GetDistance(self:GetArmyPosition(), self.Troops[i]) > 1500 then
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
    for i= 1, table.getn(self.Troops), 1 do
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
    for i= 1, table.getn(self.Troops), 1 do
        local First = self:GetTroopSpeedConfigKey(self.Troops[i]);
        local NewSpeed = (TroopSpeed >= 250 and TroopSpeed) or 250;
        self:SetTroopSpeed(self.Troops[i], NewSpeed/AiArmyConstants.BaseSpeed[First]);
    end
end

function AiArmy.Internal.Army:ResetArmySpeed()
    for i= 1, table.getn(self.Troops), 1 do
        self:SetTroopSpeed(self.Troops[i], 1.0);
    end
end

function AiArmy.Internal.Army:SetTroopSpeed(_TroopID, _Factor)
    if AiArmy.Internal:IsTroopAlive(_TroopID) then
        Logic.SetSpeedFactor(_TroopID, _Factor);
        if Logic.IsLeader(_TroopID) == 1 then
            local Soldiers = {Logic.GetSoldiersAttachedToLeader(_TroopID)};
            for i= 2, Soldiers[1]+1, 1 do
                if AiArmy.Internal:IsTroopAlive(_TroopID) then
                    Logic.SetSpeedFactor(Soldiers[i], _Factor);
                end
            end
        end
    end
end

function AiArmy.Internal.Army:GetTroopSpeedConfigKey(_TroopID)
    if AiArmy.Internal:IsTroopAlive(_TroopID) then
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
    if self.Debug.Active then
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
--- `Dumb`
--- * Target clostest enemy
---
--- `Rational`
--- * Target enemies weak to unit first
---
--- `Clever`
--- * Target enemies weak to unit first
--- * Aviod enemies unit is weak to
---
--- `Tactical`
--- * Snipe heroes first
--- * Target enemies weak to unit first
--- * Use different target priorities
--- * Aviod enemies unit is weak to
---
AiArmyTargetingBehavior = {
    Dumb = {},
    Rational = {
        Sword = {
            ["Rifle"] = 1.0,
            ["LongRange"] = 1.0,
            ["Spear"] = 1.0,
            ["DefendableBuilding"] = 0,
        },
        Spear = {
            ["CavalryHeavy"] = 1.0,
            ["DefendableBuilding"] = 0,
        },
        CavalryHeavy = {
            ["Cannon"] = 1.0,
            ["LongRange"] = 1.0,
            ["Rifle"] = 1.0,
            ["DefendableBuilding"] = 0,
        },
        LongRange = {
            ["Cannon"] = 1.0,
            ["CavalryHeavy"] = 1.0,
            ["CavalryLight"] = 1.0,
            ["DefendableBuilding"] = 0,
        },
        Rifle = {
            ["EvilLeader"] = 1.0,
            ["LongRange"] = 1.0,
            ["DefendableBuilding"] = 0,
        },
        Cannon = {
            ["MilitaryBuilding"] = 1.0,
            ["LongRange"] = 1.0,
            ["DefendableBuilding"] = 0,
        },
    },
    Clever = {
        Sword = {
            ["Rifle"] = 1.0,
            ["LongRange"] = 1.0,
            ["Spear"] = 1.0,
            ["DefendableBuilding"] = 0,
            ["CavalryHeavy"] = 0,
            ["CavalryLight"] = 0,
        },
        Spear = {
            ["CavalryHeavy"] = 1.0,
            ["CavalryLight"] = 1.0,
            ["MilitaryBuilding"] = 1.0,
            ["DefendableBuilding"] = 0,
            ["Sword"] = 0,
            ["Cannon"] = 0,
        },
        CavalryHeavy = {
            ["Cannon"] = 1.0,
            ["LongRange"] = 1.0,
            ["Sword"] = 1.0,
            ["DefendableBuilding"] = 0,
            ["MilitaryBuilding"] = 0,
            ["Spear"] = 0,
        },
        LongRange = {
            ["Cannon"] = 1.0,
            ["CavalryHeavy"] = 1.0,
            ["Spear"] = 1.0,
            ["DefendableBuilding"] = 0,
            ["Rifle"] = 0,
            ["Sword"] = 0,
        },
        Rifle = {
            ["EvilLeader"] = 1.0,
            ["LongRange"] = 1.0,
            ["Spear"] = 1.0,
            ["DefendableBuilding"] = 0,
            ["MilitaryBuilding"] = 0,
        },
        Cannon = {
            ["MilitaryBuilding"] = 1.0,
            ["LongRange"] = 1.0,
            ["Rifle"] = 1.0,
            ["DefendableBuilding"] = 0,
            ["CavalryLight"] = 1.0,
            ["CavalryHeavy"] = 0,
        },
    },
    Tactical = {
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
    },
}

AiArmyConstants = {
    Targeting = AiArmyTargetingBehavior.Rational,

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

