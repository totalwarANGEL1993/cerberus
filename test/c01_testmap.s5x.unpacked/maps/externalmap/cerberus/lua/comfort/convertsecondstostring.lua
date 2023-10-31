Lib.Register("comfort/ConvertSecondsToString");

-- Version: 1.0.0
-- Author:  Blue Byte

--- Converts seconds to a time string.
--- (The string will be in the format hh:mm:ss.)
--- @param _TotalSeconds number time in seconds
--- @return string Time Time string
function ConvertSecondsToString(_TotalSeconds)
    local TotalMinutes = math.floor(_TotalSeconds / 60);
    local TotalHours = math.floor(TotalMinutes / 60);
    local Hours = math.mod(TotalHours, 60);
    if Hours == 60 then
        Hours = Hours -1;
    end
    local Minutes = math.mod(TotalMinutes, 60);
    if Minutes == 60 then
        Hours = Hours +1;
        Minutes = Minutes -1;
    end
    local Seconds = math.floor(math.mod(_TotalSeconds, 60));
    if Seconds == 60 then
        Minutes = Minutes +1;
        Seconds = Seconds -1;
    end

    local String = "";
    if Hours < 10 then
        String = String .. "0" .. Hours .. ":";
    else
        String = String .. Hours .. ":";
    end
    if Minutes < 10 then
        String = String .. "0" .. Minutes .. ":";
    else
        String = String .. Minutes .. ":";
    end
    if Seconds < 10 then
        String = String .. "0" .. Seconds;
    else
        String = String .. Seconds;
    end
    return String;
end

