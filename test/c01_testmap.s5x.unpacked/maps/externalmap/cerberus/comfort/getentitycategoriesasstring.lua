Lib.Register("comfort/GetEntityCategoriesAsString");

--- Returns all categories the entity is in as strings.
--- @param _Entity any Entity ID or script name
--- @return table Categories List of categories
---
--- @author totalwarANGEL
--- @version 1.0.0
---
function GetEntityCategoriesAsString(_Entity)
    local Categories = {};
    for k, v in pairs(EntityCategories) do
        if Logic.IsEntityInCategory(GetID(_Entity), v) == 1 then
            table.insert(Categories, k);
        end
    end
    return Categories;
end

