Lib.Register("module/lua/Overwrite");

--- 
--- Owerwrite helper
--- 
--- Allows to overwrite any function directly in _G.
--- 
--- @author totalwarANGEL
--- @version 1.0.0
--- 

Overwrite = Overwrite or {};

-- -------------------------------------------------------------------------- --
-- API

--- Declares an new overwrite frame to the function.
--- @param _Name string       Name of function
--- @param _Function function Function to call instead
--- @return number ID ID of owerwrite
function Overwrite.CreateOverwrite(_Name, _Function)
    return Overwrite.Internal:CreateOverwrite(_Name, _Function);
end

--- Removes an overwrite from the function.
--- @param _Name string Name of function
--- @param _ID number   ID of overwrite
function Overwrite.DeleteOverwrite(_Name, _ID)
    Overwrite.Internal:DeleteOverwrite(_Name, _ID);
end

--- Calls the previous declaration of the function.
--- @return any Value The return value(s) of the call
function Overwrite.CallOriginal()
    return Overwrite.Internal:CallPrev();
end

-- -------------------------------------------------------------------------- --
-- Internal

Overwrite.Internal = Overwrite.Internal or {
    Overwrites = {},
    OverwriteSequenceId = 0,
    Context = {},
};

function Overwrite.Internal:Install()
    if not self.IsInstalled then
        self.IsInstalled = true;

        self:OverwriteOnSaveGameLoaded();
    end
end

function Overwrite.Internal:OverwriteOnSaveGameLoaded()
    self.Orig_Mission_OnSaveGameLoaded = Mission_OnSaveGameLoaded;
    Mission_OnSaveGameLoaded = function()
        Overwrite.Internal.Orig_Mission_OnSaveGameLoaded();
        for k, v in pairs(Overwrite.Internal.Overwrites) do
            Overwrite.Internal:ReplaceOriginal(k);
        end
    end
end

function Overwrite.Internal:CreateOverwrite(_Name, _Function)
    self:Install();

    self.OverwriteSequenceId = self.OverwriteSequenceId +1;
    local ID = self.OverwriteSequenceId;

    if not self.Overwrites[_Name] then
        -- FIXME: Does not work for functions not directly in _G
        self.Overwrites[_Name] = {Original = _G[_Name]};
        self:ReplaceOriginal(_Name);
    end
    table.insert(self.Overwrites[_Name], {ID, _Function});
    return ID;
end

function Overwrite.Internal:DeleteOverwrite(_Name, _ID)
    if self.Overwrites[_Name] then
        for i= table.getn(self.Overwrites[_Name]), 1, -1 do
            if self.Overwrites[_Name][1] == _ID then
                table.remove(self.Overwrites[_Name], i);
                break;
            end
        end
    end
end

function Overwrite.Internal:CallPrev()
    local Frame = self.Context[table.getn(self.Context)];
    assert(Frame ~= nil, "Context frame is nil!");
    assert(Frame[2] > 0, "Previous overwrite called in original!");
    return self:Invoke(Frame[1], Frame[2] -1, unpack(Frame[3]));
end

function Overwrite.Internal:Call()
    local Frame = self.Context[table.getn(self.Context)];
    assert(Frame ~= nil, "Context frame is nil!");
    if Frame[2] < 1 then
        return self.Overwrites[Frame[1]].Original(unpack(Frame[3]));
    else
        return self.Overwrites[Frame[1]][Frame[2]][2](unpack(Frame[3]));
    end
end

function Overwrite.Internal:Invoke(_Name, _Idx, ...)
    _Idx = (_Idx == -1 and table.getn(self.Overwrites[_Name])) or _Idx;
    table.insert(self.Context, {_Name, _Idx, arg});
    local Values = {self:Call()};
    table.remove(self.Context);
    return unpack(Values);
end

function Overwrite.Internal:ReplaceOriginal(_Name)
    -- FIXME: Does not work for functions not directly in _G
    _G[_Name] = function(...)
        -- _Name is an upvalue! Must be redone after savegame loaded!
        return Overwrite.Internal:Invoke(_Name, -1, unpack(arg));
    end
end

