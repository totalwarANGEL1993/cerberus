Lib.Register("comfort/GetEntityCategories");

--- Returns all categories the entity is in.
--- @param _Entity any Entity ID or script name
--- @return table Categories List of categories
---
--- @author totalwarANGEL
--- @version 1.0.0
---
function GetEntityCategories(_Entity)
    local Categories = {};
    for k, v in pairs(EntityCategories) do
        if Logic.IsEntityInCategory(GetID(_Entity), v) == 1 then
            table.insert(Categories, v);
        end
    end
    return Categories;
end

