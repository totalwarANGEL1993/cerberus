Lib.Register("comfort/GetGeometricCenter");

--- Returns the average position of all positions.
--- @param ... any List of positions
--- @return table Center Center position
---
--- @author totalwarANGEL
--- @version 1.0.0
---
function GetGeometricCenter(...)
    local SumX = 0;
    local SumY = 0;
    local SumZ = 0;
    for i= 1, table.getn(arg), 1 do
        local Position = arg[i];
        if type(arg[i]) ~= "table" then
            Position = GetPosition(arg[i]);
        end
        SumX = SumX + Position.X;
        SumY = SumY + Position.Y;
        if Position.Z then
            SumZ = SumZ + Position.Z;
        end
    end
    return {
        X= 1/table.getn(arg) * SumX,
        Y= 1/table.getn(arg) * SumY,
        Z= 1/table.getn(arg) * SumZ
    };
end

