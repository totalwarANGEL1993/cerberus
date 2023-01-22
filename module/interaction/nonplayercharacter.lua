Lib.Require("module/interaction/Interaction");
Lib.Register("module/interaction/NonPlayerCharacter");

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

--- Installs the interaction controller.
--- (Must be called on game start!)
function NonPlayerCharacter.Install()
    Interaction.Install();
    NonPlayerCharacter.Internal:Install();
end

--- Creates a new NPC.
---
--- Possible fields for definition:
--- * ScriptName     (Required) Scriptname of NPC
--- * Callback       (Required) Callback for interaction
--- * Hero           (Optional) Scriptname of hero who can talk to NPC
--- * WrongHeroMsg   (Optional) Wrong hero message
--- * Player         (Optional) Player that can talk to NPC
--- * WrongPlayerMsg (Optional) Wrong player message
---
--- @param _Data table NPC definition table
function NonPlayerCharacter.Create(_Data)
    NonPlayerCharacter.Internal:CreateNpc(_Data);
end

--- Deletes an NPC (but not the settler).
--- @param _Scriptname string Scriptname of NPC
function NonPlayerCharacter.Delete(_Scriptname)
    NonPlayerCharacter.Internal:DeleteNpc(_Scriptname);
end

--- Checks if the character has an active NPC.
--- @param _Scriptname string Scriptname of NPC
--- @return boolean Active NPC is active
function NonPlayerCharacter.IsActive(_Scriptname)
    local Data = Interaction.Internal.Data.IO[_Scriptname];
    return Data and Data.Active == true;
end

--- Activates an existing inactive NPC.
--- (The TalkedTo value is reset.)
--- @param _Scriptname string Scriptname of NPC
function NonPlayerCharacter.Activate(_Scriptname)
    Interaction.Internal:Activate(_Scriptname);
end

--- Deactivates an existing active NPC.
--- @param _Scriptname string Scriptname of NPC
function NonPlayerCharacter.Deactivate(_Scriptname)
    Interaction.Internal:Deactivate(_Scriptname);
end

--- Checks if any hero has talked to the NPC.
--- @param _Scriptname string Scriptname of NPC
--- @return boolean TalkedTo Someone talked to NPC
function NonPlayerCharacter.TalkedTo(_Scriptname)
    return NonPlayerCharacter.Internal:TalkedToNpc(_Scriptname);
end

--- Checks if the hero has talked to the NPC.
--- @param _HeroScriptName string Scriptname of Hero
--- @param _NpcScriptname string  Scriptname of NPC
--- @return boolean TalkedTo Hero talked to NPC
function NonPlayerCharacter.HeroTalkedTo(_HeroScriptName, _NpcScriptname)
    local ID = GetID(_HeroScriptName);
    return NonPlayerCharacter.Internal:TalkedToNpc(_NpcScriptname, ID);
end

-- -------------------------------------------------------------------------- --
-- Internal

NonPlayerCharacter.Internal = {
    Data = {},
};

function NonPlayerCharacter.Internal:Install()
    if not self.IsInstalled then
        self.IsInstalled = true;

        self:OverrideNpcInteractionCallbacks();
    end
end

function NonPlayerCharacter.Internal:CreateNpc(_Data)
    Interaction.Internal:CreateNpc(_Data);

    local Data = Interaction.Internal.Data.IO[_Data.Scriptname];
    Data.IsCharacter = true;
    Data.Follow      = _Data.Follow;
    Data.Target      = _Data.Target;
    Data.Waypoints   = _Data.Waypoints or {};
    Data.WayCallback = _Data.WayCallback;
    Data.Wanderer    = _Data.StrayPoints or {};
    Data.Waittime    = _Data.Waittime or 0;

    Interaction.Internal.Data.IO[_Data.Scriptname] = Data;
end

function NonPlayerCharacter.Internal:DeleteNpc(_Scriptname)
    Interaction.Internal:DeleteNpc(_Scriptname);
end

function NonPlayerCharacter.Internal:TalkedToNpc(_NpcScriptname, _ID)
    if Interaction.Internal.Data.IO[_NpcScriptname] then
        local Data = Interaction.Internal.Data.IO[_NpcScriptname];
        if Data.TalkedTo then
            if _ID and _ID ~= 0 then
                return Data.TalkedTo == _ID;
            end
            return true;
        end
    end
    return false;
