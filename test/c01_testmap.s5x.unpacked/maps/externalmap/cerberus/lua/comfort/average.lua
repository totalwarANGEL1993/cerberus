Lib.Register("comfort/Average");

-- Version: 1.0.0
-- Author:  totalwarANGEL

--- Returns the average of all passed numbers.
--- @param ... number List of numbers
--- @return number Mean Average of numbers
function Average(...)
    local n = table.getn(arg);
    local sum = 0;
    for i= 1, n do
        sum = sum + arg[i];
    end
    return sum / n;
end

