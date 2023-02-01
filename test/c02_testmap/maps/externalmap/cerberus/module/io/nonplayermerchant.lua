Lib.Require("comfort/KeyOf");
Lib.Require("comfort/GetResourceName");
Lib.Require("module/ui/Placeholder");
Lib.Require("module/io/Interaction");
Lib.Register("module/io/NonPlayerMerchant");

--- 
--- NPC merchant script
---
--- Implements an alternative merchant to the vanilla system.
--- 
--- @require Interaction
--- @author totalwarANGEL
--- @version 1.0.0
--- 

NonPlayerMerchant = {}

MerchantOfferTypes = {
    Unit       = 1,
    Technology = 2,
    Custom     = 3,
    Resource   = 4,
};

-- -------------------------------------------------------------------------- --
-- API

--- Creates a new merchant.
---
--- Possible fields for definition:
--- * ScriptName     (Required) ScriptName of NPC
--- * SpawnPoint     (Optional) Spawnpoint for mercenaries
--- * Hero           (Optional) ScriptName of hero who can talk to NPC
--- * WrongHeroMsg   (Optional) Wrong hero message
--- * Player         (Optional) Player that can talk to NPC
--- * WrongPlayerMsg (Optional) Wrong player message
---
--- @param _Data table Merchant definition table
function NonPlayerMerchant.Create(_Data)
    NonPlayerMerchant.Internal:CreateNpc(_Data);
end

--- Deletes an merchant (but not the settler).
--- @param _ScriptName string ScriptName of NPC
function NonPlayerMerchant.Delete(_ScriptName)
    NonPlayerMerchant.Internal:DeleteNpc(_ScriptName);
end

--- Checks if the settler has an active merchant NPC.
--- @param _ScriptName string ScriptName of NPC
--- @return boolean Active NPC is active
function NonPlayerMerchant.IsActive(_ScriptName)
    local Data = Interaction.Internal.Data.IO[_ScriptName];
    return Data and Data.Active == true;
end

--- Activates an existing inactive merchant NPC.
---
--- (The TalkedTo value is reset.)
--- @param _ScriptName string ScriptName of NPC
function NonPlayerMerchant.Activate(_ScriptName)
    Interaction.Internal:Activate(_ScriptName);
end

--- Deactivates an existing active merchant NPC.
--- @param _ScriptName string ScriptName of NPC
function NonPlayerMerchant.Deactivate(_ScriptName)
    Interaction.Internal:Deactivate(_ScriptName);
end

--- Returns the amount of offerts.
--- @param _ScriptName string ScriptName of NPC
--- @return number Amount Amount of offers
function NonPlayerMerchant.GetOfferCount(_ScriptName)
    return NonPlayerMerchant.Internal:GetOfferCount(_ScriptName);
end

--- Returns the amount of offer instances bought from the offer.
--- @param _ScriptName string ScriptName of NPC
--- @param _OfferIdx number Index of offer
--- @return number Amount Amount of purchase
function NonPlayerMerchant.GetTradingVolume(_ScriptName, _OfferIdx)
    return NonPlayerMerchant.Internal:GetTradingVolume(_ScriptName, _OfferIdx);
end

--- Adds a resource offer to the merchant.
--- @param _ScriptName string ScriptName of NPC
--- @param _Good number    Type of resource
--- @param _Amount number  Amount of resource
--- @param _Costs table    Costs of offer
--- @param _Load number    Amount of resource offers
--- @param _Refresh number Time until a wagonload is regenerated
function NonPlayerMerchant.AddResourceOffer(_ScriptName, _Good, _Amount, _Costs, _Load, _Refresh)
    if NonPlayerMerchant.Internal:GetOfferCount(_ScriptName) < 4 then
        NonPlayerMerchant.Internal:AddResourceOffer(_ScriptName, _Good, _Amount, _Costs, _Load, _Refresh);
    end
end

--- Adds a mercenary offer to the merchant.
--- @param _ScriptName string ScriptName of NPC
--- @param _Type number    Type of mercenary
--- @param _Costs table    Costs of offer
--- @param _Amount number  Amount of troops
--- @param _Refresh number Time until a wagonload is regenerated
function NonPlayerMerchant.AddTroopOffer(_ScriptName, _Type, _Costs, _Amount, _Refresh)
    if NonPlayerMerchant.Internal:GetOfferCount(_ScriptName) < 4 then
        NonPlayerMerchant.Internal:AddTroopOffer(_ScriptName, _Type, _Costs, _Amount, _Refresh);
    end
