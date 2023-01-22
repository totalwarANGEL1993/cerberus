Lib.Register("comfort/GetLanguage");

--- Returns the localization (language) of the game.
--- @return string Language Shorthand symbol of language
---
--- @author totalwarANGEL
--- @version 1.0.0
---
function GetLanguage()
    local ShortLang = string.lower(XNetworkUbiCom.Tool_GetCurrentLanguageShortName());
    return (ShortLang == "de" and "de") or "en";
end

