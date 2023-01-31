Lib.Require("comfort/GetLanguage");
Lib.Register("module/ui/Placeholder");

--- 
--- Placeholder replacement script
--- 
--- Allows to set placeholders and replace them in strings.
--- 
--- Default placeholders:
--- * {cr}      - Replaced with: @cr
--- * {nl}      - Replaced with: @cr
--- * {ra}      - Replaced with: @ra
--- * {qq}      - Replaced with: \"
--- * {center}  - Replaced with: @center
--- * {red}     - Replaced with: @color:255,0,0
--- * {scarlet} - Replaced with: @color:190,0,0
--- * {green}   - Replaced with: @color:0,180,0
--- * {blue}    - Replaced with: @color:0,0,180
--- * {yellow}  - Replaced with: @color:235,235,0
--- * {violet}  - Replaced with: @color:180,0,180
--- * {orange}  - Replaced with: @color:235,158,52
--- * {azure}   - Replaced with: @color:0,180,180
--- * {black}   - Replaced with: @color:40,40,40
--- * {white}   - Replaced with: @color:255,255,255
--- * {grey}    - Replaced with: @color:180,180,180
--- * {none}    - Replaced with: @color:0,0,0,0
--- 
--- @require GetLanguage
--- @author totalwarANGEL
--- @version 1.0.0
--- 

Placeholder = Placeholder or {}

-- -------------------------------------------------------------------------- --
-- API

--- Installs the placeholder replacer.
--- (This is usually called by code from other scripts.)
function Placeholder.Install()
    Placeholder.Internal:Install();
end

--- Replaces all placeholders in the string with their values.
--- @param _Message string String with message
--- @return string Text String with replaced placeholders
function Placeholder.Replace(_Message)
    return Placeholder.Internal:ReplaceInString(_Message);
end

--- Removes all placeholders from the string.
--- @param _Message string String with message
--- @return string String with all placeholders removed
function Placeholder.Clean(_Message)
    return Placeholder.Internal:RemoveFormattingPlaceholders(_Message);
end

--- Defines a placeholder for a value.
--- (Can be the value or a function that returns the value.)
--- 
--- The placeholder is placed in the text by typing {v:XXX} where XXX is the
--- name of the placeholder.
--- 
--- @param _Key string placeholder name
--- @param _Value any  Placeholder value
function Placeholder.DefineValuePlaceholder(_Key, _Value)
    Placeholder.Internal.Data.Values[_Key] = _Value;
end

--- Defines a placeholder for a scriptname.
--- (Can be the value or a function that returns the value.)
--- 
--- The placeholder is placed in the text by typing {n:XXX} where XXX is the
--- name of the placeholder.
--- 
--- @param _ScriptName string placeholder name
--- @param _Value any         Name for scriptname
function Placeholder.DefineNamePlaceholder(_ScriptName, _Value)
    Placeholder.Internal.Data.Names[_ScriptName] = _Value;
end

-- -------------------------------------------------------------------------- --
-- Internal

Placeholder.Internal = Placeholder.Internal or {
    Data = {
        Values = {},
        Names  = {},
    },

    Config = {
        Mapping = {
            ["{cr}"]      = " @cr ",
            ["{nl}"]      = " @cr ",
            ["{ra}"]      = " @ra ",
            ["{qq}"]      = "\"",
            ["{center}"]  = " @center ",
            ["{red}"]     = " @color:255,0,0 ",
            ["{scarlet}"] = " @color:190,0,0 ",
            ["{green}"]   = " @color:0,180,0 ",
            ["{blue}"]    = " @color:0,0,180 ",
            ["{yellow}"]  = " @color:235,235,0 ",
            ["{violet}"]  = " @color:180,0,180 ",
            ["{orange}"]  = " @color:235,158,52 ",
            ["{azure}"]   = " @color:0,180,180 ",
            ["{black}"]   = " @color:40,40,40 ",
            ["{white}"]   = " @color:255,255,255 ",
            ["{grey}"]    = " @color:180,180,180 ",
            ["{none}"]    = " @color:0,0,0,0 ",
        }
    }
};