end

function NonPlayerCharacter.Internal:OnNpcActivated(_Scriptname)
    if Interaction.Internal.Data.IO[_Scriptname] then
        local Data = Interaction.Internal.Data.IO[_Scriptname];
        if Data.Waypoints then
            Data.Waypoints.Current = false;
        end
        Data.Arrived = false;
        Data.TalkedTo = nil;

        Interaction.Internal.Data.IO[_Scriptname] = Data;
    end
end

function NonPlayerCharacter.Internal:OnNpcDeactivated(_Scriptname)
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
    GameCallback_Logic_OnTickNpcController = function(_Scriptname)
        NonPlayerCharacter.Internal.Orig_GameCallback_Logic_OnTickNpcController(_Scriptname);
        NonPlayerCharacter.Internal:OnTickNpcController(_Scriptname);
    end

    self.Orig_GameCallback_Logic_OnNpcActivated = GameCallback_Logic_OnNpcActivated;
    GameCallback_Logic_OnNpcActivated = function(_Scriptname)
        NonPlayerCharacter.Internal.Orig_GameCallback_Logic_OnNpcActivated(_Scriptname);
        NonPlayerCharacter.Internal:OnNpcActivated(_Scriptname);
    end

    self.Orig_GameCallback_Logic_OnNpcDeactivated = GameCallback_Logic_OnNpcDeactivated;
    GameCallback_Logic_OnNpcDeactivated = function(_Scriptname)
        NonPlayerCharacter.Internal.Orig_GameCallback_Logic_OnNpcDeactivated(_Scriptname);
        NonPlayerCharacter.Internal:OnNpcDeactivated(_Scriptname);
    end
end

-- Interaction --

function NonPlayerCharacter.Internal:OnNpcInteraction(_NpcScriptname, _HeroScriptname)
    GUIAction_MerchantReady();

    gvLastInteractionHeroName = _HeroScriptname;
    gvLastInteractionNpcName = _NpcScriptname;

    local HeroID = GetID(_HeroScriptname);
    local NpcID = GetID(_NpcScriptname);
    if Interaction.Internal.Data.IO[_NpcScriptname] then
        local Data = Interaction.Internal.Data.IO[_NpcScriptname];
        if Data.Follow then
            Data = self:OnNpcFolowInteraction(_NpcScriptname, Data, _HeroScriptname);
        elseif table.getn(Data.Waypoints) > 0 then
            Data = self:OnNpcWaypointInteraction(_NpcScriptname, Data, _HeroScriptname);
        elseif table.getn(Data.Wanderer) > 0 then
            if Data.WayCallback then
                Data:WayCallback(HeroID);
            end
        else
            Data = self:OnNpcRegularInteraction(_NpcScriptname, Data, _HeroScriptname);
        end
        Interaction.Internal.Data.IO[_NpcScriptname] = Data;
    end
end

function NonPlayerCharacter.Internal:OnNpcRegularInteraction(_NpcScriptname, _Data, _HeroScriptname)
    local HeroID = GetID(_HeroScriptname);
    local NpcID = GetID(_NpcScriptname);
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
    Interaction.Internal:Deactivate(_NpcScriptname);
    return _Data;
end

function NonPlayerCharacter.Internal:OnNpcFolowInteraction(_NpcScriptname, _Data, _HeroScriptname)
    local HeroID = GetID(_HeroScriptname);
    local NpcID = GetID(_NpcScriptname);
    if _Data.Target then
        if IsNear(_NpcScriptname, _Data.Target, 1200) then
            _Data:Callback(HeroID);
            _Data.TalkedTo = HeroID;
            Interaction.Internal:HeroesLookAtNpc(HeroID, NpcID);
            Interaction.Internal:Deactivate(_NpcScriptname);
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

function NonPlayerCharacter.Internal:OnNpcWaypointInteraction(_NpcScriptname, _Data, _HeroScriptname)
    local HeroID = GetID(_HeroScriptname);
    local NpcID = GetID(_NpcScriptname);
    local LastWaypoint = _Data.Waypoints[table.getn(_Data.Waypoints)];
    if IsNear(_Data.ScriptName, LastWaypoint, 1200) then
        _Data:Callback(HeroID);
        _Data.TalkedTo = HeroID;
        Interaction.Internal:HeroesLookAtNpc(HeroID, NpcID);
        Interaction.Internal:Deactivate(_NpcScriptname);
    else
        if _Data.WayCallback then
            _Data:WayCallback(HeroID);
        end
    end
    return _Data;
