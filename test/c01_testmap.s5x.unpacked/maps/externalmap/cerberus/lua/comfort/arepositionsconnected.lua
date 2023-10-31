Lib.Register("comfort/ArePositionsConnected");

-- Version: 1.0.0
-- Author:  totalwarANGEL

--- Checks if the positions are in the same sector.
--- @param _pos1 any First position
--- @param _pos2 any Second position
--- @return boolean Connected Positions are connected
--- 
function ArePositionsConnected(_pos1, _pos2)
    local sector1, sector2 = 0, 0;
    if CUtil then
        if type(_pos1) == "table" then
            sector1 = CUtil.GetSector(_pos1.X/100, _pos1.Y/100);
        else
            sector1 = Logic.GetSector(GetID(_pos1));
        end
        if type(_pos2) == "table" then
            sector2 = CUtil.GetSector(_pos2.X/100, _pos2.Y/100);
        else
            sector2 = Logic.GetSector(GetID(_pos2));
        end
    else
        local sectorEntity1 = _pos1;
        local toClean1;
        if type(sectorEntity1) == "table" then
            sectorEntity1 = Logic.CreateEntity(Entities.XD_ScriptEntity, _pos1.X, _pos1.Y, 0, 8);
            toClean1 = true;
        end

        local sectorEntity2 = _pos2;
        local toClean2;
        if type(sectorEntity2) == "table" then
            sectorEntity2 = Logic.CreateEntity(Entities.XD_ScriptEntity, _pos2.X, _pos2.Y, 0, 8);
            toClean2 = true;
        end

        local eID1 = GetID(sectorEntity1);
        local eID2 = GetID(sectorEntity2);
        if (eID1 == nil or eID1 == 0) or (eID2 == nil or eID2 == 0) then
            return false;
        end

        sector1 = Logic.GetSector(eID1)
        if toClean1 then
            DestroyEntity(eID1);
        end
        sector2 = Logic.GetSector(eID2)
        if toClean2 then
            DestroyEntity(eID2);
        end
    end
    return (sector1 ~= 0 and sector2 ~= 0 and sector1 == sector2);
end

