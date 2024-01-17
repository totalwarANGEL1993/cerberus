Lib.Register("comfort/GetUpgradeCategoryByEntityType");

-- Version: 1.1.0
-- Author:  totalwarANGEL

GetUpgradeCategoryByEntityType_IsBuildingCache = {};
GetUpgradeCategoryByEntityType_IsSettlerCache = {};

--- Returns the upgrade category of the entity type
--- @param _Type number Entity type
--- @return number Category Upgrade category
function GetUpgradeCategoryByEntityType(_Type)
    local TypeName = Logic.GetEntityTypeName(_Type);
    if TypeName then
        -- Save building or settler to not compare strings the second time
        if  not GetUpgradeCategoryByEntityType_IsBuildingCache[_Type]
        and not GetUpgradeCategoryByEntityType_IsSettlerCache[_Type] then
            if string.find(TypeName, "CU_") or string.find(TypeName, "PU_") then
                GetUpgradeCategoryByEntityType_IsSettlerCache[_Type] = true;
            end
            if string.find(TypeName, "CB_") or string.find(TypeName, "PB_")
            or string.find(TypeName, "XD_") then
                GetUpgradeCategoryByEntityType_IsBuildingCache[_Type] = true;
            end
        end
        -- Use logic for buildings
        -- (Custom building types must be put in valid categories!)
        if GetUpgradeCategoryByEntityType_IsBuildingCache[_Type] then
            return Logic.GetUpgradeCategoryByBuildingType(_Type);
        end
        -- Parse entity type for settlers
        -- (Custom settler types must be numbered starting from 1!)
        if GetUpgradeCategoryByEntityType_IsSettlerCache[_Type] then
            local Key = string.sub(TypeName, 4);
            local s,e = string.find(Key, "^[A-Za-z_]+");
            local Suffix = string.sub(Key, e+1);
            if Suffix and tonumber(Suffix) then
                Key = string.sub(Key, 1, e);
            end
            if UpgradeCategories[Key] then
                return UpgradeCategories[Key];
            end
        end
    end
    return 0;
end

