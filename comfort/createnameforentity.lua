Lib.Register("comfort/CreateNameForEntity");

--- Returns all categories the entity is in.
--- @param _eID number Entity ID
--- @return string Name Script name
---
--- @author Noigi
--- @version 1.0.0
---
function CreateNameForEntity(_eID)
    if type(_eID) == "string" then
        return _eID;
    else
        assert(type(_eID) == "number");
        local name = Logic.GetEntityName(_eID);
        if (type(name) ~= "string" or name == "" ) then
            gvEntityNameCounter = gvEntityNameCounter + 1;
            name = "eName_"..gvEntityNameCounter;
            Logic.SetEntityName(_eID,name);
        end
        return name;
    end
end

