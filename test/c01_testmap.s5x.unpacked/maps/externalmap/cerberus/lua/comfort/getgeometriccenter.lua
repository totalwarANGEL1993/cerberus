Lib.Require("comfort/IsValidPosition");
Lib.Register("comfort/GetGeometricCenter");

-- Version: 1.0.0
-- Author:  totalwarANGEL

--- Returns the average position of all positions.
--- @param ... any List of positions
--- @return table Center Center position
function GetGeometricCenter(...)
    local Valid = 0;
    local SumX = 0;
    local SumY = 0;
    local SumZ = 0;
    for i= 1, table.getn(arg), 1 do
        --- @type table
        --- @diagnostic disable-next-line: assign-type-mismatch
        local Position = arg[i];
        if type(arg[i]) ~= "table" then
            Position = GetPosition(arg[i]);
        end
        if Position and IsValidPosition(Position) then
            SumX = SumX + Position.X;
            SumY = SumY + Position.Y;
            SumZ = SumZ + (Position.Z or 0);
            Valid = Valid +1;
        end
    end
    return {
        X= (1/Valid) * SumX,
        Y= (1/Valid) * SumY,
        Z= (1/Valid) * SumZ
    };
end

