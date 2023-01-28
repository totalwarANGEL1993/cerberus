Lib.Require("module/io/Interaction");
Lib.Register("module/io/NonPlayerCharacter");

--- 
--- NPC interaction script
---
--- Implements an alternative to the vanilla NPC system.
--- 
--- @require Interaction
--- @author totalwarANGEL
--- @version 1.0.0
--- 

NonPlayerCharacter = {}

-- -------------------------------------------------------------------------- --
-- API

--- Creates a new NPC.
---
--- Possible fields for definition:
--- * ScriptName     (Required) ScriptName of NPC
--- * Callback       (Required) Callback for interaction
--- * LookAt         (Optional) NPC looks at hero (Default: true)
--- * Hero           (Optional) ScriptName of hero who can talk to NPC
--- * WrongHeroMsg   (Optional) Wrong hero message
--- * Player         (Optional) Player that can talk to NPC
--- * WrongPlayerMsg (Optional) Wrong player message
---
--- @param _Data table NPC definition table
function NonPlayerCharacter.Create(_Data)
    NonPlayerCharacter.Internal:CreateNpc(_Data);
end

--- Deletes an NPC (but not the settler).
--- @param _ScriptName string ScriptName of NPC
function NonPlayerCharacter.Delete(_ScriptName)
    NonPlayerCharacter.Internal:DeleteNpc(_ScriptName);
end

--- Checks if the character has an active NPC.
--- @param _ScriptName string ScriptName of NPC
--- @return boolean Active NPC is active
function NonPlayerCharacter.IsActive(_ScriptName)
    local Data = Interaction.Internal.Data.IO[_ScriptName];
    return Data and Data.Active == true;
end

--- Activates an existing inactive NPC.
---
--- (The TalkedTo value is reset.)
--- @param _ScriptName string ScriptName of NPC
function NonPlayerCharacter.Activate(_ScriptName)
    Interaction.Internal:Activate(_ScriptName);
end

--- Deactivates an existing active NPC.
--- @param _ScriptName string ScriptName of NPC
function NonPlayerCharacter.Deactivate(_ScriptName)
    Interaction.Internal:Deactivate(_ScriptName);
end

--- Checks if any hero has talked to the NPC.
--- @param _ScriptName string ScriptName of NPC
--- @return boolean TalkedTo Someone talked to NPC
function NonPlayerCharacter.TalkedTo(_ScriptName)
    return NonPlayerCharacter.Internal:TalkedToNpc(_ScriptName);
end

--- Checks if the hero has talked to the NPC.
--- @param _HeroScriptName string ScriptName of Hero
--- @param _NpcScriptName string  ScriptName of NPC
--- @return boolean TalkedTo Hero talked to NPC
function NonPlayerCharacter.HeroTalkedTo(_HeroScriptName, _NpcScriptName)
    local ID = GetID(_HeroScriptName);
    return NonPlayerCharacter.Internal:TalkedToNpc(_NpcScriptName, ID);
end

-- -------------------------------------------------------------------------- --
-- Internal

NonPlayerCharacter.Internal = {
    Data = {},
};

function NonPlayerCharacter.Internal:Install()
    Interaction.Internal:Install();

    if not self.IsInstalled then
        self.IsInstalled = true;

        self:OverrideNpcInteractionCallbacks();
    end
end

function NonPlayerCharacter.Internal:CreateNpc(_Data)
    self:Install();
    Interaction.Internal:CreateNpc(_Data);

    local Data = Interaction.Internal.Data.IO[_Data.ScriptName];
    Data.IsCharacter = true;
    Data.LookAt      = (_Data.LookAt == nil and true) or _Data.LookAt == true;
    Data.Follow      = _Data.Follow;
    Data.Target      = _Data.Target;
    Data.Waypoints   = _Data.Waypoints or {};
    Data.WayCallback = _Data.WayCallback;
    Data.Wanderer    = _Data.StrayPoints or {};
    Data.Waittime    = _Data.Waittime or 0;

    Interaction.Internal.Data.IO[_Data.ScriptName] = Data;
end

function NonPlayerCharacter.Internal:DeleteNpc(_ScriptName)
    Interaction.Internal:DeleteNpc(_ScriptName);
end

function NonPlayerCharacter.Internal:TalkedToNpc(_NpcScriptName, _ID)
    if Interaction.Internal.Data.IO[_NpcScriptName] then
        local Data = Interaction.Internal.Data.IO[_NpcScriptName];
        if Data.TalkedTo then
            if _ID and _ID ~= 0 then
                return Data.TalkedTo == _ID;
            end
            return true;
        end
    end
    return false;
end

function NonPlayerCharacter.Internal:OnNpcActivated(_ScriptName)
    if Interaction.Internal.Data.IO[_ScriptName] then
        local Data = Interaction.Internal.Data.IO[_ScriptName];
        if Data.Waypoints then
            Data.Waypoints.Current = false;
        end
        Data.Arrived = false;
        Data.TalkedTo = nil;

        Interaction.Internal.Data.IO[_ScriptName] = Data;
    end
