--- Returns the upgrade category of the entity type
--- @param _Type number Entity type
--- @return number Category Upgrade category
---
--- @author totalwarANGEL
--- @version 1.0.0
---
function GetUpgradeCategoryByEntityType(_Type)
    local TypeName = Logic.GetEntityTypeName(_Type);
    if TypeName then
        local Key = string.sub(TypeName, 4);
        local s,e = string.find(Key, "^[A-Za-z_]+");
        local Suffix = string.sub(Key, e+1);
        if Suffix and tonumber(Suffix) and tonumber(Suffix) < 10 and not string.find(Suffix, "0[0-9]+") then
            Key = string.sub(Key, 1, e);
        end
        if UpgradeCategories[Key] then
            return UpgradeCategories[Key];
        end
    end
    return 0;
end