function Placeholder.Internal:Install()
    if not self.IsInstalled then
        self.IsInstalled = true;

        self:OverrideMessagePrinter();
    end
end

function Placeholder.Internal:OverrideMessagePrinter()
    self.Orig_Message = Message;
    Message = function(_Text)
        local Text = Placeholder.Internal:ReplaceInString(_Text);
        Placeholder.Internal.Orig_Message(Text);
    end
end

function Placeholder.Internal:ReplaceInString(_Message)
    if type(_Message) == "table" then
        for k, v in pairs(_Message) do
            _Message[k] = self:ReplaceInString(v);
        end

    elseif type(_Message) == "string" then
        -- Replace valued placeholders
        _Message = self:ReplaceValuesInString(_Message);

        -- Replace basic placeholders last
        for k,v in pairs(self.Config.Mapping) do
            _Message = string.gsub(_Message, k, v);
        end
    end
    return _Message;
end

function Placeholder.Internal:ReplaceValuesInString(_Message)
    local s, e = string.find(_Message, "{", 1);
    while (s) do
        local ss, ee      = string.find(_Message, "}", e+1);
        local Before      = (s <= 1 and "") or string.sub(_Message, 1, s-1);
        local After       = (ee and string.sub(_Message, ee+1)) or "";
        local Placeholder = string.sub(_Message, e+1, ss-1);

        if string.find(Placeholder, "c:") then
            _Message = Before .. " @" .. Placeholder .. " " .. After;
        end
        if string.find(Placeholder, "v:") then
            local Key = string.sub(Placeholder, string.find(Placeholder, ":")+1);
            local Value = self.Data.Values[Key];
            if not Value then
                Value = _G[Key];
            end
            if type(Value) == "function" then
                Value = Value(Key);
            end
            if type(Value) == "string" or type(Value) == "number" then
                _Message = Before .. Value .. After;
            end
        end
        if string.find(Placeholder, "n:") then
            local Key = string.sub(Placeholder, string.find(Placeholder, ":")+1);
            local Value = self.Data.Names[Key];
            if type(Value) == "function" then
                Value = Value(Key);
            end
            if type(Value) == "string" then
                _Message = Before .. Value .. After;
            end
        end
        s, e = string.find(_Message, "{", ee+1);
    end
    return _Message;
end

function Placeholder.Internal:RemoveFormattingPlaceholders(_Message)
    if type(_Message) == "table" then
        for k, v in pairs(_Message) do
            _Message[k] = self:RemoveFormattingPlaceholders(v);
        end
    elseif type(_Message) == "string" then
        _Message = string.gsub(_Message, "{ra}", "");
        _Message = string.gsub(_Message, "{center}", "");
        _Message = string.gsub(_Message, "{color:%d,%d,%d}", "");
        _Message = string.gsub(_Message, "{color:%d,%d,%d,%d}", "");
        _Message = string.gsub(_Message, "{red}", "");
        _Message = string.gsub(_Message, "{scarlet}", "");
        _Message = string.gsub(_Message, "{green}", "");
        _Message = string.gsub(_Message, "{blue}", "");
        _Message = string.gsub(_Message, "{yellow}", "");
        _Message = string.gsub(_Message, "{violet}", "");
        _Message = string.gsub(_Message, "{orange}", "");
        _Message = string.gsub(_Message, "{azure}", "");
        _Message = string.gsub(_Message, "{black}", "");
        _Message = string.gsub(_Message, "{white}", "");
        _Message = string.gsub(_Message, "{grey}", "");
        _Message = string.gsub(_Message, "{none}", "");

        _Message = string.gsub(_Message, " @color:%d,%d,%d ", " ");
        _Message = string.gsub(_Message, " @color:%d,%d,%d,%d ", " ");
        _Message = string.gsub(_Message, " @center ", " ");
        _Message = string.gsub(_Message, " @ra ", " ");
    end
    return _Message;
end

