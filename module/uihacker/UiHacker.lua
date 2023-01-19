Lib.Register("module/uihacker/UiHacker");

---
--- Provides a simple way to overwrite GUI functions.
---
--- Supported Actions:
--- * GUIAction_ActivateAlarm
--- * GUIAction_BlessSettlers
--- * GUIAction_BuyCannon
--- * GUIAction_BuyMerchantOffer
--- * GUIAction_BuyMilitaryUnit
--- * GUIAction_BuySerf
--- * GUIAction_BuySoldier
--- * GUIAction_CancelTechnology
--- * GUIAction_CancelTrade
--- * GUIAction_CancelUpgrade
--- * GUIAction_ChangeBuildingMenu
--- * GUIAction_ChangeFormation
--- * GUIAction_ChangeWeather
--- * GUIAction_Command
--- * GUIAction_ExpelSettler
--- * GUIAction_FindIdleSerf
--- * GUIAction_FindHero
--- * GUIAction_Hero1SendHawk
--- * GUIAction_Hero1ProtectUnits
--- * GUIAction_Hero1LookAtHawk
--- * GUIAction_Hero2PlaceBomb
--- * GUIAction_Hero2BuildCannon
--- * GUIAction_Hero3BuildTrap
--- * GUIAction_Hero3BuildTrap
--- * GUIAction_Hero4CircularAttack
--- * GUIAction_Hero4AuraOfWar
--- * GUIAction_Hero6Bless
--- * GUIAction_Hero6ConvertSettlers
--- * GUIAction_Hero7InflictFear
--- * GUIAction_Hero7Madness
--- * GUIAction_Hero8Poison
--- * GUIAction_Hero8MoraleDamage
--- * GUIAction_Hero9Berserk
--- * GUIAction_Hero9CallWolfs
--- * GUIAction_Hero10SniperAttack
--- * GUIAction_Hero10LongRangeAura
--- * GUIAction_Hero11Shuriken
--- * GUIAction_Hero11FireworksMotivate
--- * GUIAction_Hero11FireworksFear
--- * GUIAction_Hero12PoisonRange
--- * GUIAction_Hero12PoisonArrows
--- * GUIAction_MarketClearDeals
--- * GUIAction_MarketToggleResource
--- * GUIAction_MerchantReady
--- * GUIAction_OnlineHelp
--- * GUIAction_PlaceBuilding
--- * GUIAction_QuitAlarm
--- * GUIAction_ReserachTechnology
--- * GUIAction_SetTaxes
--- * GUIAction_ThiefPlaceExplosives
--- * GUIAction_ToggleMenu
--- * GUIAction_UpgradeSelectedBuilding
---
--- Supported Tooltips:
--- * GUITooltip_AbilityButton
--- * GUITooltip_AOFindHero
--- * GUITooltip_BlessSettlers
--- * GUITooltip_BuyMilitaryUnit
--- * GUITooltip_BuySerf
--- * GUITooltip_BuySoldier
--- * GUITooltip_ConstructBuilding
--- * GUITooltip_Generic
--- * GUITooltip_NormalButton
--- * GUITooltip_ResearchTechnologies
--- * GUITooltip_UpgradeBuilding
---
--- Supported Updates:
--- * GUIUpdate_AbilityButtons
--- * GUIUpdate_AlarmButton
--- * GUIUpdate_AverageMotivation
--- * GUIUpdate_BuildingButtons
--- * GUIUpdate_BuyHeroButton
--- * GUIUpdate_BuyMilitaryUnitButtons
--- * GUIUpdate_BuySoldierButton
--- * GUIUpdate_CannonProgress
--- * GUIUpdate_CurrentWorkersAmount
--- * GUIUpdate_FaithProgress
--- * GUIUpdate_FeatureButtons
--- * GUIUpdate_FindView
--- * GUIUpdate_GlobalTechnologiesButtons
--- * GUIUpdate_GroupStrength
--- * GUIUpdate_HeroButton
--- * GUIUpdate_HeroAbility
--- * GUIUpdate_IdelSerfAmount
--- * GUIUpdate_PaydayClock
--- * GUIUpdate_Population
--- * GUIUpdate_MarketTradeProgress
--- * GUIUpdate_MarketTradeWindow
--- * GUIUpdate_MerchantOffers
--- * GUIUpdate_ResourceAmount
--- * GUIUpdate_SelectionName
--- * GUIUpdate_SettlersUpgradeButtons
--- * GUIUpdate_TaxesButtons
--- * GUIUpdate_TaxLeaderAmount
--- * GUIUpdate_TaxLeaderCosts
--- * GUIUpdate_TaxPaydayIncome
--- * GUIUpdate_TaxTaxAmountOfWorker
--- * GUIUpdate_TaxSumOfTaxes
--- * GUIUpdate_TaxWorkerAmount
--- * GUIUpdate_TechnologyButtons
--- * GUIUpdate_ThiefSelection
--- * GUIUpdate_TroopOffer
--- * GUIUpdate_ToggleWeatherForecast
--- * GUIUpdate_ResearchProgress
--- * GUIUpdate_UpgradeButtons
--- * GUIUpdate_UpgradeProgress
--- * GUIUpdate_WeatherForecast
--- * GUIUpdate_WeatherEnergyProgress
---

