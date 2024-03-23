Lib.Register("comfort/CopyTable");

-- Version: 1.0.0
-- Author:  totalwarANGEL

--- Copies a table.
--- @param _Source table Table to copy
--- @param _Dest? table  (Optional) Destination table
--- @return table Found Value was found
---
function CopyTable(_Source, _Dest)
    local Result = _Dest or {};
    assert(type(_Source) == "table", "CopyTable: Source is nil!");
    assert(type(Result) == "table");
    -- Amend array part
    local LastIndex = 0;
    for i= 1, table.getn(_Source) do
        LastIndex = LastIndex + 1;
        if type(_Source[i]) == "table" then
            table.insert(Result, CopyTable(_Source[i]));
        else
            table.insert(Result, _Source[i]);
        end
    end
    -- Overwrite associative part
    for k,v in pairs(_Source) do
        if type(k) == "number" then
            if k <= 0 or k > LastIndex then
                if type(v) == "table" then
                    Result[k] = Result[k] or CopyTable(v);
                else
                    Result[k] = Result[k] or v;
                end
            end
        else
            if type(v) == "table" then
                Result[k] = Result[k] or CopyTable(v);
            else
                Result[k] = Result[k] or v;
            end
        end
    end
    return Result;
end

