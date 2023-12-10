Lib.Register("comfort/ShuffleTable");

-- Version: 1.0.0
-- Author:  totalwarANGEL

--- Shuffles a table.
--- @param _Source table Table to shuffle
--- @return table Table Shuffled table
---
function ShuffleTable(_Source)
    local function swap(t, i, j)
        t[i], t[j] = t[j], t[i];
    end
    for i = table.getn(_Source), 2, -1 do
        local j = math.random(i);
        swap(_Source, i, j);
    end
    return _Source;
end

