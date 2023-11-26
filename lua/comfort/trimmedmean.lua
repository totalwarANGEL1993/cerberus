Lib.Register("comfort/TrimmedMean");

-- Version: 1.0.0
-- Author:  totalwarANGEL

--- Returns an average where up to 10% of outliers will be ignored.
--- @param ... number List of values
--- @return number Mean Average of values
function TrimmedMean(...)
    table.sort(arg);
    local count = table.getn(arg);
    local trimCount = math.floor(count * 10 / 100);
    local trimmedValues = {};
    for i = trimCount + 1, count - trimCount do
        table.insert(trimmedValues, arg[i]);
    end
    local sum = 0;
    for _, value in ipairs(trimmedValues) do
        sum = sum + value;
    end
    return sum / table.getn(trimmedValues);
end

