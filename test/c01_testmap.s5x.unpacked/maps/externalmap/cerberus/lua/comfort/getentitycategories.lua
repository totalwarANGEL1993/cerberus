Lib.Register("comfort/GetEntityCategories");

-- Version: 1.0.0
-- Author:  totalwarANGEL

--- Returns all categories the entity is in.
--- @param _Entity any Entity ID or script name
--- @return table Categories List of categories
function GetEntityCategories(_Entity)
    local Categories = {};
    for k, v in pairs(EntityCategories) do
        if Logic.IsEntityInCategory(GetID(_Entity), v) == 1 then
            table.insert(Categories, v);
        end
    end
    return Categories;
end