UiHacker = {}

-- -------------------------------------------------------------------------- --
-- API

--- Installs the syncer.
--- (Must be called on game start!)
function UiHacker.Install()
    UiHacker.Internal:Install();
end

--- Creates a hack to overwrite a supported GUI function.
--- @param _Name string       Name of function
--- @param _Function function overwrite function
--- @return number ID Id of hack 
function UiHacker.CreateHack(_Name, _Function)
    return UiHacker.Internal:CreateHack(_Name, _Function);
end

--- Deletes the hack with the ID.
--- @param _ID number ID of hack
function UiHacker.DeleteHack(_ID)
    UiHacker.Internal:DeleteHack(_ID);
end

--- Calls the original function without invoking the hacks.
--- @param _Name string Name of function
--- @param ... any      List of parameters
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

        self:OverrideGeneralGuiAction();
        self:OverrideBuildingGuiAction();
        self:OverrideSettlerGuiAction();
        self:OverrideHeroGuiAction();

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

function UiHacker.Internal:OverrideGeneralGuiAction()
    self.Data.Originals["GUIAction_ToggleMenu"] = GUIAction_ToggleMenu;
    GUIAction_ToggleMenu = function(...)
        local Name = "GUIAction_ToggleMenu";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIAction_FindIdleSerf"] = GUIAction_FindIdleSerf;
    GUIAction_FindIdleSerf = function(...)
        local Name = "GUIAction_FindIdleSerf";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIAction_OnlineHelp"] = GUIAction_OnlineHelp;
    GUIAction_OnlineHelp = function(...)
        local Name = "GUIAction_OnlineHelp";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end
end

function UiHacker.Internal:OverrideSettlerGuiAction()
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

    self.Data.Originals["GUIAction_ExpelSettler"] = GUIAction_ExpelSettler;
    GUIAction_ExpelSettler = function(...)
        local Name = "GUIAction_ExpelSettler";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIAction_PlaceBuilding"] = GUIAction_PlaceBuilding;
    GUIAction_PlaceBuilding = function(...)
        local Name = "GUIAction_PlaceBuilding";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIAction_Command"] = GUIAction_Command;
    GUIAction_Command = function(...)
        local Name = "GUIAction_Command";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end
end

