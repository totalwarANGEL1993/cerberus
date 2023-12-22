Lib.Require("module/trigger/Job");
Lib.Register("module/trigger/Delay");

--- 
--- Simple Delay System
---
--- Allows to create delays that wait some seconds or turns. Delays can be set
--- to repeat themselves.
--- 
--- Version 1.0.0
--- 

Delay = Delay or {};

-- -------------------------------------------------------------------------- --
-- API

--- Starts a delay that waits a few seconds.
--- @param _Seconds integer Seconds to wait
--- @param _Action function Action at expiration
--- @param ... any List of parameters
--- @return integer ID ID of delay
function Delay.Second(_Seconds, _Action, ...)
    return Delay.Internal:StartDelay(_Seconds * 10, Logic.GetCurrentTurn(), false, _Action, unpack(arg or {}));
end

--- Starts a delay that waits a few turns.
--- @param _Turns integer Turns to wait
--- @param _Action function Action at expiration
--- @param ... any List of parameters
--- @return integer ID ID of delay
function Delay.Turn(_Turns, _Action, ...)
    return Delay.Internal:StartDelay(_Turns, Logic.GetCurrentTurn(), false, _Action, unpack(arg or {}));
end

--- Starts a delay that waits some seconds since game start.
--- @param _Seconds integer Seconds to wait
--- @param _Action function Action at expiration
--- @param ... any List of parameters
--- @return integer ID ID of delay
function Delay.SecondsAfterStart(_Seconds, _Action, ...)
    return Delay.Internal:StartDelay(_Seconds * 10, 0, false, _Action, unpack(arg or {}));
end

--- Starts a delay that waits some turns since game start.
--- @param _Turns integer Turns to wait
--- @param _Action function Action at expiration
--- @param ... any List of parameters
--- @return integer ID ID of delay
function Delay.TurnsAfterStart(_Turns, _Action, ...)
    return Delay.Internal:StartDelay(_Turns, 0, false, _Action, unpack(arg or {}));
end

--- Starts a delay that waits a few seconds and then repeats.
--- @param _Seconds integer Seconds to wait
--- @param _Action function Action at expiration
--- @param ... any List of parameters
--- @return integer ID ID of delay
function Delay.RepeatingEachSecond(_Seconds, _Action, ...)
    return Delay.Internal:StartDelay(_Seconds * 10, Logic.GetCurrentTurn(), true, _Action, unpack(arg or {}));
end

--- Starts a delay that waits a few turns and then repeats.
--- @param _Turns integer Turns to wait
--- @param _Action function Action at expiration
--- @param ... any List of parameters
--- @return integer ID ID of delay
function Delay.RepeatingEachTurn(_Turns, _Action, ...)
    return Delay.Internal:StartDelay(_Turns, Logic.GetCurrentTurn(), true, _Action, unpack(arg or {}));
end

--- Stops a delay if it is running.
--- @param _ID integer ID of delay
function Delay.StopDelay(_ID)
    Delay.Internal:StopDelay(_ID);
end

--- Returns if a delay is running.
--- @param _ID integer ID of delay
--- @return boolean
function Delay.IsRunning(_ID)
    return Delay.Internal:DelayIsRunning(_ID);
end

-- -------------------------------------------------------------------------- --
-- Internal

Delay.Internal = Delay.Internal or {
    Data = {
        Delay = {SequenceID = 0},
    },
};

function Delay.Internal:Install()
    if not self.IsInstalled then
        self.IsInstalled = true;
    end
end

function Delay.Internal:StartDelay(_Time, _StartTime, _IsRepeating, _Action, ...)
    self.Data.Delay.SequenceID = self.Data.Delay.SequenceID + 1;
    local ID = self.Data.Delay.SequenceID;

    local JobID = Job.Turn(function(_ID, _Delay)
        local StartTime = Delay.Internal.Data.Delay[_ID].StartTime;
        local CurrentTurn = Logic.GetCurrentTurn();

        if CurrentTurn - StartTime >= _Delay then
            local Action = Delay.Internal.Data.Delay[_ID].Action;
            local Parameter = Delay.Internal.Data.Delay[_ID].Parameter;
            Action(unpack(Parameter));

            if Delay.Internal.Data.Delay[_ID].Repeat then
                Delay.Internal.Data.Delay[_ID].StartTime = CurrentTurn;
                return false;
            end
            Delay.Internal.Data.Delay[_ID] = nil;
            return true;
        end
    end, ID, _Time);

    self.Data.Delay[ID] = {
        StartTime = _StartTime,
        DelayedTime = _Time,
        Action = _Action,
        Repeat = _IsRepeating == true,
        Parameter = CopyTable(arg or {}),
        JobID = JobID
    };
    return ID;
end

function Delay.Internal:StopDelay(_ID)
    if self.Data.Delay[_ID] then
        EndJob(self.Data.Delay[_ID].JobID);
        self.Data.Delay[_ID] = nil;
    end
end

function Delay.Internal:DelayIsRunning(_ID)
    if self.Data.Delay[_ID] then
        return JobIsRunning(self.Data.Delay[_ID].JobID) == true;
    end
    return false;
end

