Lib = {
    Paths = {
        "maps/externalmap/",
        "maps/user/" ..Framework.GetCurrentMapName().. "/",
        "maps/user/",
    },

    Sources = {},
    Loaded = {},
};

function Lib.Require(_Path)
    local Path = string.gsub(_Path, "/", "\\");
    for i= 1, table.getn(Lib.Paths) do
        if not Lib.Loaded[Path] then
            local Source = string.gsub(Lib.Paths[i], "/", "\\");
            Lib.Sources[_Path] = Source;
            Lib.Load(Source, Path);
        end
    end
    assert(Lib.Loaded[_Path] ~= nil, "\nFile not found: \n".._Path);
    Lib.Sources[_Path] = nil;
end

function Lib.Register(_Path)
    Lib.Loaded[_Path] = Lib.Sources[_Path] .. "cerberus\\";
end

function Lib.Load(_Source, _Path)
    local Path = _Source.. "cerberus\\" .._Path;
    Script.Load(Path.. ".lua");
end

