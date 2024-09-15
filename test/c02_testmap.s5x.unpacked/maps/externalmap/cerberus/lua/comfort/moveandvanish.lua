Lib.Register("comfort/MoveAndVanish");

--- Moves an entity to another and deletes it after it's arrived.
--- @param _Entity any Scriptname/ID of entity
--- @param _Target any Scriptname/ID of target
function MoveAndVanish(_Entity, _Target)
    Move(_Entity, _Target);
    Trigger.RequestTrigger(
        Events.LOGIC_EVENT_EVERY_SECOND,
        "",
        "MoveAndVanish_Internal_VanishHelper",
        1,
        {},
        {_Entity}
    )
end

function MoveAndVanish_Internal_VanishHelper(_Entity)
    local ID = GetID(_Entity);
    if not IsExisting(ID) then
        return true;
    end
    if Logic.IsEntityMoving(ID) == false then
        DestroyEntity(ID);
    end
end

