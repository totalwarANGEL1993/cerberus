Lib.Register("comfort/StartCountdown");

--- Starts a countdown.
---
--- Only one visible countdown is allowed but any number of invisible
--- countdowns are possible.
--- @param _Limit integer Time in seconds
--- @param _Callback function Callback function
--- @param _Show boolean Countdown is visible
--- @return integer ID ID of countdown
function StartCountdown(_Limit, _Callback, _Show)
    assert(type(_Limit) == "number");
    assert( not _Callback or type(_Callback) == "function" );
    Counter.Index = (Counter.Index or 0) + 1;
    if _Show and CountdownIsVisisble() then
        assert(false, "StartCountdown: A countdown is already visible");
    end
    Counter["counter" .. Counter.Index] = {
        Limit = _Limit,
        TickCount = 0,
        Callback = _Callback,
        Show = _Show,
        Finished = false
    };
    if _Show then
        MapLocal_StartCountDown(_Limit);
    end
    if Counter.JobId == nil then
        Counter.JobId = StartSimpleJob("CountdownTick");
    end
    return Counter.Index;
end

--- Stops a countdown.
--- @param _Id integer ID of countdown
function StopCountdown(_Id)
    if Counter.Index == nil then
        return;
    end
    if _Id == nil then
        for i = 1, Counter.Index do
            if Counter.IsValid("counter" .. i) then
                if Counter["counter" .. i].Show then
                    MapLocal_StopCountDown();
                end
                Counter["counter" .. i] = nil;
            end
        end
    else
        if Counter.IsValid("counter" .. _Id) then
            if Counter["counter" .. _Id].Show then
                MapLocal_StopCountDown();
            end
            Counter["counter" .. _Id] = nil;
        end
    end
end

--- Checks if a visible countdown is active,
--- @return boolean Visible Countdown is visible
function CountdownIsVisisble()
    for i = 1, Counter.Index do
        if Counter.IsValid("counter" .. i) and Counter["counter" .. i].Show then
            return true;
        end
    end
    return false;
end

function CountdownTick()
    local empty = true;
    for i = 1, Counter.Index do
        if Counter.IsValid("counter" .. i) then
            if Counter.Tick("counter" .. i) then
                Counter["counter" .. i].Finished = true;
            end
            if Counter["counter" .. i].Finished and XGUIEng.IsWidgetShown("Cinematic") == 0 then
                if Counter["counter" .. i].Show then
                    MapLocal_StopCountDown();
                end
                if type(Counter["counter" .. i].Callback) == "function" then
                    Counter["counter" .. i].Callback();
                end
                Counter["counter" .. i] = nil;
            end
            empty = false;
        end
    end
    if empty then
        Counter.JobId = nil;
        Counter.Index = nil;
        return true;
    end
end

