Lib = {
    Paths = {
        "maps/user/",
        "maps/user/" ..Framework.GetCurrentMapName().. "/",
        "maps/externalmap/",
    },

    Version = "1.1.0",
    Sources = {},
    Loaded = {},
};

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

function Lib.Register(_Path)
    local Key = string.gsub(_Path, "/", "_");
    Lib.Loaded[Key] = Lib.Sources[Key] .. "cerberus\\";
end

function Lib.Load(_Source, _Path)
    local Path = _Source.. "cerberus\\" .._Path;
    Script.Load(Path.. ".lua");
end