function UiHacker.Internal:OverrideBuildingGuiAction()
    self.Data.Originals["GUIAction_MerchantReady"] = GUIAction_MerchantReady;
    GUIAction_MerchantReady = function(...)
        local Name = "GUIAction_MerchantReady";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIAction_BuyMerchantOffer"] = GUIAction_BuyMerchantOffer;
    GUIAction_BuyMerchantOffer = function(...)
        local Name = "GUIAction_BuyMerchantOffer";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIAction_ChangeWeather"] = GUIAction_ChangeWeather;
    GUIAction_ChangeWeather = function(...)
        local Name = "GUIAction_ChangeWeather";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIAction_CancelTrade"] = GUIAction_CancelTrade;
    GUIAction_CancelTrade = function(...)
        local Name = "GUIAction_CancelTrade";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIAction_MarketToggleResource"] = GUIAction_MarketToggleResource;
    GUIAction_MarketToggleResource = function(...)
        local Name = "GUIAction_MarketToggleResource";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIAction_MarketClearDeals"] = GUIAction_MarketClearDeals;
    GUIAction_MarketClearDeals = function(...)
        local Name = "GUIAction_MarketClearDeals";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIAction_ActivateAlarm"] = GUIAction_ActivateAlarm;
    GUIAction_ActivateAlarm = function(...)
        local Name = "GUIAction_ActivateAlarm";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIAction_QuitAlarm"] = GUIAction_QuitAlarm;
    GUIAction_QuitAlarm = function(...)
        local Name = "GUIAction_QuitAlarm";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIAction_CancelTechnology"] = GUIAction_CancelTechnology;
    GUIAction_CancelTechnology = function(...)
        local Name = "GUIAction_CancelTechnology";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIAction_CancelUpgrade"] = GUIAction_CancelUpgrade;
    GUIAction_CancelUpgrade = function(...)
        local Name = "GUIAction_CancelUpgrade";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIAction_UpgradeSelectedBuilding"] = GUIAction_UpgradeSelectedBuilding;
    GUIAction_UpgradeSelectedBuilding = function(...)
        local Name = "GUIAction_UpgradeSelectedBuilding";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIAction_ReserachTechnology"] = GUIAction_ReserachTechnology;
    GUIAction_ReserachTechnology = function(...)
        local Name = "GUIAction_ReserachTechnology";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIAction_SetTaxes"] = GUIAction_SetTaxes;
    GUIAction_SetTaxes = function(...)
        local Name = "GUIAction_SetTaxes";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIAction_ChangeBuildingMenu"] = GUIAction_ChangeBuildingMenu;
    GUIAction_ChangeBuildingMenu = function(...)
        local Name = "GUIAction_ChangeBuildingMenu";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIAction_BlessSettlers"] = GUIAction_BlessSettlers;
    GUIAction_BlessSettlers = function(...)
        local Name = "GUIAction_BlessSettlers";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

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

    self.Data.Originals["GUIAction_BuySerf"] = GUIAction_BuySerf;
    GUIAction_BuySerf = function(...)
        local Name = "GUIAction_BuySerf";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end
end