end

function NonPlayerCharacter.Internal:OnNpcDeactivated(_ScriptName)
end

function NonPlayerCharacter.Internal:OverrideNpcInteractionCallbacks()
    self.Orig_GameCallback_Logic_InteractWithCharacter = GameCallback_Logic_InteractWithCharacter;
    GameCallback_Logic_InteractWithCharacter = function(_HeroID, _NpcID)
        NonPlayerCharacter.Internal.Orig_GameCallback_Logic_InteractWithCharacter(_HeroID, _NpcID);
        local HeroScriptName = Logic.GetEntityName(_HeroID);
        local NpcScriptName = Logic.GetEntityName(_NpcID);
        NonPlayerCharacter.Internal:OnNpcInteraction(NpcScriptName, HeroScriptName);
    end

    self.Orig_GameCallback_Logic_OnTickNpcController = GameCallback_Logic_OnTickNpcController;
    GameCallback_Logic_OnTickNpcController = function(_ScriptName)
        NonPlayerCharacter.Internal.Orig_GameCallback_Logic_OnTickNpcController(_ScriptName);
        NonPlayerCharacter.Internal:OnTickNpcController(_ScriptName);
    end

    self.Orig_GameCallback_Logic_OnNpcActivated = GameCallback_Logic_OnNpcActivated;
    GameCallback_Logic_OnNpcActivated = function(_ScriptName)
        NonPlayerCharacter.Internal.Orig_GameCallback_Logic_OnNpcActivated(_ScriptName);
        NonPlayerCharacter.Internal:OnNpcActivated(_ScriptName);
    end

    self.Orig_GameCallback_Logic_OnNpcDeactivated = GameCallback_Logic_OnNpcDeactivated;
    GameCallback_Logic_OnNpcDeactivated = function(_ScriptName)
        NonPlayerCharacter.Internal.Orig_GameCallback_Logic_OnNpcDeactivated(_ScriptName);
        NonPlayerCharacter.Internal:OnNpcDeactivated(_ScriptName);
    end
end

-- Interaction --

function NonPlayerCharacter.Internal:OnNpcInteraction(_NpcScriptName, _HeroScriptName)
    GUIAction_MerchantReady();

    gvLastInteractionHeroName = _HeroScriptName;
    gvLastInteractionNpcName = _NpcScriptName;

    local HeroID = GetID(_HeroScriptName);
    local NpcID = GetID(_NpcScriptName);
    if Interaction.Internal.Data.IO[_NpcScriptName] then
        local Data = Interaction.Internal.Data.IO[_NpcScriptName];
        if Data.Follow then
            Data = self:OnNpcFolowInteraction(_NpcScriptName, Data, _HeroScriptName);
        elseif table.getn(Data.Waypoints) > 0 then
            Data = self:OnNpcWaypointInteraction(_NpcScriptName, Data, _HeroScriptName);
        elseif table.getn(Data.Wanderer) > 0 then
            if Data.WayCallback then
                Data:WayCallback(HeroID);
            end
        else
            Data = self:OnNpcRegularInteraction(_NpcScriptName, Data, _HeroScriptName);
        end
        Interaction.Internal.Data.IO[_NpcScriptName] = Data;
    end
end

function NonPlayerCharacter.Internal:OnNpcRegularInteraction(_NpcScriptName, _Data, _HeroScriptName)
    local HeroID = GetID(_HeroScriptName);
    local NpcID = GetID(_NpcScriptName);
    if _Data.Hero then
        if HeroID ~= GetID(_Data.Hero) then
            if _Data.WrongHeroMsg then
                Message(_Data.WrongHeroMsg);
            end
            return;
        end
    end
    _Data:Callback(HeroID);
    _Data.TalkedTo = HeroID;
    Interaction.Internal:HeroesLookAtNpc(HeroID, NpcID);
    Interaction.Internal:Deactivate(_NpcScriptName);
    if _Data.LookAt then
        LookAt(_NpcScriptName, _HeroScriptName);
    end
    return _Data;
end

function NonPlayerCharacter.Internal:OnNpcFolowInteraction(_NpcScriptName, _Data, _HeroScriptName)
    local HeroID = GetID(_HeroScriptName);
    local NpcID = GetID(_NpcScriptName);
    if _Data.Target then
        if IsNear(_NpcScriptName, _Data.Target, 1200) then
            _Data:Callback(HeroID);
            _Data.TalkedTo = HeroID;
            Interaction.Internal:HeroesLookAtNpc(HeroID, NpcID);
            Interaction.Internal:Deactivate(_NpcScriptName);
        else
            if _Data.WayCallback then
                _Data:WayCallback(HeroID);
            end
        end
    else
        if _Data.WayCallback then
            _Data:WayCallback(HeroID);
        end
    end
    return _Data;
