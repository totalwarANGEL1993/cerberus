Lib.Register("comfort/GetLanguage");

-- Version: 1.0.0
-- Author:  totalwarANGEL

--- Returns the localization (language) of the game.
--- @return string Language Shorthand symbol of language
function GetLanguage()
    local ShortLang = string.lower(XNetworkUbiCom.Tool_GetCurrentLanguageShortName());
    return (ShortLang == "de" and "de") or "en";
end