end

--- Adds a technology offer to the merchant.
--- @param _ScriptName string ScriptName of NPC
--- @param _Tech number Technology type
--- @param _Costs table Costs of offer
function NonPlayerMerchant.AddTechnologyOffer(_ScriptName, _Tech, _Costs)
    if NonPlayerMerchant.Internal:GetOfferCount(_ScriptName) < 4 then
        NonPlayerMerchant.Internal:AddTechnologyOffer(_ScriptName, _Tech, _Costs);
    end
end

--- Adds a custom defined offer to the merchant.
--- @param _ScriptName string ScriptName of NPC
--- @param _Action function   Function to call
--- @param _Amount number     Amount of wagonloads
--- @param _Costs table       Costs of offer
--- @param _Icon string       Icon name to display
--- @param _Description table Description (Title and Text are separeted)
--- @param _Refresh number    Time until a wagonload is regenerated
function NonPlayerMerchant.AddCustomOffer(_ScriptName, _Action, _Amount, _Costs, _Icon, _Description, _Refresh)
    if NonPlayerMerchant.Internal:GetOfferCount(_ScriptName) < 4 then
        NonPlayerMerchant.Internal:AddCustomOffer(_ScriptName, _Action, _Amount, _Costs, _Icon, _Description, _Refresh);
    end
end

--- Deletes an offer from the merchant.
--- @param _ScriptName string ScriptName of NPC
--- @param _Index number      Index of offer
function NonPlayerMerchant.RemoveOffer(_ScriptName, _Index)
    NonPlayerMerchant.Internal:RemoveOffer(_ScriptName, _Index);
end

-- -------------------------------------------------------------------------- --
-- Internal

NonPlayerMerchant.Internal = {
    Event = {},
};

function NonPlayerMerchant.Internal:Install()
    Placeholder.Install();
    Interaction.Internal:Install();

    if not self.IsInstalled then
        self.IsInstalled = true;

        self:OverrideNpcInteractionCallbacks();
        self:OverrideNpcMerchantGui();
        self:CreateNpcMerchantSyncEvents();
    end
end

function NonPlayerMerchant.Internal:CreateNpc(_Data)
    self:Install();
    Interaction.Internal:CreateNpc(_Data);

    local Data = Interaction.Internal.Data.IO[_Data.ScriptName];
    Data.IsMerchant = true;
    Data.Waypoints  = _Data.Waypoints or {};
    Data.Wanderer   = _Data.StrayPoints or {};
    Data.Waittime   = _Data.Waittime or 0;
    Data.SpawnPoint = _Data.SpawnPoint;
    Data.Offers     = {};

    Logic.AddMercenaryOffer(
        GetID(_Data.ScriptName),
        Entities.CU_Barbarian_LeaderClub1,
        1,
        ResourceType.Gold,
        1
    );

    Interaction.Internal.Data.IO[_Data.ScriptName] = Data;
end

function NonPlayerMerchant.Internal:DeleteNpc(_ScriptName)
    Interaction.Internal:DeleteNpc(_ScriptName);
end

function NonPlayerMerchant.Internal:OnNpcActivated(_ScriptName)
end

function NonPlayerMerchant.Internal:OnNpcDeactivated(_ScriptName)
    GUIAction_MerchantReady();
end

