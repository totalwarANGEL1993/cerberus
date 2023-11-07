Lib.Register("comfort/GetMaxAmountOfPlayer");

--- Returns the max amount of possible player IDs.
--- @return integer Amount Amount of IDs
function GetMaxAmountOfPlayer()
    return (CNetwork and XNetwork.Manager_DoesExist() and 16) or 8;
end

