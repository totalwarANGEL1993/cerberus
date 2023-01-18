--- Returns the upgrade level associated to the type.
--- @param _Type number Entity type
--- @return number Level Upgrade level of type
---
--- @require GetUpgradeCategoryByEntityType
---
--- @author totalwarANGEL
--- @version 1.0.0
---
function GetUpgradeLevelByEntityType(_Type)
    local UpgradeCategory = GetUpgradeCategoryByEntityType(_Type);
    if UpgradeCategory ~= 0 then
        local Buildings = {Logic.GetBuildingTypesInUpgradeCategory(UpgradeCategory)};
        for i=2, Buildings[1] +1 do
            if Buildings[i] == _Type then
                return i - 2;
            end
        end
        local Settlers = {Logic.GetSettlerTypesInUpgradeCategory(UpgradeCategory)};
        for i=2, Settlers[1] +1 do
            if Settlers[i] == _Type then
                return i - 2;
            end
        end
    end
    return 0;
end

