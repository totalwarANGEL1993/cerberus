--- Returns the tooltip text separated in sections.
--- @param _Key string Key of text
--- @return table Text Table with text chunks 
---
--- @author totalwarANGEL
--- @version 1.0.0
---
function GetSeparatedTooltipText(_Key)
    local Text = XGUIEng.GetStringTableText(_Key);
    local LBHStard, LBHEnd = string.find(Text, "@cr");
    if not LBHStard then
        return {"", ""};
    end
    local TextHeader = string.sub(Text, 1, LBHStard-1);
    local TextBody = string.sub(Text, LBHEnd+2);
    local LBTStart, LBTEnd = string.find(TextBody, "@cr");
    local TextParts = {TextHeader, TextBody};
    if LBTStart then
        local SorceText = string.sub(TextBody, LBTEnd+2);
        TextBody = string.sub(TextBody, 1, LBTStart-1);
        TextParts[2] = TextBody;
        local s, e = string.find(SorceText, "@color:%d+,%d+,%d+,%d+ ");
        if s then
            while (s) do
                local lbs, lbe = string.find(SorceText, "@cr");
                if not lbs then
                    table.insert(TextParts, SorceText);
                    break;
                end
                table.insert(TextParts, string.sub(SorceText, lbe+1));
                SorceText = string.sub(SorceText, lbe+2);
                s, e = string.find(SorceText, "@color:%d+,%d+,%d+,%d+ ");
            end
        end
    end
    return TextParts;
end

