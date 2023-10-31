Lib.Register("comfort/CreateNameForEntity");

-- Version: 1.0.0
-- Author:  Noigi

gvEntityNameCounter = gvEntityNameCounter or 0;

--- Returns all categories the entity is in.
--- @param _eID number Entity ID
--- @return string Name Script name
---
function CreateNameForEntity(_eID)
    if type(_eID) == "string" then
        return _eID;
    else
        assert(type(_eID) == "number");
        local name = Logic.GetEntityName(_eID);
        if (type(name) ~= "string" or name == "" ) then
            gvEntityNameCounter = gvEntityNameCounter + 1;
            name = "AutoScriptName_"..gvEntityNameCounter;
            Logic.SetEntityName(_eID,name);
        end
        return name;
    end
end

