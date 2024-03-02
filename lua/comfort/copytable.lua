Lib.Register("comfort/CopyTable");

-- Version: 1.0.0
-- Author:  totalwarANGEL

--- Copies a table.
--- @param _Source table Table to copy
--- @param _Dest? table  (Optional) Destination table
--- @return table Found Value was found
---
function CopyTable(_Source, _Dest)
    _Dest = _Dest or {};
    assert(_Source ~= nil, "CopyTable: Source is nil!");
    assert(type(_Dest) == "table");

    local Result = {};
    if type(_Source[1]) == "number" and type(_Dest[1]) == "number" then
        Result = _Dest;
        for i= 1, table.getn(_Source) do
            if type(_Source[i]) == "table" then
                table.insert(Result, CopyTable(_Source[i]));
            else
                table.insert(Result, _Source[i]);
            end
        end
    else
        Result = _Dest;
        for k,v in pairs(_Source) do
            if type(v) == "table" then
                Result[k] = _Dest[k] or CopyTable(v);
            else
                Result[k] = _Dest[k] or v;
            end
        end
    end
    return Result;
end