function NonPlayerMerchant.Internal:OverrideNpcMerchantGui()
    self.Orig_GUIUpdate_MerchantOffers = GUIUpdate_MerchantOffers;
    GUIUpdate_MerchantOffers = function(_WidgetTable)
        local PlayerID = GUI.GetPlayerID();
        local EntityID = GetID(Interaction.Npc(PlayerID));
        local MerchantID = Logic.GetMerchantBuildingId(EntityID);
        local ScriptName = Logic.GetEntityName(MerchantID);
        if MerchantID == 0 then
            ScriptName = Logic.GetEntityName(EntityID);
        end

        local Data = Interaction.Internal.Data.IO[ScriptName];
        if Data then
            NonPlayerMerchant.Internal:UpdateOfferWidgets(ScriptName);
        else
            NonPlayerMerchant.Internal.Orig_GUIUpdate_MerchantOffers(_WidgetTable);
        end
    end

    self.Orig_GUIUpdate_TroopOffer = GUIUpdate_TroopOffer;
    GUIUpdate_TroopOffer = function(_SlotIndex)
        local PlayerID = GUI.GetPlayerID();
        local EntityID = GetID(Interaction.Npc(PlayerID));
        local MerchantID = Logic.GetMerchantBuildingId(EntityID);
        local ScriptName = Logic.GetEntityName(MerchantID);
        if MerchantID == 0 then
            ScriptName = Logic.GetEntityName(EntityID);
        end

        local Data = Interaction.Internal.Data.IO[ScriptName];
        if Data then
            if Data.Active then
                NonPlayerMerchant.Internal:UpdateOffer(ScriptName, _SlotIndex)
            end
        else
            NonPlayerMerchant.Internal.Orig_GUIUpdate_TroopOffer(_SlotIndex);
        end
    end

    self.Orig_GUIAction_BuyMerchantOffer = GUIAction_BuyMerchantOffer;
    GUIAction_BuyMerchantOffer = function(_SlotIndex)
        local PlayerID = GUI.GetPlayerID();
        local EntityID = GetID(Interaction.Npc(PlayerID));
        local MerchantID = Logic.GetMerchantBuildingId(EntityID);
        local ScriptName = Logic.GetEntityName(MerchantID);
        if MerchantID == 0 then
            ScriptName = Logic.GetEntityName(EntityID);
        end

        local Data = Interaction.Internal.Data.IO[ScriptName];
        if Data then
            if Data.Active then
                NonPlayerMerchant.Internal:BuyOffer(ScriptName, _SlotIndex);
            end
        else
            NonPlayerMerchant.Internal.Orig_GUIAction_BuyMerchantOffer(_SlotIndex);
        end
    end

    self.Orig_GUITooltip_TroopOffer = GUITooltip_TroopOffer;
    GUITooltip_TroopOffer = function(_SlotIndex)
        local PlayerID = GUI.GetPlayerID();
        local EntityID = GetID(Interaction.Npc(PlayerID));
        local MerchantID = Logic.GetMerchantBuildingId(EntityID);
        local ScriptName = Logic.GetEntityName(MerchantID);
        if MerchantID == 0 then
            ScriptName = Logic.GetEntityName(EntityID);
        end

        local Data = Interaction.Internal.Data.IO[ScriptName];
        if Data then
            if Data.Active then
                NonPlayerMerchant.Internal:TooltipOffer(ScriptName, _SlotIndex);
            end
        else
            NonPlayerMerchant.Internal.Orig_GUITooltip_TroopOffer(_SlotIndex);
        end
    end
end

function NonPlayerMerchant.Internal:OverrideNpcInteractionCallbacks()
    self.Orig_GameCallback_Logic_InteractWithMerchant = GameCallback_Logic_InteractWithMerchant;
    GameCallback_Logic_InteractWithMerchant = function(_PlayerID, _HeroID, _NpcID)
        NonPlayerMerchant.Internal.Orig_GameCallback_Logic_InteractWithMerchant(_PlayerID, _HeroID, _NpcID);
        local HeroScriptName = Interaction.Hero(_PlayerID);
        local NpcScriptName = Interaction.Npc(_PlayerID);
        NonPlayerMerchant.Internal:OnNpcInteraction(NpcScriptName, HeroScriptName);
    end

    self.Orig_GameCallback_Logic_OnTickNpcController = GameCallback_Logic_OnTickNpcController;
    GameCallback_Logic_OnTickNpcController = function(_ScriptName)
        NonPlayerMerchant.Internal.Orig_GameCallback_Logic_OnTickNpcController(_ScriptName);
        NonPlayerMerchant.Internal:OnTickNpcController(_ScriptName);
    end

    self.Orig_GameCallback_Logic_OnNpcActivated = GameCallback_Logic_OnNpcActivated;
    GameCallback_Logic_OnNpcActivated = function(_ScriptName)
        NonPlayerMerchant.Internal.Orig_GameCallback_Logic_OnNpcActivated(_ScriptName);
        NonPlayerMerchant.Internal:OnNpcActivated(_ScriptName);
    end

    self.Orig_GameCallback_Logic_OnNpcDeactivated = GameCallback_Logic_OnNpcDeactivated;
    GameCallback_Logic_OnNpcDeactivated = function(_ScriptName)
        NonPlayerMerchant.Internal.Orig_GameCallback_Logic_OnNpcDeactivated(_ScriptName);
        NonPlayerMerchant.Internal:OnNpcDeactivated(_ScriptName);
    end