function UiHacker.Internal:OverrideHeroGuiAction()
    self.Data.Originals["GUIAction_ThiefPlaceExplosives"] = GUIAction_ThiefPlaceExplosives;
    GUIAction_ThiefPlaceExplosives = function(...)
        local Name = "GUIAction_ThiefPlaceExplosives";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIAction_Hero1SendHawk"] = GUIAction_Hero1SendHawk;
    GUIAction_Hero1SendHawk = function(...)
        local Name = "GUIAction_Hero1SendHawk";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIAction_Hero1ProtectUnits"] = GUIAction_Hero1ProtectUnits;
    GUIAction_Hero1ProtectUnits = function(...)
        local Name = "GUIAction_Hero1ProtectUnits";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIAction_Hero1LookAtHawk"] = GUIAction_Hero1LookAtHawk;
    GUIAction_Hero1LookAtHawk = function(...)
        local Name = "GUIAction_Hero1LookAtHawk";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIAction_Hero2PlaceBomb"] = GUIAction_Hero2PlaceBomb;
    GUIAction_Hero2PlaceBomb = function(...)
        local Name = "GUIAction_Hero2PlaceBomb";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIAction_Hero2BuildCannon"] = GUIAction_Hero2BuildCannon;
    GUIAction_Hero2BuildCannon = function(...)
        local Name = "GUIAction_Hero2BuildCannon";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIAction_Hero3BuildTrap"] = GUIAction_Hero3BuildTrap;
    GUIAction_Hero3BuildTrap = function(...)
        local Name = "GUIAction_Hero3BuildTrap";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIAction_Hero3BuildTrap"] = GUIAction_Hero3BuildTrap;
    GUIAction_Hero3BuildTrap = function(...)
        local Name = "GUIAction_Hero3BuildTrap";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIAction_Hero4CircularAttack"] = GUIAction_Hero4CircularAttack;
    GUIAction_Hero4CircularAttack = function(...)
        local Name = "GUIAction_Hero4CircularAttack";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIAction_Hero4AuraOfWar"] = GUIAction_Hero4AuraOfWar;
    GUIAction_Hero4AuraOfWar = function(...)
        local Name = "GUIAction_Hero4AuraOfWar";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIAction_Hero6Bless"] = GUIAction_Hero6Bless;
    GUIAction_Hero6Bless = function(...)
        local Name = "GUIAction_Hero6Bless";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIAction_Hero6ConvertSettlers"] = GUIAction_Hero6ConvertSettlers;
    GUIAction_Hero6ConvertSettlers = function(...)
        local Name = "GUIAction_Hero6ConvertSettlers";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIAction_Hero7InflictFear"] = GUIAction_Hero7InflictFear;
    GUIAction_Hero7InflictFear = function(...)
        local Name = "GUIAction_Hero7InflictFear";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIAction_Hero7Madness"] = GUIAction_Hero7Madness;
    GUIAction_Hero7Madness = function(...)
        local Name = "GUIAction_Hero7Madness";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIAction_Hero8Poison"] = GUIAction_Hero8Poison;
    GUIAction_Hero8Poison = function(...)
        local Name = "GUIAction_Hero8Poison";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIAction_Hero8MoraleDamage"] = GUIAction_Hero8MoraleDamage;
    GUIAction_Hero8MoraleDamage = function(...)
        local Name = "GUIAction_Hero8MoraleDamage";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIAction_Hero9Berserk"] = GUIAction_Hero9Berserk;
    GUIAction_Hero9Berserk = function(...)
        local Name = "GUIAction_Hero9Berserk";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIAction_Hero9CallWolfs"] = GUIAction_Hero9CallWolfs;
    GUIAction_Hero9CallWolfs = function(...)
        local Name = "GUIAction_Hero9CallWolfs";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIAction_Hero10SniperAttack"] = GUIAction_Hero10SniperAttack;
    GUIAction_Hero10SniperAttack = function(...)
        local Name = "GUIAction_Hero10SniperAttack";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIAction_Hero10LongRangeAura"] = GUIAction_Hero10LongRangeAura;
    GUIAction_Hero10LongRangeAura = function(...)
        local Name = "GUIAction_Hero10LongRangeAura";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIAction_Hero11Shuriken"] = GUIAction_Hero11Shuriken;
    GUIAction_Hero11Shuriken = function(...)
        local Name = "GUIAction_Hero11Shuriken";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIAction_Hero11FireworksMotivate"] = GUIAction_Hero11FireworksMotivate;
    GUIAction_Hero11FireworksMotivate = function(...)
        local Name = "GUIAction_Hero11FireworksMotivate";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIAction_Hero11FireworksFear"] = GUIAction_Hero11FireworksFear;
    GUIAction_Hero11FireworksFear = function(...)
        local Name = "GUIAction_Hero11FireworksFear";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIAction_Hero12PoisonRange"] = GUIAction_Hero12PoisonRange;
    GUIAction_Hero12PoisonRange = function(...)
        local Name = "GUIAction_Hero12PoisonRange";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIAction_Hero12PoisonArrows"] = GUIAction_Hero12PoisonArrows;
    GUIAction_Hero12PoisonArrows = function(...)
        local Name = "GUIAction_Hero12PoisonArrows";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end
end

-- GUI Tooltip --

function UiHacker.Internal:OverrideGuiTooltip()
    self.Data.Originals["GUITooltip_BlessSettlers"] = GUITooltip_BlessSettlers;
    GUITooltip_BlessSettlers = function(...)
        local Name = "GUITooltip_BlessSettlers";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUITooltip_BuySoldier"] = GUITooltip_BuySoldier;
    GUITooltip_BuySoldier = function(...)
        local Name = "GUITooltip_BuySoldier";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUITooltip_ConstructBuilding"] = GUITooltip_ConstructBuilding;
    GUITooltip_ConstructBuilding = function(...)
        local Name = "GUITooltip_ConstructBuilding";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUITooltip_Generic"] = GUITooltip_Generic;
    GUITooltip_Generic = function(...)
        local Name = "GUITooltip_Generic";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUITooltip_NormalButton"] = GUITooltip_NormalButton;
    GUITooltip_NormalButton = function(...)
        local Name = "GUITooltip_NormalButton";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUITooltip_ResearchTechnologies"] = GUITooltip_ResearchTechnologies;
    GUITooltip_ResearchTechnologies = function(...)
        local Name = "GUITooltip_ResearchTechnologies";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUITooltip_UpgradeBuilding"] = GUITooltip_UpgradeBuilding;
    GUITooltip_UpgradeBuilding = function(...)
        local Name = "GUITooltip_UpgradeBuilding";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUITooltip_AOFindHero"] = GUITooltip_AOFindHero;
    GUITooltip_AOFindHero = function(...)
        local Name = "GUITooltip_AOFindHero";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUITooltip_AbilityButton"] = GUITooltip_AbilityButton;
    GUITooltip_AbilityButton = function(...)
        local Name = "GUITooltip_AbilityButton";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUITooltip_BuySerf"] = GUITooltip_BuySerf;
    GUITooltip_BuySerf = function(...)
        local Name = "GUITooltip_BuySerf";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUITooltip_BuyMilitaryUnit"] = GUITooltip_BuyMilitaryUnit;
    GUITooltip_BuyMilitaryUnit = function(...)
        local Name = "GUITooltip_BuyMilitaryUnit";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end
