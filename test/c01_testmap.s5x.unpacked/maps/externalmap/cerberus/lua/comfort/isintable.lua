Lib.Register("comfort/IsInTable");

-- Version: 1.0.0
-- Author:  unknown

--- Returns the key of the value in the table.
--- @param _Value  any  Value to search
--- @param _Table table Table to check
--- @return boolean Found Value was found
function IsInTable(_Value, _Table)
    for k, v in pairs(_Table) do
        if v == _Value then
            return true;
        end
    end
    return false;
end