end

function NonPlayerMerchant.Internal:OnTickNpcController(_NpcScriptName)
    local Data = Interaction.Internal.Data.IO[_NpcScriptName];
    if Data.Active == true and Data.IsMerchant then
        for k, v in pairs(Data.Offers) do
            if v and v.Refresh > -1 then
                Data.Offers[k].LastRefresh = v.LastRefresh or Logic.GetTime();
                if Logic.GetTime() > v.LastRefresh + v.Refresh then
                    -- Update load
                    if Data.Offers[k].Load < Data.Offers[k].LoadMax then
                        Data.Offers[k].Load = v.Load +1;
                    end
                    -- Update inflation
                    Data.Offers[k].Inflation = Data.Offers[k].Inflation - 0.05;
                    if Data.Offers[k].Inflation < 0.75 then
                        Data.Offers[k].Inflation = 0.75;
                    end
                    -- Delete refresh time
                    Data.Offers[k].LastRefresh = nil;
                end
            end
        end
    end
end

function NonPlayerMerchant.Internal:GetTradingVolume(_ScriptName, _SlotIndex)
    if Interaction.Internal.Data.IO[_ScriptName] then
        if Interaction.Internal.Data.IO[_ScriptName].Offers[_SlotIndex] then
            return Interaction.Internal.Data.IO[_ScriptName].Offers[_SlotIndex].Volume;
        end
    end
    return 0;
end

function NonPlayerMerchant.Internal:GetOfferCount(_ScriptName)
    if Interaction.Internal.Data.IO[_ScriptName] then
        return table.getn(Interaction.Internal.Data.IO[_ScriptName].Offers);
    end
    return 0;
end

function NonPlayerMerchant.Internal:CreateCostTable(_Costs)
    local CostsTable = {
        [ResourceType.Gold]   = _Costs.Gold or 0,
        [ResourceType.Clay]   = _Costs.Clay or 0,
        [ResourceType.Wood]   = _Costs.Wood or 0,
        [ResourceType.Stone]  = _Costs.Stone or 0,
        [ResourceType.Iron]   = _Costs.Iron or 0,
        [ResourceType.Sulfur] = _Costs.Sulfur or 0,
        [ResourceType.Silver] = 0,
    };
    return CostsTable;
end

-- Events --

function NonPlayerMerchant.Internal:CreateNpcMerchantSyncEvents()
    -- Buy Units
    self.Event.BuyUnit = Syncer.CreateEvent(function(_PlayerID, _ScriptName, _EntityType, _X, _Y, _SlotIndex)
        local Data = Interaction.Internal.Data.IO[_ScriptName];
        if Data then
            local ID = AI.Entity_CreateFormation(_PlayerID, _EntityType, 0, 0, _X, _Y, 0, 0, 3, 0);
            if Logic.IsLeader(ID) == 1 then
                Tools.CreateSoldiersForLeader(ID, 16);
            end
            NonPlayerMerchant.Internal:SubResources(_ScriptName, _PlayerID, _SlotIndex);
            NonPlayerMerchant.Internal:UpdateValues(_ScriptName, _SlotIndex);
        end
    end);
    -- Buy Resources
    self.Event.BuyRes = Syncer.CreateEvent(function(_PlayerID, _ScriptName, _GoodType, _Amount, _SlotIndex)
        local Data = Interaction.Internal.Data.IO[_ScriptName];
        if Data then
            Logic.AddToPlayersGlobalResource(_PlayerID, _GoodType, _Amount);
            NonPlayerMerchant.Internal:SubResources(_ScriptName, _PlayerID, _SlotIndex);
            NonPlayerMerchant.Internal:UpdateValues(_ScriptName, _SlotIndex);
        end
    end);
    -- Buy Technology
    self.Event.BuyTech = Syncer.CreateEvent(function(_PlayerID, _ScriptName, _TechType, _SlotIndex)
        local Data = Interaction.Internal.Data.IO[_ScriptName];
        if Data then
            ResearchTechnology(_TechType, _PlayerID);
            NonPlayerMerchant.Internal:SubResources(_ScriptName, _PlayerID, _SlotIndex);
            NonPlayerMerchant.Internal:UpdateValues(_ScriptName, _SlotIndex);
        end
    end);
    -- Buy Custom
    self.Event.BuyFunc = Syncer.CreateEvent(function(_PlayerID, _ScriptName, _SlotIndex)
        local Data = Interaction.Internal.Data.IO[_ScriptName];
        if Data then
            Data.Offers[_SlotIndex].Good(
                Data.Offers[_SlotIndex],
                Data,
                _PlayerID
            );
            NonPlayerMerchant.Internal:SubResources(_ScriptName, _PlayerID, _SlotIndex);
            NonPlayerMerchant.Internal:UpdateValues(_ScriptName, _SlotIndex);
        end
    end);
