Lib.Require("comfort/GetLanguage");
Lib.Register("comfort/Localize");

--- Returns the localized text from the input.
--- 
--- Alternatively, string table entries can be used. In that case the text is
--- returned. If no text is found to the key, the key is returned instead.
--- 
--- @param _Msg any Text to localize
--- @return string Text Localized text
function Localize(_Msg)
    local Language = GetLanguage();
    local Msg = _Msg;

    if type(Msg) == "table" then
        Msg = Msg[Language] or Msg["en"] or Language.. "no text found!";
    end
    if type(Msg) == "string" then
        if string.find(Msg, "^[A-Za-z0-9_]+/[A-Za-z0-9_]+$") then
            Msg = XGUIEng.GetStringTableText(Msg) or Msg;
        end
    end
    return Msg;
end