end

-- Controller --

function NonPlayerCharacter.Internal:OnTickNpcController(_Scriptname)
    if Interaction.Internal.Data.IO[_Scriptname] then
        if Interaction.Internal.Data.IO[_Scriptname].IsCharacter then
            local Data = Interaction.Internal.Data.IO[_Scriptname];

            if Data.Active == true then
                if Data.Follow ~= nil and not Data.Arrived then
                    Data = NonPlayerCharacter.Internal:OnTickNpcFollowController(_Scriptname, Data);
                elseif table.getn(Data.Waypoints) > 0 and not Data.Arrived then
                    Data = NonPlayerCharacter.Internal:OnTickNpcWaypointController(_Scriptname, Data);
                elseif table.getn(Data.Wanderer) > 1 and not Data.Arrived then
                    Data = NonPlayerCharacter.Internal:OnTickNpcWalkerController(_Scriptname, Data);
                else
                    Data.Arrived = true;
                end
            end
            Interaction.Internal.Data.IO[_Scriptname] = Data;
        end
    end
end

function NonPlayerCharacter.Internal:OnTickNpcFollowController(_Scriptname, _Data)
    local FollowID;
    if type(_Data.Follow) == "string" then
        FollowID = GetID(_Data.Follow);
    else
        FollowID = Interaction.Internal:GetNearestHero(2000);
    end
    if FollowID ~= nil and IsAlive(FollowID) then
        if _Data.Target and IsNear(_Scriptname, _Data.Target, 1200) then
            Move(_Scriptname, _Data.Target);
            _Data.Arrived = true;
        end
        if not _Data.Arrived and Logic.IsEntityMoving(GetID(_Scriptname)) == false then
            Move(_Scriptname, FollowID, 500);
        end
    end
    return _Data;
end

function NonPlayerCharacter.Internal:OnTickNpcWaypointController(_Scriptname, _Data)
    _Data.Waypoints.LastTime = _Data.Waypoints.LastTime or 0;
    _Data.Waypoints.Current = _Data.Waypoints.Current or 1;

    local CurrentTime = Logic.GetTime();
    if _Data.Waypoints.LastTime < CurrentTime then
        _Data.Waypoints.LastTime = CurrentTime + (_Data.Waittime or (2*60));
        -- Set waypoint
        if IsNear(_Scriptname, _Data.Waypoints[_Data.Waypoints.Current], _Data.ArrivedDistance or 1200) then
            _Data.Waypoints.Current = _Data.Waypoints.Current +1;
            if _Data.Waypoints.Current > table.getn(_Data.Waypoints) then
                _Data.Arrived = true;
            end
        end
        -- Move to waypoint
        if not _Data.Arrived then
            if Logic.IsEntityMoving(GetID(_Scriptname)) == false then
                Move(_Scriptname, _Data.Waypoints[_Data.Waypoints.Current]);
            end
        end
    end
    return _Data;
end

function NonPlayerCharacter.Internal:OnTickNpcWalkerController(_Scriptname, _Data)
    _Data.Wanderer.LastTime = _Data.Wanderer.LastTime or 0;
    _Data.Wanderer.Current = _Data.Wanderer.Current or 1;

    if not Interaction.Internal:GetNearestHero(2000) then
        local CurrentTime = Logic.GetTime();
        if _Data.Wanderer.LastTime < CurrentTime then
            _Data.Wanderer.LastTime = CurrentTime + (_Data.Waittime or (5*60));
            if IsNear(_Scriptname, _Data.Wanderer[_Data.Wanderer.Current], _Data.ArrivedDistance or 1200) then
                -- Select random waypoint
                local NewWaypoint;
                repeat
                    NewWaypoint = math.random(1, table.getn(_Data.Wanderer));
                until (NewWaypoint ~= _Data.Wanderer.Current);
                _Data.Wanderer.Current = NewWaypoint;

                -- Move to waypoint
                if Logic.IsEntityMoving(GetID(_Scriptname)) == false then
                    Move(_Scriptname, _Data.Wanderer[_Data.Wanderer.Current]);
                end
            end
        end
    end
    return _Data;
end