end

-- GUI Update --

function UiHacker.Internal:OverrideGuiUpdate()
    self.Data.Originals["GUIUpdate_BuildingButtons"] = GUIUpdate_BuildingButtons;
    GUIUpdate_BuildingButtons = function(...)
        local Name = "GUIUpdate_BuildingButtons";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIUpdate_BuySoldierButton"] = GUIUpdate_BuySoldierButton;
    GUIUpdate_BuySoldierButton = function(...)
        local Name = "GUIUpdate_BuySoldierButton";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIUpdate_FaithProgress"] = GUIUpdate_FaithProgress;
    GUIUpdate_FaithProgress = function(...)
        local Name = "GUIUpdate_FaithProgress";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIUpdate_FindView"] = GUIUpdate_FindView;
    GUIUpdate_FindView = function(...)
        local Name = "GUIUpdate_FindView";
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

    self.Data.Originals["GUIUpdate_UpgradeButtons"] = GUIUpdate_UpgradeButtons;
    GUIUpdate_UpgradeButtons = function(...)
        local Name = "GUIUpdate_UpgradeButtons";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIUpdate_WeatherForecast"] = GUIUpdate_WeatherForecast;
    GUIUpdate_WeatherForecast = function(...)
        local Name = "GUIUpdate_WeatherForecast";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIUpdate_ToggleWeatherForecast"] = GUIUpdate_ToggleWeatherForecast;
    GUIUpdate_ToggleWeatherForecast = function(...)
        local Name = "GUIUpdate_ToggleWeatherForecast";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIUpdate_IdelSerfAmount"] = GUIUpdate_IdelSerfAmount;
    GUIUpdate_IdelSerfAmount = function(...)
        local Name = "GUIUpdate_IdelSerfAmount";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIUpdate_HeroButton"] = GUIUpdate_HeroButton;
    GUIUpdate_HeroButton = function(...)
        local Name = "GUIUpdate_HeroButton";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIUpdate_PaydayClock"] = GUIUpdate_PaydayClock;
    GUIUpdate_PaydayClock = function(...)
        local Name = "GUIUpdate_PaydayClock";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIUpdate_AverageMotivation"] = GUIUpdate_AverageMotivation;
    GUIUpdate_AverageMotivation = function(...)
        local Name = "GUIUpdate_AverageMotivation";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIUpdate_ResourceAmount"] = GUIUpdate_ResourceAmount;
    GUIUpdate_ResourceAmount = function(...)
        local Name = "GUIUpdate_ResourceAmount";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIUpdate_Population"] = GUIUpdate_Population;
    GUIUpdate_Population = function(...)
        local Name = "GUIUpdate_Population";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIUpdate_TaxPaydayIncome"] = GUIUpdate_TaxPaydayIncome;
    GUIUpdate_TaxPaydayIncome = function(...)
        local Name = "GUIUpdate_TaxPaydayIncome";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIUpdate_SelectionName"] = GUIUpdate_SelectionName;
    GUIUpdate_SelectionName = function(...)
        local Name = "GUIUpdate_SelectionName";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIUpdate_GroupStrength"] = GUIUpdate_GroupStrength;
    GUIUpdate_GroupStrength = function(...)
        local Name = "GUIUpdate_GroupStrength";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIUpdate_AbilityButtons"] = GUIUpdate_AbilityButtons;
    GUIUpdate_AbilityButtons = function(...)
        local Name = "GUIUpdate_AbilityButtons";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIUpdate_HeroAbility"] = GUIUpdate_HeroAbility;
    GUIUpdate_HeroAbility = function(...)
        local Name = "GUIUpdate_HeroAbility";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIUpdate_ThiefSelection"] = GUIUpdate_ThiefSelection;
    GUIUpdate_ThiefSelection = function(...)
        local Name = "GUIUpdate_ThiefSelection";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIUpdate_UpgradeProgress"] = GUIUpdate_UpgradeProgress;
    GUIUpdate_UpgradeProgress = function(...)
        local Name = "GUIUpdate_UpgradeProgress";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIUpdate_CannonProgress"] = GUIUpdate_CannonProgress;
    GUIUpdate_CannonProgress = function(...)
        local Name = "GUIUpdate_CannonProgress";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIUpdate_TechnologyButtons"] = GUIUpdate_TechnologyButtons;
    GUIUpdate_TechnologyButtons = function(...)
        local Name = "GUIUpdate_TechnologyButtons";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIUpdate_BuyHeroButton"] = GUIUpdate_BuyHeroButton;
    GUIUpdate_BuyHeroButton = function(...)
        local Name = "GUIUpdate_BuyHeroButton";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIUpdate_AlarmButton"] = GUIUpdate_AlarmButton;
    GUIUpdate_AlarmButton = function(...)
        local Name = "GUIUpdate_AlarmButton";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIUpdate_FeatureButtons"] = GUIUpdate_FeatureButtons;
    GUIUpdate_FeatureButtons = function(...)
        local Name = "GUIUpdate_FeatureButtons";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIUpdate_TaxWorkerAmount"] = GUIUpdate_TaxWorkerAmount;
    GUIUpdate_TaxWorkerAmount = function(...)
        local Name = "GUIUpdate_TaxWorkerAmount";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIUpdate_TaxTaxAmountOfWorker"] = GUIUpdate_TaxTaxAmountOfWorker;
    GUIUpdate_TaxTaxAmountOfWorker = function(...)
        local Name = "GUIUpdate_TaxTaxAmountOfWorker";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIUpdate_TaxSumOfTaxes"] = GUIUpdate_TaxSumOfTaxes;
    GUIUpdate_TaxSumOfTaxes = function(...)
        local Name = "GUIUpdate_TaxSumOfTaxes";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIUpdate_TaxLeaderCosts"] = GUIUpdate_TaxLeaderCosts;
    GUIUpdate_TaxLeaderCosts = function(...)
        local Name = "GUIUpdate_TaxLeaderCosts";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIUpdate_TaxLeaderAmount"] = GUIUpdate_TaxLeaderAmount;
    GUIUpdate_TaxLeaderAmount = function(...)
        local Name = "GUIUpdate_TaxLeaderAmount";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIUpdate_GlobalTechnologiesButtons"] = GUIUpdate_GlobalTechnologiesButtons;
    GUIUpdate_GlobalTechnologiesButtons = function(...)
        local Name = "GUIUpdate_GlobalTechnologiesButtons";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIUpdate_BuyMilitaryUnitButtons"] = GUIUpdate_BuyMilitaryUnitButtons;
    GUIUpdate_BuyMilitaryUnitButtons = function(...)
        local Name = "GUIUpdate_BuyMilitaryUnitButtons";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIUpdate_SettlersUpgradeButtons"] = GUIUpdate_SettlersUpgradeButtons;
    GUIUpdate_SettlersUpgradeButtons = function(...)
        local Name = "GUIUpdate_SettlersUpgradeButtons";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIUpdate_MarketTradeProgress"] = GUIUpdate_MarketTradeProgress;
    GUIUpdate_MarketTradeProgress = function(...)
        local Name = "GUIUpdate_MarketTradeProgress";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIUpdate_MarketTradeWindow"] = GUIUpdate_MarketTradeWindow;
    GUIUpdate_MarketTradeWindow = function(...)
        local Name = "GUIUpdate_MarketTradeWindow";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIUpdate_CurrentWorkersAmount"] = GUIUpdate_CurrentWorkersAmount;
    GUIUpdate_CurrentWorkersAmount = function(...)
        local Name = "GUIUpdate_CurrentWorkersAmount";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIUpdate_WeatherEnergyProgress"] = GUIUpdate_WeatherEnergyProgress;
    GUIUpdate_WeatherEnergyProgress = function(...)
        local Name = "GUIUpdate_WeatherEnergyProgress";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIUpdate_MerchantOffers"] = GUIUpdate_MerchantOffers;
    GUIUpdate_MerchantOffers = function(...)
        local Name = "GUIUpdate_MerchantOffers";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end

    self.Data.Originals["GUIUpdate_TroopOffer"] = GUIUpdate_TroopOffer;
    GUIUpdate_TroopOffer = function(...)
        local Name = "GUIUpdate_TroopOffer";
        UiHacker.Internal:Execute(Name, XGUIEng.GetCurrentWidgetID(), unpack(arg));
    end
end

