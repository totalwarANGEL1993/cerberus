LibWriter = {
    ComponentList = {
        "module/ai/aiarmy",
        "module/ai/aiarmyrefiller",
        "module/ai/aitroopspawner",
        "module/ai/aitrooptrainer",
        "module/archive/archive",
        "module/archive/s5hook",
        "module/camera/freecam",
        "module/cinematic/cinematic",
        "module/cinematic/briefingsystem",
        "module/cinematic/cutscenesystem",
        "module/cinematic/spectatablebriefing",
        "module/entity/entitymover",
        "module/entity/entitytracker",
        "module/entity/svlib",
        "module/entity/treasure",
        "module/io/interaction",
        "module/io/nonplayercharacter",
        "module/io/nonplayermerchant",
        "module/lua/extension",
        "module/lua/overwrite",
        "module/mp/buyhero",
        "module/mp/syncer",
        "module/quest/questconstants",
        "module/quest/questsystem",
        "module/trigger/job",
        "module/tutorial/tutorial",
        "module/ui/clock",
        "module/ui/placeholder",
        "module/ui/workplace",
        "module/weather/desertweatherset",
        "module/weather/europeanweatherset",
        "module/weather/evelanceweatherset",
        "module/weather/highlandsweatherset",
        "module/weather/mediterranweatherset",
        "module/weather/swampweatherset",
        "module/weather/weathermaker",
    },
    Behaviors = "",
    Compile = false,
    LoadOrderFromFile = false,
    SingleFile = false,
}

--- Runs the build process.
--- @param ... unknown Program arguments
function LibWriter:Run(...)
    local Action = self:ProcessArguments();
    if Action == 0 then
        print("Usage:");
        print("-b [-c] [-o] [Files] - build cerberus in var/cerberus");
        print("                       * -c compiles files to bytecode");
        print("                         (needs lua 5.0.x compiler!)");
        print("                       * -o loadorder from following wile");
        print("-l [-o] [Files]      - alphabetical list of loaded dependencies");
        print("-h                   - show this help");
        return;
    end

    if Action == 1 then
        self:DeleteFolder("var");
        self:CreateFolder("var/cerberus");
        self:CopyModules();
    elseif Action == 2 then
        print("Files loaded:");
        local Files = self:ReadFilesLoop();
        table.sort(Files);
        for i= 1, table.getn(Files) do
            print("> " ..Files[i]:lower());
        end
    end
end

--- Takes the programm arguments and processes them as source paths.
--- * 0  Arguments: Take default component list
--- * 1  Argument:  Load list from file
--- * 2+ Arguments: Load as components in this order
function LibWriter:ProcessArguments()
    if table.getn(arg) > 0 then
        local Command = table.remove(arg, 1);
        local Parameter = arg;
        if Command == "-b" or Command == "build" then
            -- Compile?
            Command = arg[1];
            if Command and Command == "-c" then
                if string.find(_VERSION, "5%.0") then
                    self.Compile = true;
                    table.remove(arg, 1);
                else
                    print("Error: Need Lua 5.0.x compiler!");
                    table.remove(arg, 1);
                end
            end
            -- load order from file?
            Command = arg[1];
            if Command and Command == "-o" then
                self.LoadOrderFromFile = true;
                table.remove(arg, 1);
            end

            if table.getn(Parameter) > 0 then
                if self.LoadOrderFromFile then
                    self.ComponentList = self:GetLoadOrderFromFile(Parameter[1]);
                else
                    self.ComponentList = Parameter;
                end
            end
            return 1;
        elseif Command == "-l" or Command == "list" then
            -- load order from file?
            Command = arg[1];
            if Command and Command == "-o" then
                self.LoadOrderFromFile = true;
                table.remove(arg, 1);
            end

            if table.getn(Parameter) > 0 then
                if self.LoadOrderFromFile then
                    self.ComponentList = self:GetLoadOrderFromFile(Parameter[1]);
                else
                    self.ComponentList = Parameter;
                end
            end
            return 2;
        end
    end
    return 0;
end

--- Copies the module files with dependencies to the output folder.
function LibWriter:CopyModules()
    print("Copy files...");
    self:CopyFile("loader.lua","var/cerberus/loader.lua");
    self:CompileFile("var/cerberus/loader.lua", "var/cerberus/loader.lua");

    local imports = self:ReadFilesLoop();
    for i= table.getn(imports), 1, -1 do
        local index = string.find(imports[i], "/[^/]*$");
        local Path = "var/cerberus/"..imports[i]:sub(1, index-1);
        local File = imports[i]:sub(index+1):lower();
        if not self:IsDir(Path) then
            self:CreateFolder(Path);
        end
        self:CopyFile("lua/"..imports[i]..".lua", Path.."/"..File..".lua");
        self:CompileFile("lua/"..imports[i]..".lua", Path.. "/" ..File.. ".lua");
    end
    print("Done!");