end

-- Offers --

function NonPlayerMerchant.Internal:AddOffer(_Type, _ScriptName, _Costs, _Amount, _Good, _Load, _Icon, _Refresh, _Description)
    if Interaction.Internal.Data.IO[_ScriptName] then
        local CostsTable = self:CreateCostTable(_Costs);

        local Length = table.getn(Interaction.Internal.Data.IO[_ScriptName].Offers);
        if Length < 4 then
            Interaction.Internal.Data.IO[_ScriptName].Offers[Length+1] = {
                Type = _Type,
                Costs = CostsTable,
                Amount = _Amount,
                Good = _Good,
                Load = _Load,
                LoadMax = _Load,
                Icon = _Icon,
                Refresh = _Refresh or -1,
                Inflation = 1.0,
                Volume = 0,
                Description = _Description
            };
        end
    end
end

function NonPlayerMerchant.Internal:AddTroopOffer(_ScriptName, _Good, _Costs, _Amount, _Refresh)
    -- Get icon
    local Icon = "Buy_LeaderSword";
    if Logic.IsEntityTypeInCategory(_Good, EntityCategories.Bow) == 1 then
		Icon = "Buy_LeaderBow";
	elseif Logic.IsEntityTypeInCategory(_Good, EntityCategories.Spear)== 1 then
		Icon = "Buy_LeaderSpear";
	elseif Logic.IsEntityTypeInCategory(_Good, EntityCategories.CavalryHeavy)== 1 then
		Icon = "Buy_LeaderCavalryHeavy";
	elseif Logic.IsEntityTypeInCategory(_Good, EntityCategories.CavalryLight) == 1 then
		Icon = "Buy_LeaderCavalryLight";
	elseif Logic.IsEntityTypeInCategory(_Good, EntityCategories.Rifle) == 1 then
		Icon = "Buy_LeaderRifle";
	elseif _Good == Entities.PV_Cannon1 then
		Icon = "Buy_Cannon1";
	elseif _Good == Entities.PV_Cannon2 then
		Icon = "Buy_Cannon2";
	elseif _Good == Entities.PV_Cannon3 then
		Icon = "Buy_Cannon3";
	elseif _Good == Entities.PV_Cannon4 then
		Icon = "Buy_Cannon4";
	elseif _Good == Entities.PU_Serf then
		Icon = "Buy_Serf";
	elseif _Good == Entities.PU_Thief then
		Icon = "Buy_Thief";
	elseif _Good == Entities.PU_Scout then
        Icon = "Buy_Scout";
    end
    -- Add offer
    self:AddOffer(MerchantOfferTypes.Unit, _ScriptName, _Costs, 0, _Good, _Amount, Icon, _Refresh or -1);
end

function NonPlayerMerchant.Internal:AddResourceOffer(_ScriptName, _Good, _Amount, _Costs, _Load, _Refresh)
    -- Get icon
    local Icon = "Statistics_SubResources_Money";
    if _Good == ResourceType.Clay or _Good == ResourceType.ClayRaw then
        Icon = "Statistics_SubResources_Clay";
    elseif _Good == ResourceType.Wood or _Good == ResourceType.WoodRaw then
        Icon = "Statistics_SubResources_Wood";
    elseif _Good == ResourceType.Stone or _Good == ResourceType.StoneRaw then
        Icon = "Statistics_SubResources_Stone";
    elseif _Good == ResourceType.Iron or _Good == ResourceType.IronRaw then
        Icon = "Statistics_SubResources_Iron";
    elseif _Good == ResourceType.Sulfur or _Good == ResourceType.SulfurRaw then
        Icon = "Statistics_SubResources_Sulphur";
    end
    -- Add offer
    self:AddOffer(MerchantOfferTypes.Resource, _ScriptName, _Costs, _Amount, _Good, _Load, Icon, _Refresh or -1);
