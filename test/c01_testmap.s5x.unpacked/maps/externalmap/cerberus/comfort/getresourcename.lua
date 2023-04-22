Lib.Register("comfort/GetResourceName");

--- Returns the interface name of the resource.
--- @param _ResourceType number Type of resource
--- @return string Name Resource name in GUI
---
--- @author Unknown
--- @version 1.0.0
---
function GetResourceName(_ResourceType)
    local GoodName = XGUIEng.GetStringTableText("InGameMessages/GUI_NameMoney");
    if _ResourceType == ResourceType.Clay or _ResourceType == ResourceType.ClayRaw then
        GoodName = XGUIEng.GetStringTableText("InGameMessages/GUI_NameClay");
    elseif _ResourceType == ResourceType.Wood or _ResourceType == ResourceType.WoodRaw then
        GoodName = XGUIEng.GetStringTableText("InGameMessages/GUI_NameWood");
    elseif _ResourceType == ResourceType.Stone or _ResourceType == ResourceType.StoneRaw then
        GoodName = XGUIEng.GetStringTableText("InGameMessages/GUI_NameStone");
    elseif _ResourceType == ResourceType.Iron or _ResourceType == ResourceType.IronRaw then
        GoodName = XGUIEng.GetStringTableText("InGameMessages/GUI_NameIron");
    elseif _ResourceType == ResourceType.Sulfur or _ResourceType == ResourceType.SulfurRaw then
        GoodName = XGUIEng.GetStringTableText("InGameMessages/GUI_NameSulfur");
    end
    return GoodName;
end

