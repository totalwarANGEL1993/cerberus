Lib.Require("comfort/CopyTable");
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

--- Creates a trigger that is invoked when diplomacy changes between players.
---
--- The player will be called for both players each in reversed order.
---
--- * Event.GetSourcePlayerID() returns first player
--- * Event.GetTargetPlayerID() returns second player
--- * Event.GetDiplomacyState() returns diplomacy state
---
--- @param _Function function Function to call
--- @param ... any            List of parameters
--- @return number ID ID of trigger
function Job.Diplomacy(_Function, ...)
    Job.Internal:Install();
    return Job.Internal:StartJob(Events.LOGIC_EVENT_DIPLOMACY_CHANGED, _Function, unpack(arg));
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

--- Creates a trigger that is invoked when a tribute is payed.
--- 
--- * Event.GetTributeUniqueID() returns the ID of the tribute.
--- * Event.GetSourcePlayerID() returns the ID of the player.
---
--- @param _Function function Function to call
--- @param ... any            List of parameters
--- @return number ID ID of trigger
function Job.Tribute(_Function, ...)
    Job.Internal:Install();
    return Job.Internal:StartJob(Events.LOGIC_EVENT_TRIBUTE_PAID, _Function, unpack(arg));
end

--- Adds a condition to a specific tribute or to all tributes.
---
--- Conditions for specific tributes have priority over the common condition.
---
--- #### Example
--- ```lua
--- -- _PlayerID  - player who would pay tribute
--- -- _TributeID - ID of tribute payed
--- function MyCondition(_PlayerID, _TributeID)
---     -- true: tribute can be fulfilled
---     -- false: tribute is locked
---     return true;
--- end
--- Job.AddTributeCondition(6, MyCondition);
--- ```
--- @param _TributeID integer  ID of tribute or -1 for all
--- @param _Condition function Condition function
function Job.AddTributeCondition(_TributeID, _Condition)
    Job.Internal.Data.TributeCondition[_TributeID] = _Condition;
end

-- -------------------------------------------------------------------------- --
-- Internal

Job.Internal = Job.Internal or {
    JobIdSequence = 0,

    Data = {
        TributeCondition = {},
        --
        Parameter = {},
        Function = {},
        Executor = {},
    },
};

function Job.Internal:Install()
    if not self.IsInstalled then
        self.IsInstalled = true;

        self:InitOverwriteTributePaied();
        self:InitRestoreAfterLoad();
    end
end

function Job.Internal:InitOverwriteTributePaied()
    self.Orig_GameCallback_FulfillTribute = GameCallback_FulfillTribute;
    GameCallback_FulfillTribute = function(_PlayerID, _TributeID)
        local IsAllowed = 1;
        if Job.Internal.Orig_GameCallback_FulfillTribute then
            IsAllowed = Job.Internal.Orig_GameCallback_FulfillTribute(_PlayerID, _TributeID);
        end
        if Job.Internal.Data.TributeCondition[_TributeID] then
            IsAllowed = 0;
            if Job.Internal.Data.TributeCondition[_TributeID](_PlayerID, _TributeID) then
                IsAllowed = 1;
            end
        elseif Job.Internal.Data.TributeCondition[-1] then
            IsAllowed = 0;
            if Job.Internal.Data.TributeCondition[-1](_PlayerID, _TributeID) then
                IsAllowed = 1;
            end
        end
        return IsAllowed;
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
        {Sequence, _EventType}
    );
end

function Job.Internal:CreateExecutor(_Index)
    _G["InlineJob_Executor_" .._Index] = function(i, _EventType)
        if Job.Internal.Data.Function[i](unpack(Job.Internal.Data.Parameter[i])) then
            _G["InlineJob_Executor_" .._Index] = nil;
            Job.Internal.Data.Function[i] = nil;
            Job.Internal.Data.Parameter[i] = nil;
            -- HACK: Close tribute window 
            if _EventType == Events.LOGIC_EVENT_TRIBUTE_PAID then
                if GUI.GetPlayerID() == Event.GetSourcePlayerID() then
                    Sound.PlayGUISound(Sounds.OnKlick_Select_helias, 127);
                    XGUIEng.ShowWidget("TradeWindow", 0);
                end
            end
            return true;
        end
    end
end