end

function NonPlayerMerchant.Internal:AddTechnologyOffer(_ScriptName, _Good, _Costs)
    -- Get icon
    local Icon;
    for k, v in pairs(Technologies) do
        if v == _Good then
            if string.find(k, "GT_") then
                Icon = "Research_" .. string.sub(k, 4, string.len(k));
            elseif string.find(k, "T_") then
                Icon = "Research_" .. string.sub(k, 3, string.len(k));
            elseif string.find(k, "B_") then
                Icon = "Build_" .. string.sub(k, 3, string.len(k));
            else
                Icon = "Research_Literacy";
            end
        end
    end
    -- Add offer
    self:AddOffer(MerchantOfferTypes.Technology, _ScriptName, _Costs, 0, _Good, 1, Icon, -1);
end

function NonPlayerMerchant.Internal:AddCustomOffer(_ScriptName, _Action, _Amount, _Costs, _Icon, _Description, _Refresh)
    self:AddOffer(MerchantOfferTypes.Custom, _ScriptName, _Costs, 0, _Action, _Amount, _Icon, _Refresh or -1, _Description);
end

function NonPlayerMerchant.Internal:RemoveOffer(_ScriptName, _Index)
    if Interaction.Internal.Data.IO[_ScriptName] then
        if table.getn(Interaction.Internal.Data.IO[_ScriptName].Offers) >= _Index then
            table.remove(Interaction.Internal.Data.IO[_ScriptName].Offers, _Index);
        end
    end
end

-- Interaction --

function NonPlayerMerchant.Internal:OnNpcInteraction(_NpcScriptName, _HeroScriptName)
    local HeroID = GetID(_HeroScriptName);
    local CurrentPlayerID = GUI.GetPlayerID();
    local PlayerIDOfHero = Logic.EntityGetPlayer(HeroID);
    if PlayerIDOfHero == CurrentPlayerID then
        GUI.SelectEntity(HeroID);
        XGUIEng.ShowAllSubWidgets(gvGUI_WidgetID.SelectionView, 0);
        XGUIEng.ShowWidget(gvGUI_WidgetID.SelectionGeneric, 1);
        XGUIEng.ShowWidget(gvGUI_WidgetID.BackgroundFull, 1);
        XGUIEng.ShowAllSubWidgets(gvGUI_WidgetID.SelectionBuilding, 0);
        XGUIEng.ShowWidget(gvGUI_WidgetID.SelectionBuilding, 1);
        XGUIEng.ShowWidget(gvGUI_WidgetID.TroopMerchant, 1);
        self:UpdateOfferWidgets(_NpcScriptName);
    end
end

function NonPlayerMerchant.Internal:UpdateOfferWidgets(_NpcScriptName)
    local Data = Interaction.Internal.Data.IO[_NpcScriptName];
    XGUIEng.ShowAllSubWidgets("TroopMerchantOffersContainer", 0);
    for i= 1, 4, 1 do
        local Visible = (Data.Offers[i] ~= nil and 1) or 0;
        XGUIEng.ShowWidget("BuyTroopOfferContainer" ..i, Visible);
        XGUIEng.ShowWidget("Amount_TroopOffer" ..i, Visible);
        XGUIEng.ShowWidget("Buy_TroopOffer" ..i, Visible);
    end
end

function NonPlayerMerchant.Internal:UpdateOffer(_NpcScriptName, _SlotIndex)
    local Data = Interaction.Internal.Data.IO[_NpcScriptName];
    local CurrentWidgetID = XGUIEng.GetCurrentWidgetID();
    local PlayerID = GUI.GetPlayerID();
    local EntityID = GUI.GetSelectedEntity();
    if not IsExisting(EntityID) or string.find(Logic.GetCurrentTaskList(EntityID), "WALK") then
        GUIAction_MerchantReady();
        return;
    end

    -- Set icon
    local SourceButton = Data.Offers[_SlotIndex].Icon;
    XGUIEng.TransferMaterials(SourceButton, CurrentWidgetID);
    XGUIEng.HighLightButton(CurrentWidgetID, 0);

    -- Prevent buying already researched technologies
    if Data.Offers[_SlotIndex].Type == MerchantOfferTypes.Technology then
        if Logic.IsTechnologyResearched(PlayerID, Data.Offers[_SlotIndex].Good) == 1 then
            XGUIEng.HighLightButton(CurrentWidgetID, 1);
        end
        XGUIEng.SetText(gvGUI_WidgetID.TroopMerchantOfferAmount[_SlotIndex], "");
        return;
    end

    -- Set amount and disable sold out offers
    -- FIX: Highlight because disable doesn't work
    local Amount = Data.Offers[_SlotIndex].Load;
    if Amount < 1 then
        Amount = "";
        XGUIEng.HighLightButton(CurrentWidgetID, 1);
    else
        XGUIEng.HighLightButton(CurrentWidgetID, 0);
    end
    XGUIEng.SetText(gvGUI_WidgetID.TroopMerchantOfferAmount[_SlotIndex], "@center " ..Amount);
