Lib.Require("module/syncer/Syncer");
Lib.Register("module/cinematic/Cinematic");

--- 
--- Provides means of control for cinematic events.
---
--- This file is supposed to be used as dependency for other scripts. Only use
--- the functions, if you know what you are doing!
--- 
--- @require Syncer
--- @author totalwarANGEL
--- @version 1.0.0
--- 

Cinematic = {}

--- List of states for cinematic events.
--- * Inactive Event is not active
--- * Active   Event is currently running
--- * Over     Event is over
CinematicEventStatus = {
    Inactive = 1,
    Active   = 2,
    Over     = 3
};

-- -------------------------------------------------------------------------- --
-- API

--- Installs the cinematic event controller
--- (Will be called by code!)
function Cinematic.Install()
    Cinematic.Internal:Install();
end

--- Creates a new event with the name for the player.
--- @param _PlayerID number ID of player
--- @param _Name string     Name of event
--- @return boolean EventCreated Event was created
function Cinematic.CreateCinematicEvent(_PlayerID, _Name)
    return Cinematic.Internal:CreateCinematicEvent(_PlayerID, _Name);
end

--- Checks if any cinematic event is currently active for the player.
--- @param _PlayerID number ID of player
--- @return boolean AnyActive An event is active
function Cinematic.IsAnyCinematicActive(_PlayerID)
    return Cinematic.Internal:IsAnyCinematicEventActive(_PlayerID)
end

--- Returns the state of the cinematic event.
--- @param _PlayerID number ID of player
--- @param _Name string     Name of event
--- @return number State State of cinematic event
function Cinematic.GetCinematicEventState(_PlayerID, _Name)
    return Cinematic.Internal:GetCinematicEventState(_PlayerID, _Name);
end

--- Sets the state of the cinematic event.
--- @param _PlayerID number ID of player
--- @param _Name string     Name of event
--- @param _State number    New state for event
--- @return boolean StateChanged State was changed
function Cinematic.SetCinematicEventState(_PlayerID, _Name, _State)
    return Cinematic.Internal:SetCinematicEventState(_PlayerID, _Name, _State);
end

-- -------------------------------------------------------------------------- --
-- Internal

Cinematic.Internal = {
    Data = {
        CinematicEventID = 0;
        EventStatus = {},
    },
};

function Cinematic.Internal:Install()
    if not self.IsInstalled then
        self.IsInstalled = true;

        for k, v in pairs(Syncer.GetActivePlayers()) do
            self.Data.EventStatus[k] = {};
        end
    end
end

function Cinematic.Internal:IsAnyCinematicEventActive(_PlayerID)
    if self.Data.EventStatus[_PlayerID] then
        for k,v in pairs(self.Data.EventStatus[_PlayerID]) do
            if v == CinematicEventStatus.Active then
                return true;
            end
        end
    end
    return false;
end

function Cinematic.Internal:CreateCinematicEvent(_PlayerID, _Name)
    if self.Data.EventStatus[_PlayerID] then
        if not self.Data.EventStatus[_PlayerID][_Name] then
            self.Data.EventStatus[_PlayerID][_Name] = CinematicEventStatus.Inactive;
            return true;
        end
    end
    return false;
end

function Cinematic.Internal:DeleteCinematicEvent(_PlayerID, _Name)
    self.Data.EventStatus[_PlayerID][_Name] = nil;
end

function Cinematic.Internal:GetCinematicEventState(_PlayerID, _Name)
    if self.Data.EventStatus[_PlayerID] then
        if not self.Data.EventStatus[_PlayerID][_Name] then
            self:CreateCinematicEvent(_PlayerID, _Name);
        end
        return self.Data.EventStatus[_PlayerID][_Name];
    end
    return 0;
end

function Cinematic.Internal:SetCinematicEventState(_PlayerID, _Name, _State)
    if self.Data.EventStatus[_PlayerID] then
        if not self.Data.EventStatus[_PlayerID][_Name] then
            self:CreateCinematicEvent(_PlayerID, _Name);
        end
        self.Data.EventStatus[_PlayerID][_Name] = _State;
        return true;
    end
    return false;
end

