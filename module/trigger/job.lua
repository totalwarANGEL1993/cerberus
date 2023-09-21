Lib.Register("module/trigger/Job");

--- 
--- Simple Trigger System
--- 
--- Wraps the internal Trigger System to allow jobs with table parameters.
--- In addition functions can be directly passed instead of a string with
--- a function name (but that is also possible).
--- 
--- Version 1.0.0
--- 

Job = Job or {};

-- -------------------------------------------------------------------------- --
-- API

--- Creates a trigger that is invoked each second.
--- @param _Function function Function to call
--- @param ... any            List of parameters
--- @return number ID ID of trigger
function Job.Second(_Function, ...)
    Job.Internal:Install();
    return Job.Internal:StartJob(Events.LOGIC_EVENT_EVERY_SECOND, _Function, unpack(arg));
end

--- Creates a trigger that is invoked each tenth second.
--- @param _Function function Function to call
--- @param ... any            List of parameters
--- @return number ID ID of trigger
function Job.Turn(_Function, ...)
    Job.Internal:Install();
    return Job.Internal:StartJob(Events.LOGIC_EVENT_EVERY_TURN, _Function, unpack(arg));
end

--- Creates a trigger that is invoked when a entity is hurt.
--- 
--- * Event.GetEntityID1() returns the attacking entity.
--- * Event.GetEntityID2() returns the defending entity.
---
--- @param _Function function Function to call
--- @param ... any            List of parameters
--- @return number ID ID of trigger
function Job.Hurt(_Function, ...)
    Job.Internal:Install();
    return Job.Internal:StartJob(Events.LOGIC_EVENT_ENTITY_HURT_ENTITY, _Function, unpack(arg));
end

--- Creates a trigger that is invoked when an entity is created.
--- 
--- * Event.GetEntityID() returns the entity.
---
--- @param _Function function Function to call
--- @param ... any            List of parameters
--- @return number ID ID of trigger
function Job.Create(_Function, ...)
    Job.Internal:Install();
    return Job.Internal:StartJob(Events.LOGIC_EVENT_ENTITY_CREATED, _Function, unpack(arg));
end

--- Creates a trigger that is invoked when an entity is destroyed.
--- 
--- * Event.GetEntityID() returns the entity.
---
--- @param _Function function Function to call
--- @param ... any            List of parameters
--- @return number ID ID of trigger
function Job.Destroy(_Function, ...)
    Job.Internal:Install();
    return Job.Internal:StartJob(Events.LOGIC_EVENT_ENTITY_DESTROYED, _Function, unpack(arg));
end

--- Creates a trigger that is invoked when a tribute is payed.
--- 
--- * Event.GetTributeUniqueID() returns the ID of the tribute.
---
--- @param _Function function Function to call
--- @param ... any            List of parameters
--- @return number ID ID of trigger
function Job.Tribute(_Function, ...)
    Job.Internal:Install();
    return Job.Internal:StartJob(Events.LOGIC_EVENT_TRIBUTE_PAID, _Function, unpack(arg));
end

--- Creates a trigger that is invoked when a trade is completed.
---
--- * Event.GetBuyResource() returns the purchased resource
--- * Event.GetSellResource() returns the sold resource
--- * Event.GetEntityID() returns the ID of the market
---
--- @param _Function function Function to call
--- @param ... any            List of parameters
--- @return number ID ID of trigger
function Job.Trade(_Function, ...)
    Job.Internal:Install();
    return Job.Internal:StartJob(Events.LOGIC_EVENT_GOODS_TRADED, _Function, unpack(arg));
end

-- TODO: Add delay functions

-- -------------------------------------------------------------------------- --
-- Internal

Job.Internal = Job.Internal or {
    JobIdSequence = 0,

    Data = {
        Parameter = {},
        Function = {},
        Executor = {},
    },
};

function Job.Internal:Install()
    if not self.IsInstalled then
        self.IsInstalled = true;

        self:InitRestoreAfterLoad();
    end
end

function Job.Internal:InitRestoreAfterLoad()
	self.Orig_Mission_OnSaveGameLoaded = Mission_OnSaveGameLoaded;
    Mission_OnSaveGameLoaded = function()
        for k,v in pairs(Job.Internal.Data.Function) do
            Job.Internal:CreateExecutor(k);
        end
        Job.Internal.Orig_Mission_OnSaveGameLoaded();
    end
end

-- Who needs a trigger fix? :P
function Job.Internal:StartJob(_EventType, _Function, ...)
    self.JobIdSequence = self.JobIdSequence +1;
    local Sequence = self.JobIdSequence;

    -- Save parameters
    self.Data.Parameter[Sequence] = CopyTable(arg);

    -- Save function
    local Function = _Function;
    if type(Function) == "string" then
        Function = _G[Function];
    end
    assert(type(Function) == "function", "Could not find function!");
    self.Data.Function[Sequence] = _Function

    -- Create job runner
    -- (Must be a variable in _G because triggers are stupid pussies!)
    self:CreateExecutor(Sequence);

    -- Request the trigger
    return Trigger.RequestTrigger(
        _EventType,
        "",
        "InlineJob_Executor_" ..Sequence,
        1,
        {},
        {Sequence}
    );
end

function Job.Internal:CreateExecutor(_Index)
    _G["InlineJob_Executor_" .._Index] = function(i)
        if Job.Internal.Data.Function[i](unpack(Job.Internal.Data.Parameter[i])) then
            _G["InlineJob_Executor_" .._Index] = nil;
            Job.Internal.Data.Function[i] = nil;
            Job.Internal.Data.Parameter[i] = nil;
            return true;
        end
    end
end

