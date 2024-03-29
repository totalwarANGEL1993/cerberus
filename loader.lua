Lib = {
    -- Searching paths
    -- The paths listed below will be checked for the components from first
    -- to last entry.
    Paths = {
        -- Search in folder map
        "maps/user/" ..Framework.GetCurrentMapName().. "/",
        -- Search in map archive
        "maps/externalmap/",
        -- Search in script directory
        "script/",
    },

    Version = "1.4.1",
    Sources = {},
    Loaded = {},
};

--- Loads a component at the given relative path.
--- @param _Path string Relative path
function Lib.Require(_Path)
    -- Define it if it is not defined in the script.
    Mission_OnSaveGameLoaded = Mission_OnSaveGameLoaded or function()
    end

    local Key = string.gsub(_Path, "/", "_");
    local Path = string.gsub(_Path, "/", "\\");
    for i= 1, table.getn(Lib.Paths) do
        if not Lib.Loaded[Key] then
            local Source = string.gsub(Lib.Paths[i], "/", "\\");
            Lib.Sources[Key] = Source;
            Lib.Load(Source, Path);
        end
    end
    assert(Lib.Loaded[Key] ~= nil, "\nFile not found: \n".._Path);
    Lib.Sources[Key] = nil;
end

--- Adds a path at top of the search order.
--- @param _Path string Path to search in
function Lib.AddPath(_Path)
    table.insert(Lib.Paths, 1, _Path);
end

--- DO NOT USE THIS MANUALLY!
--- Registers a component as found.
--- @param _Path string Relative path
function Lib.Register(_Path)
    local Key = string.gsub(_Path, "/", "_");
    Lib.Loaded[Key] = Lib.Sources[Key] .. "cerberus\\lua\\";
end

--- DO NOT USE THIS MANUALLY!
--- Loads the component from the source folder.
--- @param _Source string Path where the component is loaded from
--- @param _Path string   Relative path of component
function Lib.Load(_Source, _Path)
    local Path = _Source.. "cerberus\\lua\\" .._Path;
    Script.Load(Path.. ".lua");
end

