--- Checks if the building is being upgraded.
--- @param _Entity any Building to check
--- @return boolean Upgrading Building is upgrading
---
--- @author totalwarANGEL
--- @version 1.0.0
---
function IsBuildingBeingUpgraded(_Entity)
    local BuildingID = GetID(_Entity);
    if Logic.IsBuilding(BuildingID) == 0 then
        return false;
    end
    local Value = Logic.GetRemainingUpgradeTimeForBuilding(BuildingID);
    local Limit = Logic.GetTotalUpgradeTimeForBuilding(BuildingID);
    return Limit - Value > 0;
end

