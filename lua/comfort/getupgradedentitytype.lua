Lib.Require("comfort/GetUpgradeLevelByEntityType");
Lib.Register("comfort/GetUpgradedEntityType");

-- Version: 1.0.0
-- Author:  totalwarANGEL

--- Returns the type the entity will be upgraded to.
--- @param _Type integer Entity type
--- @return integer Type Upgraded entity type
function GetUpgradedEntityType(_Type)
    local UpgradeCategory = GetUpgradeCategoryByEntityType(_Type);
    if UpgradeCategory ~= 0 then
        local UpgradeLevel = GetUpgradeLevelByEntityType(_Type);
        local Buildings = {Logic.GetBuildingTypesInUpgradeCategory(UpgradeCategory)};
        if Buildings[1] > 0 and Buildings[UpgradeLevel + 3] then
            return Buildings[UpgradeLevel + 3];
        end
        local Settlers = {Logic.GetSettlerTypesInUpgradeCategory(UpgradeCategory)};
        if Settlers[1] > 0 and Settlers[UpgradeLevel + 3] then
            return Settlers[UpgradeLevel + 3];
        end
    end
    return 0;
end