end

function NonPlayerMerchant.Internal:BuyOffer(_NpcScriptName, _SlotIndex)
    local Data = Interaction.Internal.Data.IO[_NpcScriptName];
    if Data.Offers[_SlotIndex].Load < 1 then
        return;
    end
    local Costs = CopyTable(Data.Offers[_SlotIndex].Costs);
    for k, v in pairs(Costs) do
        Costs[k] = math.ceil(v * Data.Offers[_SlotIndex].Inflation);
    end

    if InterfaceTool_HasPlayerEnoughResources_Feedback(Costs) == 1 then
        local PlayerID = GUI.GetPlayerID();
        if Data.Offers[_SlotIndex].Type == MerchantOfferTypes.Unit then
            if Logic.GetPlayerAttractionUsage(PlayerID) >= Logic.GetPlayerAttractionLimit(PlayerID) then
                GUI.SendPopulationLimitReachedFeedbackEvent(PlayerID);
                return;
            end
        end

        -- Mercenary
        if Data.Offers[_SlotIndex].Type == MerchantOfferTypes.Unit then
            local Position
            if Data.SpawnPoint then
                Position = GetPosition(Data.SpawnPoint);
            else
                Position = GetPosition(Data.ScriptName);
            end
            Syncer.InvokeEvent(
                NonPlayerMerchant.Internal.Event.BuyUnit,
                _NpcScriptName,
                Data.Offers[_SlotIndex].Good,
                Position.X,
                Position.Y,
                _SlotIndex
            );

        -- Resource
        elseif Data.Offers[_SlotIndex].Type == MerchantOfferTypes.Resource then
            Syncer.InvokeEvent(
                NonPlayerMerchant.Internal.Event.BuyRes,
                _NpcScriptName,
                Data.Offers[_SlotIndex].Good +1,
                Data.Offers[_SlotIndex].Amount,
                _SlotIndex
            );

        -- Technology
        elseif Data.Offers[_SlotIndex].Type == MerchantOfferTypes.Technology then
            if Logic.IsTechnologyResearched(PlayerID, Data.Offers[_SlotIndex].Good) == 1 then
                return;
            end
            Syncer.InvokeEvent(
                NonPlayerMerchant.Internal.Event.BuyTech,
                _NpcScriptName,
                Data.Offers[_SlotIndex].Good,
                _SlotIndex
            );

        -- Custom
        else
            Syncer.InvokeEvent(
                NonPlayerMerchant.Internal.Event.BuyFunc,
                _NpcScriptName,
                _SlotIndex
            );
        end
        GUIUpdate_TroopOffer(_SlotIndex);
    end
end

function NonPlayerMerchant.Internal:SubResources(_NpcScriptName, _PlayerID, _SlotIndex)
    local Data = Interaction.Internal.Data.IO[_NpcScriptName];
    local Costs = CopyTable(Data.Offers[_SlotIndex].Costs);
    for k, v in pairs(Costs) do
        Costs[k] = math.ceil(v * Data.Offers[_SlotIndex].Inflation);
    end
    for k, v in pairs(Costs) do
        Logic.SubFromPlayersGlobalResource(_PlayerID, k, v);
    end
end

function NonPlayerMerchant.Internal:UpdateValues(_NpcScriptName, _SlotIndex)
    local Data = Interaction.Internal.Data.IO[_NpcScriptName];
    Data.Offers[_SlotIndex].Volume = Data.Offers[_SlotIndex].Volume +1;
    Data.Offers[_SlotIndex].Load = Data.Offers[_SlotIndex].Load -1;
    Data.Offers[_SlotIndex].Inflation = Data.Offers[_SlotIndex].Inflation + 0.05;
    if Data.Offers[_SlotIndex].Inflation > 1.75 then
        Data.Offers[_SlotIndex].Inflation = 1.75;
    end
