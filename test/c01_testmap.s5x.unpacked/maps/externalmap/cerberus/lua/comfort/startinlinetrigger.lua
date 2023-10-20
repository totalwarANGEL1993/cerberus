Lib.Require("comfort/CopyTable");
Lib.Register("comfort/StartInlineTrigger");

JobQueueData = {
    JobIDSequence = 0,
};

--- Creates a trigger that is invoked each second.
--- @param _Function function Function to call
--- @param ... any            List of parameters
--- @return number ID ID of trigger
---
--- @deprecated
--- @author totalwarANGEL
--- @version 1.0.0
---
function StartSimpleSecondsTrigger(_Function, ...)
    local Function = _Function;
    if type(Function) == "string" then
        Function = _G[Function];
    end
    assert(type(Function) == "function", "Function does not exist!");
    return StartInlineTrigger(Events.LOGIC_EVENT_EVERY_SECOND, Function, unpack(arg));
end

--- Creates a trigger that is invoked each tenth second.
--- @param _Function function Function to call
--- @param ... any            List of parameters
--- @return number ID ID of trigger
---
--- @deprecated
--- @author totalwarANGEL
--- @version 1.0.0
---
function StartSimpleTurnTrigger(_Function, ...)
    local Function = _Function;
    if type(Function) == "string" then
        Function = _G[Function];
    end
    assert(type(Function) == "function", "Function does not exist!");
    return StartInlineTrigger(Events.LOGIC_EVENT_EVERY_TURN, Function, unpack(arg));
end

--- Creates a trigger that is invoked when a entity is hurt.
--- 
--- * Event.GetEntityID1() returns the attacking entity.
--- * Event.GetEntityID2() returns the defending entity.
---
--- @param _Function function Function to call
--- @param ... any            List of parameters
--- @return number ID ID of trigger
---
--- @deprecated
--- @author totalwarANGEL
--- @version 1.0.0
---
function StartSimpleHurtTrigger(_Function, ...)
    local Function = _Function;
    if type(Function) == "string" then
        Function = _G[Function];
    end
    assert(type(Function) == "function", "Function does not exist!");
    return StartInlineTrigger(Events.LOGIC_EVENT_ENTITY_HURT_ENTITY, Function, unpack(arg));
end

--- Creates a trigger that is invoked when an entity is created.
--- 
--- * Event.GetEntityID() returns the entity.
---
--- @param _Function function Function to call
--- @param ... any            List of parameters
--- @return number ID ID of trigger
---
--- @deprecated
--- @author totalwarANGEL
--- @version 1.0.0
---
function StartSimpleCreatedTrigger(_Function, ...)
    local Function = _Function;
    if type(Function) == "string" then
        Function = _G[Function];
    end
    assert(type(Function) == "function", "Function does not exist!");
    return StartInlineTrigger(Events.LOGIC_EVENT_ENTITY_CREATED, Function, unpack(arg));
end

--- Creates a trigger that is invoked when an entity is destroyed.
--- 
--- * Event.GetEntityID() returns the entity.
---
--- @param _Function function Function to call
--- @param ... any            List of parameters
--- @return number ID ID of trigger
---
--- @deprecated
--- @author totalwarANGEL
--- @version 1.0.0
---
function StartSimpleDestroyedTrigger(_Function, ...)
    local Function = _Function;
    if type(Function) == "string" then
        Function = _G[Function];
    end
    assert(type(Function) == "function", "Function does not exist!");
    return StartInlineTrigger(Events.LOGIC_EVENT_ENTITY_DESTROYED, Function, unpack(arg));
end

--- Creates a trigger that is invoked when a tribute is payed.
--- 
--- * Event.GetTributeUniqueID() returns the ID of the tribute.
---
--- @param _Function function Function to call
--- @param ... any            List of parameters
--- @return number ID ID of trigger
---
--- @deprecated
--- @author totalwarANGEL
--- @version 1.0.0
---
function StartSimpleTributeTrigger(_Function, ...)
    local Function = _Function;
    if type(Function) == "string" then
        Function = _G[Function];
    end
    assert(type(Function) == "function", "Function does not exist!");
    return StartInlineTrigger(Events.LOGIC_EVENT_TRIBUTE_PAID, Function, unpack(arg));
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
---
--- @deprecated
--- @author totalwarANGEL
--- @version 1.0.0
---
function StartSimpleTradeTrigger(_Function, ...)
    local Function = _Function;
    if type(Function) == "string" then
        Function = _G[Function];
    end
    assert(type(Function) == "function", "Function does not exist!");
    return StartInlineTrigger(Events.LOGIC_EVENT_GOODS_TRADED, Function, unpack(arg));
end

-- Who needs a trigger fix? :P
function StartInlineTrigger(_EventType, _Function, ...)
    JobQueueData.JobIDSequence = JobQueueData.JobIDSequence +1;

    local Sequence = JobQueueData.JobIDSequence;
    -- Save parameters
    _G["InlineJob_Data_" ..Sequence] = CopyTable(arg);
    -- Save function
    _G["InlineJob_Function_" ..Sequence] = _Function;

    -- Create job runner
    _G["InlineJob_Executor_" ..Sequence] = function(i)
        if _G["InlineJob_Function_" ..i](unpack(_G["InlineJob_Data_" ..i])) then
            -- Save on memory
            _G["InlineJob_Function_" ..i] = nil;
            _G["InlineJob_Executor_" ..i] = nil;
            _G["InlineJob_Data_" ..i] = nil;
            return true;
        end
    end

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