end

function NonPlayerCharacter.Internal:OnNpcWaypointInteraction(_NpcScriptName, _Data, _HeroScriptName)
    local HeroID = GetID(_HeroScriptName);
    local NpcID = GetID(_NpcScriptName);
    local LastWaypoint = _Data.Waypoints[table.getn(_Data.Waypoints)];
    if IsNear(_Data.ScriptName, LastWaypoint, 1200) then
        _Data:Callback(HeroID);
        _Data.TalkedTo = HeroID;
        Interaction.Internal:HeroesLookAtNpc(HeroID, NpcID);
        Interaction.Internal:Deactivate(_NpcScriptName);
    else
        if _Data.WayCallback then
            _Data:WayCallback(HeroID);
        end
    end
    return _Data;
end

-- Controller --

function NonPlayerCharacter.Internal:OnTickNpcController(_ScriptName)
    if Interaction.Internal.Data.IO[_ScriptName] then
        if Interaction.Internal.Data.IO[_ScriptName].IsCharacter then
            local Data = Interaction.Internal.Data.IO[_ScriptName];

            if Data.Active == true then
                if Data.Follow ~= nil and not Data.Arrived then
                    Data = NonPlayerCharacter.Internal:OnTickNpcFollowController(_ScriptName, Data);
                elseif table.getn(Data.Waypoints) > 0 and not Data.Arrived then
                    Data = NonPlayerCharacter.Internal:OnTickNpcWaypointController(_ScriptName, Data);
                elseif table.getn(Data.Wanderer) > 1 and not Data.Arrived then
                    Data = NonPlayerCharacter.Internal:OnTickNpcWalkerController(_ScriptName, Data);
                else
                    Data.Arrived = true;
                end
            end
            Interaction.Internal.Data.IO[_ScriptName] = Data;
        end
    end
end

function NonPlayerCharacter.Internal:OnTickNpcFollowController(_ScriptName, _Data)
    local FollowID;
    if type(_Data.Follow) == "string" then
        FollowID = GetID(_Data.Follow);
    else
        FollowID = Interaction.Internal:GetNearestHero(2000);
    end
    if FollowID ~= nil and IsAlive(FollowID) then
        if _Data.Target and IsNear(_ScriptName, _Data.Target, 1200) then
            Move(_ScriptName, _Data.Target);
            _Data.Arrived = true;
        end
        if not _Data.Arrived and Logic.IsEntityMoving(GetID(_ScriptName)) == false then
            Move(_ScriptName, FollowID, 500);
        end
    end
    return _Data;
end

function NonPlayerCharacter.Internal:OnTickNpcWaypointController(_ScriptName, _Data)
    _Data.Waypoints.LastTime = _Data.Waypoints.LastTime or 0;
    _Data.Waypoints.Current = _Data.Waypoints.Current or 1;

    local CurrentTime = Logic.GetTime();
    if _Data.Waypoints.LastTime < CurrentTime then
        _Data.Waypoints.LastTime = CurrentTime + (_Data.Waittime or (2*60));
        -- Set waypoint
        if IsNear(_ScriptName, _Data.Waypoints[_Data.Waypoints.Current], _Data.ArrivedDistance or 1200) then
            _Data.Waypoints.Current = _Data.Waypoints.Current +1;
            if _Data.Waypoints.Current > table.getn(_Data.Waypoints) then
                _Data.Arrived = true;
            end
        end
        -- Move to waypoint
        if not _Data.Arrived then
            if Logic.IsEntityMoving(GetID(_ScriptName)) == false then
                Move(_ScriptName, _Data.Waypoints[_Data.Waypoints.Current]);
            end
        end
    end
    return _Data;
end

function NonPlayerCharacter.Internal:OnTickNpcWalkerController(_ScriptName, _Data)
    _Data.Wanderer.LastTime = _Data.Wanderer.LastTime or 0;
    _Data.Wanderer.Current = _Data.Wanderer.Current or 1;

    if not Interaction.Internal:GetNearestHero(2000) then
        local CurrentTime = Logic.GetTime();
        if _Data.Wanderer.LastTime < CurrentTime then
            _Data.Wanderer.LastTime = CurrentTime + (_Data.Waittime or (5*60));
            if IsNear(_ScriptName, _Data.Wanderer[_Data.Wanderer.Current], _Data.ArrivedDistance or 1200) then
                -- Select random waypoint
                local NewWaypoint;
                repeat
                    NewWaypoint = math.random(1, table.getn(_Data.Wanderer));
                until (NewWaypoint ~= _Data.Wanderer.Current);
                _Data.Wanderer.Current = NewWaypoint;

                -- Move to waypoint
                if Logic.IsEntityMoving(GetID(_ScriptName)) == false then
                    Move(_ScriptName, _Data.Wanderer[_Data.Wanderer.Current]);
                end
            end
        end
    end
    return _Data;
end