end

--- Reads all dependencies from all active modules and saves them
--- into the component.
--- @return table Paths List of paths
function LibWriter:ReadFilesLoop()
    local Paths = {Result = {}};
    for i= table.getn(self.ComponentList), 1, -1 do
        Paths[i] = {};
        ---@diagnostic disable-next-line: param-type-mismatch
        self:ReadFileAndDependencies(self.ComponentList[i], Paths[i]);
        table.insert(Paths[i], self.ComponentList[i]:lower());
    end
    for i= 1, table.getn(Paths) do
        for j= 1, table.getn(Paths[i]) do
            if not self:InTable(Paths[i][j], Paths.Result) then
                table.insert(Paths.Result, Paths[i][j]);
            end
        end
    end
    return Paths.Result;
end

--- Recursivly searches for the dependencies of the passed file and
--- writes them all into the passed array.
--- Each entry is only added once.
--- @param _Path string Path of file
--- @param _Paths table Dependency array
function LibWriter:ReadFileAndDependencies(_Path, _Paths)
    local Paths = {};
    for line in io.lines("lua/" .._Path:lower() .. ".lua") do
        if line:find("Register") then
            break;
        end
        local s,e = line:find("Lib%.Require%(\".*\"");
        if s and s > 0 then
            table.insert(Paths, 1, line:sub(s+13, e-1):lower());
        end
    end
    for i= 1, table.getn(Paths) do
        self:ReadFileAndDependencies(Paths[i], _Paths);
        table.insert(_Paths, Paths[i]);
    end
end

function LibWriter:InTable(_Entry, _Table)
    for i= 1, table.getn(_Table) do
        if _Table[i] == _Entry then
            return true;
        end
    end
    return false;
end

--- Compiles the source file and moves it to the destination.
--- @param _Source string Source file location
--- @param _Dest string   Destination location
function LibWriter:CompileFile(_Source, _Dest)
    if self.Compile then
        os.execute('luac "'.._Source..'"');
        LibWriter:MoveFile("luac.out", _Dest);
    end
end

--- Reads the load order from a file.
--- @param _Path string File location
--- @return table List List of modules
function LibWriter:GetLoadOrderFromFile(_Path)
    local Paths = {};
    if self:FileExists(_Path) then
        for line in io.lines(_Path:lower()) do
            table.insert(Paths, line);
        end
    end
    return Paths;
end

-- ### File System stuff ### --

--- Returns if the file is an directory.
--- @param _File string Path to file
--- @return boolean IsDir File is directory
function LibWriter:IsDir(_File)
    return self:FileExists(_File.. "/");
end

--- Checks if the file does exist.
--- @param _File string Path to file
--- @return boolean Exists File does exist
--- @return string? Error Optional error text
function LibWriter:FileExists(_File)
    local ok, err, code = os.rename(_File, _File);
    if not ok then
        if code == 13 then
            return true;
        end
    end
    return ok, err;
end

--- Moves a file to another folder.
--- @param _Source string Path to file
--- @param _Dest string Path to move
function LibWriter:MoveFile(_Source, _Dest)
    if string.find(self:GetOS(), "windows") then
        os.execute('move "' .._Source.. '" "' .._Dest.. '"');
    else
        os.execute('mv "' .._Source.. '" "' .._Dest.. '"');
    end
end

--- Copies a file to another folder.
--- @param _Source string Path to file
--- @param _Dest string Path to copy
function LibWriter:CopyFile(_Source, _Dest)
    if string.find(self:GetOS(), "windows") then
        os.execute('xcopy /s "' .._Source.. '" "' .._Dest.. '"');
    else
        os.execute('cp "' .._Source.. '" "' .._Dest.. '"');
    end
end

--- Creates a folder.
--- @param _Path string Path to folder
function LibWriter:CreateFolder(_Path)
    if string.find(self:GetOS(), "Windows") then
        os.execute('mkdir "' .._Path.. '"');
    else
        os.execute('mkdir "' .._Path.. '"');
    end
end

--- Deletes an folder.
--- @param _Path string path to folder
function LibWriter:DeleteFolder(_Path)
    if string.find(self:GetOS(), "Windows") then
        os.execute('rd /s/q "' .._Path.. '"');
    else
        os.execute('rm -rf "' .._Path.. '"');
    end
end

--- Returns the operating system.
--- @return string OS Operating system
function LibWriter:GetOS()
	local fh,err = io.popen("uname","r");
	if fh then
		osname = fh:read();
	end
	return string.lower(osname) or "windows";
end

-- -------------------------------------------------------------------------- --

LibWriter:Run(unpack(arg));

