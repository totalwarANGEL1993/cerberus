Lib.Register("comfort/GetEntitiesByPrefix");

-- Version: 1.0.0
-- Author:  unknown

--- Returns all entities with names starting with the prefix.
--- @param _Prefix string Prefix of script names
--- @return table Result List of entities
function GetEntitiesByPrefix(_Prefix)
    local list = {};
    local i = 1;
    local bFound = true;
    while (bFound) do
        local entity = GetID(_Prefix ..i);
        if entity ~= 0 then
            table.insert(list, entity);
        else
            bFound = false;
        end
        i = i + 1;
    end
    return list;
end

