---@diagnostic disable: param-type-mismatch
Lib.Require("comfort/SerializeTable");
Lib.Register("module/lua/Extension");

--- 
--- Lua extension
--- 
--- Adds some string and table functionality as known from languages such as
--- Java or C#.
--- 
--- Version 1.0.0
--- 

Extension = Extension or {};
Extension.Internal = Extension.Internal or {};

-- -------------------------------------------------------------------------- --
-- API

function Extension.Install()
    Extension.Internal:Install();
end

function Extension.Internal:InitExtraTableFunctionality()
    --- Compares two tables with a comperator function.
    --- @param t1 table First table
    --- @param t2 table Second table
    --- @param fx function Comparator function
    --- @return integer Result Comparison result
    table.compare = function(t1, t2, fx)
        assert(type(t1) == "table");
        assert(type(t2) == "table");
        fx = fx or function(t1, t2)
            return tostring(t1) < tostring(t2);
        end
        assert(type(fx) == "function");
        return fx(t1, t2);
    end

    --- Returns if two tables are equal.
    --- @param t1 table First table
    --- @param t2 table Second table
    --- @return boolean Equals Tables are equal
    table.equals = function(t1, t2)
        assert(type(t1) == "table");
        assert(type(t2) == "table");
        local fx = function(t1, t2)
            return table.tostring(t1) < table.tostring(t2);
        end
        assert(type(fx) == "function");
        return fx(t1, t2);
    end

    --- Returns if element is contained in table.
    --- @param t table Table to check
    --- @param e any Element to find
    --- @return boolean Found Element is contained
    table.contains = function (t, e)
        assert(type(t) == "table");
        for k, v in pairs(t) do
            if v == e then
                return true;
            end
        end
        return false;
    end

    --- Returns the size of the array.
    --- @param t table Table
    --- @return integer Length Length
    table.length = function(t)
        return table.getn(t);
    end

    --- Returns the amount of all elements.
    --- @param t table Table
    --- @return integer Size Element count
    table.size = function(t)
        local c = 0;
        for k, v in pairs(t) do
            -- Ignore n if set
            if k ~= "n" or (k == "n" and type(v) ~= "number") then
                c = c +1;
            end
        end
        return c;
    end

    --- Checks if table is empty
    --- @param t table Table
    --- @return boolean Empty Table is empty
    table.isEmpty = function(t)
        return table.size(t) == 0;
    end

    --- Clones a table or merges two tables.
    --- @param t1 table First table
    --- @param t2? table Second table
    --- @return table Clone Copied table
    table.copy = function (t1, t2)
        t2 = t2 or {};
        assert(type(t1) == "table");
        assert(type(t2) == "table");
        return CopyTable(t1, t2);
    end

    --- Returns a reversed array.
    --- @param t1 table Table
    --- @return table Invert Inverted table
    table.invert = function (t1)
        assert(type(t1) == "table");
        local t2 = {};
        for i= table.length(t1), 1, -1 do
            table.insert(t2, t1[i]);
        end
        return t2;
    end

    --- Adds an element in front.
    --- @param t table Table
    --- @param e any Element
    table.push = function (t, e)
        assert(type(t) == "table");
        table.insert(t, 1, e);
    end

    --- Removes the first element.
    --- @param t table Table
    --- @return any Element Element
    table.pop = function (t)
        assert(type(t) == "table");
        return table.remove(t, 1);
    end

    --- Returns the table as lua string.
    --- @param t table Table
    --- @return string Serialized Serialized table
    table.tostring = function(t)
        return SerializeTable(t);
    end
end

function Extension.Internal:InitExtraStringFunctionality()
    --- Returns true if the partial string is found.
    --- @param _string stringlib String to search
    --- @param s string       Partial string
    --- @return boolean Found Partial string found
    string.contains = function (_string, s)
        return string.find(_string, s) ~= nil;
    end

    --- Returns true if the partial string is found.
    --- @param _string stringlib String to search
    --- @param s string       Partial string
    --- @return integer? Begin Start of part
    --- @return integer? End   End of part
    string.indexOf = function (_string, s)
        local b, e = string.find(_string, s);
        return b, e;
    end

    --- Separates a string into multiple strings.
    --- @param _string stringlib String to search
    --- @param _sep string    Separator string
    --- @return table List    List of partial strings
    string.slice = function(_string, _sep)
        _sep = _sep or "%s";
        local t = {};
        if self then
            for str in string.gfind(_string, "([^".._sep.."]+)") do
                table.insert(t, str);
            end
        end
        return t;
    end

    ---Concatinates a list of values to a single string.
    ---@param _string stringlib String to search
    ---@param ... any        Values
    ---@return string String Resulting string
    string.join = function(_string, ...)
        local s = "";
        local parts = {_string, unpack(arg)};
        for i= 1, table.getn(parts) do
            if type(parts[i]) == "table" then
                s = s .. string.join(unpack(parts[i]));
            else
                s = s .. tostring(parts[i]);
            end
        end
        return s;
    end

    --- Replaces a substring with another once.
    --- @param _string stringlib String to search
    --- @param p string       Pattern
    --- @param r string       Replacement
    --- @return string String New string
    string.replace = function(_string, p, r)
        local s, c = string.gsub(_string, p, r, 1);
        return s;
    end

    --- Replaces all occurances of a substring with another.
    --- @param _string stringlib String to search
    --- @param p string       Pattern
    --- @param r string       Replacement
    --- @return string String New string
    string.replaceAll = function(_string, p, r)
        local s, c = string.gsub(_string, p, r);
        return s;
    end
end

-- -------------------------------------------------------------------------- --
-- Internal

function Extension.Internal:Install()
    if not self.IsInstalled then
        self.IsInstalled = true;

        self:OverwriteOnSaveGameLoaded();
        self:OnSaveGameLoaded();
    end
end

function Extension.Internal:OnSaveGameLoaded()
    self:InitExtraTableFunctionality();
    self:InitExtraStringFunctionality();
end

function Extension.Internal:OverwriteOnSaveGameLoaded()
    self.Orig_Mission_OnSaveGameLoaded = Mission_OnSaveGameLoaded;
    Mission_OnSaveGameLoaded = function()
        Extension.Internal.Orig_Mission_OnSaveGameLoaded();
        Extension.Internal:OnSaveGameLoaded();
    end
end

