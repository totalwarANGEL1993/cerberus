Lib.Register("module/uihacker/UiHacker");

---
---
---

UiHacker = {}

-- -------------------------------------------------------------------------- --
-- API

function UiHacker.Install()
    UiHacker.Internal:Install();
end

function UiHacker.CreateHack(_Name, _Function)
    return UiHacker.Internal:CreateHack(_Name, _Function);
end

function UiHacker.DeleteHack(_ID)
    UiHacker.Internal:DeleteHack(_ID);
end

function UiHacker.ExecuteOriginal(_Name, ...)
    UiHacker.Internal:ExecuteOriginal(_Name, unpack(arg));
end

-- -------------------------------------------------------------------------- --
-- Internal

UiHacker.Internal = {
    Data = {
        ID = 0,
        Originals = {},
        Hacks = {},
    },
}

function UiHacker.Internal:Install()
    if not self.IsInstalled then
        self.IsInstalled = true;

        self:OverrideGuiAction();
        self:OverrideGuiTooltip();
        self:OverrideGuiUpdate();
    end
end

function UiHacker.Internal:CreateHack(_Name, _Function)
    self.Data.ID = self.Data.ID +1;
    table.insert(self.Data.Hacks, {
        ID       = self.Data.ID,
        Target   = _Name,
        Function = _Function
    });
    return self.Data.ID;
end

function UiHacker.Internal:DeleteHack(_ID)
    for i= table.getn(self.Data.Hacks), 1, -1 do
        if self.Data.Hacks[i].ID == _ID then
            table.remove(self.Data.Hacks, i);
        end
    end
end

function UiHacker.Internal:ExecuteOriginal(_Name, ...)
    if not self.Data.Originals[_Name] then
        Message("UiHacker Error: Function \"" .._Name.. "\" is not supported!");
        return;
    end
    self.Data.Originals[_Name](unpack(arg));
end

function UiHacker.Internal:Execute(_Name, _WidgetID, ...)
    if not self.Data.Originals[_Name] then
        Message("UiHacker Error: Function \"" .._Name.. "\" is not supported!");
        return;
    end
    for i= 1, table.getn(self.Data.Hacks) do
        if self.Data.Hacks[i].Target == _Name then
            if self.Data.Hacks[i].Function(_Name, _WidgetID, unpack(arg)) then
                return;
            end
        end
    end
    self.Data.Originals[_Name](unpack(arg));
end

-- GUI Action --

function UiHacker.Internal:OverrideGuiAction()
    self.Data.Originals["GUIAction_BuyCannon"] = GUIAction_BuyCannon;
    GUIAction_BuyCannon = function(...)
        local Name = "GUIAction_BuyCannon";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIAction_BuyMilitaryUnit"] = GUIAction_BuyMilitaryUnit;
    GUIAction_BuyMilitaryUnit = function(...)
        local Name = "GUIAction_BuyMilitaryUnit";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIAction_ReserachTechnology"] = GUIAction_ReserachTechnology;
    GUIAction_ReserachTechnology = function(...)
        local Name = "GUIAction_ReserachTechnology";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end
    
    self.Data.Originals["GUIAction_ExpelSettler"] = GUIAction_ExpelSettler;
    GUIAction_ExpelSettler = function(...)
        local Name = "GUIAction_ExpelSettler";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIAction_BuySoldier"] = GUIAction_BuySoldier;
    GUIAction_BuySoldier = function(...)
        local Name = "GUIAction_BuySoldier";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIAction_ChangeFormation"] = GUIAction_ChangeFormation;
    GUIAction_ChangeFormation = function(...)
        local Name = "GUIAction_ChangeFormation";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIAction_PlaceBuilding"] = GUIAction_PlaceBuilding;
    GUIAction_PlaceBuilding = function(...)
        local Name = "GUIAction_PlaceBuilding";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIAction_ChangeBuildingMenu"] = GUIAction_ChangeBuildingMenu;
    GUIAction_ChangeBuildingMenu = function(...)
        local Name = "GUIAction_ChangeBuildingMenu";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIAction_SetTaxes"] = GUIAction_SetTaxes;
    GUIAction_SetTaxes = function(...)
        local Name = "GUIAction_SetTaxes";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIAction_BuySerf"] = GUIAction_BuySerf;
    GUIAction_BuySerf = function(...)
        local Name = "GUIAction_BuySerf";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIAction_BlessSettlers"] = GUIAction_BlessSettlers;
    GUIAction_BlessSettlers = function(...)
        local Name = "GUIAction_BlessSettlers";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end
end

-- GUI Tooltip --

function UiHacker.Internal:OverrideGuiTooltip()
    self.Data.Originals["GUITooltip_ConstructBuilding"] = GUITooltip_ConstructBuilding;
    GUITooltip_ConstructBuilding = function(...)
        local Name = "GUITooltip_ConstructBuilding";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUITooltip_ResearchTechnologies"] = GUITooltip_ResearchTechnologies;
    GUITooltip_ResearchTechnologies = function(...)
        local Name = "GUITooltip_ResearchTechnologies";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUITooltip_Generic"] = GUITooltip_Generic;
    GUITooltip_Generic = function(...)
        local Name = "GUITooltip_Generic";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUITooltip_UpgradeBuilding"] = GUITooltip_UpgradeBuilding;
    GUITooltip_UpgradeBuilding = function(...)
        local Name = "GUITooltip_UpgradeBuilding";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUITooltip_NormalButton"] = GUITooltip_NormalButton;
    GUITooltip_NormalButton = function(...)
        local Name = "GUITooltip_NormalButton";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUITooltip_BuySoldier"] = GUITooltip_BuySoldier;
    GUITooltip_BuySoldier = function(...)
        local Name = "GUITooltip_BuySoldier";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUITooltip_BlessSettlers"] = GUITooltip_BlessSettlers;
    GUITooltip_BlessSettlers = function(...)
        local Name = "GUITooltip_BlessSettlers";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end
end

-- GUI Update --

function UiHacker.Internal:OverrideGuiUpdate()
    self.Data.Originals["GUIUpdate_UpgradeButtons"] = GUIUpdate_UpgradeButtons;
    GUIUpdate_UpgradeButtons = function(...)
        local Name = "GUIUpdate_UpgradeButtons";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIUpdate_BuySoldierButton"] = GUIUpdate_BuySoldierButton;
    GUIUpdate_BuySoldierButton = function(...)
        local Name = "GUIUpdate_BuySoldierButton";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIUpdate_FindView"] = GUIUpdate_FindView;
    GUIUpdate_FindView = function(...)
        local Name = "GUIUpdate_FindView";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIUpdate_BuildingButtons"] = GUIUpdate_BuildingButtons;
    GUIUpdate_BuildingButtons = function(...)
        local Name = "GUIUpdate_BuildingButtons";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIUpdate_TaxesButtons"] = GUIUpdate_TaxesButtons;
    GUIUpdate_TaxesButtons = function(...)
        local Name = "GUIUpdate_TaxesButtons";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIUpdate_ResearchProgress"] = GUIUpdate_ResearchProgress;
    GUIUpdate_ResearchProgress = function(...)
        local Name = "GUIUpdate_ResearchProgress";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIUpdate_FaithProgress"] = GUIUpdate_FaithProgress;
    GUIUpdate_FaithProgress = function(...)
        local Name = "GUIUpdate_FaithProgress";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end
end

