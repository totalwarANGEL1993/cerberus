--- Returns the kay of the value in the table.
--- @param _Value  any  Value to search
--- @param _Table table Table to check
--- @return boolean Found Value was found
---
--- @author Unknown
--- @version 1.0.0
---
function IsInTable(_Value, _Table)
    for k, v in pairs(_Table) do
        if v == _Value then
            return true;
        end
    end
    return false;
end

