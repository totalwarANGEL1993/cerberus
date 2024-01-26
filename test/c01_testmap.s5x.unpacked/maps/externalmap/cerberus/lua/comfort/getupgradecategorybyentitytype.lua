Lib.Register("comfort/GetUpgradeCategoryByEntityType");

-- Version: 1.1.0
-- Author:  totalwarANGEL

GetUpgradeCategoryByEntityType_IsBuildingCache = {};
GetUpgradeCategoryByEntityType_IsSettlerCache = {};

GetUpgradeCategoryByEntityType_CategoryMap = {
    [Entities.CU_BanditLeaderBow1] = UpgradeCategories.LeaderBanditBow,
    [Entities.CU_BanditSoldierBow1] = UpgradeCategories.SoldierBanditBow,
    [Entities.CU_BanditLeaderSword1] = UpgradeCategories.LeaderBandit,
    [Entities.CU_BanditSoldierSword1] = UpgradeCategories.SoldierBandit,
    [Entities.CU_BanditLeaderSword2] = UpgradeCategories.LeaderBandit,
    [Entities.CU_BanditSoldierSword2] = UpgradeCategories.SoldierBandit,
    [Entities.CU_Barbarian_LeaderClub1] = UpgradeCategories.LeaderBarbarian,
    [Entities.CU_Barbarian_SoldierClub1] = UpgradeCategories.SoldierBarbarian,
    [Entities.CU_Barbarian_LeaderClub2] = UpgradeCategories.LeaderBarbarian,
    [Entities.CU_Barbarian_SoldierClub2] = UpgradeCategories.SoldierBarbarian,
    [Entities.CU_BlackKnight_LeaderMace1] = UpgradeCategories.BlackKnightLeaderMace1,
    [Entities.CU_BlackKnight_SoldierMace1] = UpgradeCategories.BlackKnightSoldierMace1,
    [Entities.CU_BlackKnight_LeaderMace2] = UpgradeCategories.BlackKnightLeaderMace1,
    [Entities.CU_BlackKnight_SoldierMace2] = UpgradeCategories.BlackKnightSoldierMace1,
    [Entities.PV_Cannon1] = UpgradeCategories.Cannon1,
    [Entities.PV_Cannon2] = UpgradeCategories.Cannon2,
    [Entities.PV_Cannon3] = UpgradeCategories.Cannon3,
    [Entities.PV_Cannon4] = UpgradeCategories.Cannon4,
};

--- Returns the upgrade category of the entity type
--- @param _Type number Entity type
--- @return number Category Upgrade category
function GetUpgradeCategoryByEntityType(_Type)
    local TypeName = Logic.GetEntityTypeName(_Type);
    if TypeName then
        -- Save building or settler to not compare strings the second time
        if  not GetUpgradeCategoryByEntityType_IsBuildingCache[_Type]
        and not GetUpgradeCategoryByEntityType_IsSettlerCache[_Type] then
            if string.find(TypeName, "CU_") or string.find(TypeName, "PV_")
            or string.find(TypeName, "PU_") or string.find(TypeName, "CV_")
            or string.find(TypeName, "XA_") then
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
            if GetUpgradeCategoryByEntityType_CategoryMap[_Type] then
                return GetUpgradeCategoryByEntityType_CategoryMap[_Type];
            end
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

