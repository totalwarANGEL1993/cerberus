Lib.Register("comfort/Round");

-- Version: 1.0.0
-- Author:  unknown

--- Rounds a number to the next integer.
--- @return integer Number Rounded number
function Round(_n)
	return math.floor(_n + 0.5);
end