end

function NonPlayerMerchant.Internal:TooltipOffer(_NpcScriptName, _SlotIndex)
    local Data = Interaction.Internal.Data.IO[_NpcScriptName];
    local Costs = CopyTable(Data.Offers[_SlotIndex].Costs);
    for k, v in pairs(Costs) do
        Costs[k] = math.ceil(v * Data.Offers[_SlotIndex].Inflation);
    end

    local CostString = InterfaceTool_CreateCostString(Costs);
    local Language = GetLanguage();
    local Description;

    -- Mercenary
    if Data.Offers[_SlotIndex].Type == MerchantOfferTypes.Unit then
        local EntityTypeName = Logic.GetEntityTypeName(Data.Offers[_SlotIndex].Good);
        if EntityTypeName == nil then
            return;
        end
        local NameString = "names/" .. EntityTypeName
        Description = "{grey}" .. XGUIEng.GetStringTableText(NameString) .. "{nl}";
        local Text = XGUIEng.GetStringTableText("MenuMerchant/TroopOfferTooltipText");
        if Data.Offers[_SlotIndex].Load == 0 then
            CostString = "";
            Text = "{white}Dieses Angebot ist ausverkauft!";
            if Language ~= "de" then
                Text = "{white}This offer is sold out.";
            end
        end
        Description = Description .. Text;

    -- Resource
    elseif Data.Offers[_SlotIndex].Type == MerchantOfferTypes.Resource then
        local GoodName = GetResourceName(Data.Offers[_SlotIndex].Good);
        local Title = GoodName.. " kaufen";
        if Language ~= "de" then
            Title = "Buy " ..GoodName;
        end
        local Text;
        if Data.Offers[_SlotIndex].Load == 0 then
            CostString = "";
            Text = "{white}Dieses Angebot ist ausverkauft!";
            if Language ~= "de" then
                Text = "{white}This offer is sold out.";
            end
        else
            Text = "{white}Kauft " ..Data.Offers[_SlotIndex].Amount.. " Einheiten dieses Rohstoffes.";
            if Language ~= "de" then
                Title = "{white}Buy " ..Data.Offers[_SlotIndex].Amount.. " of this resource.";
            end
        end
        Description = "{grey}" .. Title .. "{nl}{white}" ..Text;

    -- Technology
    elseif Data.Offers[_SlotIndex].Type == MerchantOfferTypes.Technology then
        local PlayerID = GUI.GetPlayerID();
        local TechnologyKey = KeyOf(Data.Offers[_SlotIndex].Good, Technologies);
        if TechnologyKey == nil then
            return;
        end
        local Title = XGUIEng.GetStringTableText("names/" ..TechnologyKey);
        local Text = "{white}Eignet Euch das Wissen über diese Technologie an.";
        if Language ~= "de" then
            Title = "{white}Get the knowledge about this technology.";
        end
        if Logic.IsTechnologyResearched(PlayerID, Data.Offers[_SlotIndex].Good) == 1 then
            CostString = "";
            Text = "{white}Ihr habt diese Technologie bereits erforscht, Milord!";
            if Language ~= "de" then
                Title = "{white}You have already researched this technology, your majesty!";
            end
        end
        Description = "{grey}" .. Title .. "{nl}{white}" ..Text;

    -- Custom
    else
        local Title = Data.Offers[_SlotIndex].Description.Title;
        if type(Title) == "table" then
            Title = Title[Language];
        end
        local Text  = Data.Offers[_SlotIndex].Description.Text;
        if type(Text) == "table" then
            Text = Text[Language];
        end
        if Data.Offers[_SlotIndex].Load == 0 then
            CostString = "";
            Text = "{white}Dieses Angebot ist ausverkauft!";
            if Language ~= "de" then
                Text = "{white}This offer is sold out.";
            end
        end
        Description = "{grey}" .. Title .. "{nl}{white}" ..Text;
    end

    XGUIEng.SetText(gvGUI_WidgetID.TooltipBottomText, Placeholder.Replace(Description));
    XGUIEng.SetText(gvGUI_WidgetID.TooltipBottomCosts, Placeholder.Replace(CostString));
    XGUIEng.SetText(gvGUI_WidgetID.TooltipBottomShortCut, "");
end

