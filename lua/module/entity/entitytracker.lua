Lib.Require("comfort/GetMaxAmountOfPlayer");
Lib.Require("comfort/GetPlayerEntities");
Lib.Require("comfort/GetUpgradeCategoryByEntityType");
Lib.Require("comfort/GetUpgradeLevelByEntityType");
Lib.Require("comfort/GetUpgradedEntityType");
Lib.Require("module/mp/Syncer");
Lib.Register("module/entity/EntityTracker");

---
--- Entity Limitaions
--- 
--- Any entity type can be tracked whit this. The script only tracks the types
--- configured in the limits table. Changes in the UI aka disableing buttons
--- ect. must be done by the user.
--- 
--- GameCallback_GUI_SelectionChanged is called by code if an configured type
--- is created/destroyed or an building upgrade is started/canceled.
--- 
--- Version 1.3.2
---

EntityTracker = EntityTracker or {};

-- -------------------------------------------------------------------------- --
-- API

--- Installs the tracker.
--- (Must be called on game start!)
function EntityTracker.Install()
    EntityTracker.Internal:Install();
end

--- Returns the limit for the type.
---  * -1   No limit
---  *  0   Forbidden
---  * >0   Limit
--- 
--- @param _Type number Entity type
--- @param _PlayerID number? ID of player
--- @return number Limit Current limit for type
function EntityTracker.GetLimitOfType(_Type, _PlayerID)
    return EntityTracker.Internal:GetLimitForType(_PlayerID, _Type);
end

--- Sets a limit for the type.
---  * -1   No limit
---  *  0   Forbidden
---  * >0   Limit
--- 
--- @param _Type number Entity type
--- @param _Limit number Limit for type
--- @param _PlayerID number? ID of player
function EntityTracker.SetLimitOfType(_Type, _Limit, _PlayerID)
    _PlayerID = _PlayerID or -1;
    return EntityTracker.Internal:SetLimitForType(_PlayerID, _Type, _Limit);
end

--- Returns the amount of tracked entities of the player.
---
--- If `_Upgrades` is used, all upgrades of the type will also be considered.
---
--- @param _Type number Entity type
--- @param _PlayerID number ID of player
--- @param _Upgrades? boolean With upgrades
--- @return number amount of entities
function EntityTracker.GetUsageOfType(_Type, _PlayerID, _Upgrades)
    return EntityTracker.Internal:GetCurrentAmountOfType(_PlayerID, _Type, _Upgrades);
end

--- Returns if the limit of the entity type has been reached.
---
--- If `_Upgrades` is used, all upgrades of the type will also be considered.
---
--- @param _Type number Entity type
--- @param _PlayerID number ID of player
--- @param _Upgrades? boolean With upgrades
--- @return boolean Exceeded The maximum has been reached
function EntityTracker.IsLimitOfTypeReached(_Type, _PlayerID, _Upgrades)
    local Limit = EntityTracker.Internal:GetLimitForType(_PlayerID, _Type);
    if Limit > -1 then
        local Amount = EntityTracker.Internal:GetCurrentAmountOfType(_PlayerID, _Type, _Upgrades);
        return Amount >= Limit;
    end
    return false;
end

--- Returns if the limit of the entity type has been exceeded.
---
--- If `_Upgrades` is used, all upgrades of the type will also be considered.
---
--- @param _Type number Entity type
--- @param _PlayerID number ID of player
--- @param _Upgrades? boolean With upgrades
--- @return boolean Exceeded The maximum has been surpassed
function EntityTracker.IsLimitOfTypeExceeded(_Type, _PlayerID, _Upgrades)
    local Limit = EntityTracker.Internal:GetLimitForType(_PlayerID, _Type);
    if Limit > -1 then
        local Amount = EntityTracker.Internal:GetCurrentAmountOfType(_PlayerID, _Type, _Upgrades);
        return Amount > Limit;
    end
    return false;
end

-- -------------------------------------------------------------------------- --
-- Internal

EntityTracker.Internal = EntityTracker.Internal or {
    Data = {},
    Config = {},
};

function EntityTracker.Internal:Install()
    Syncer.Install();

    if not self.IsInstalled then
        self.IsInstalled = true;

        for i= 1, GetMaxAmountOfPlayer() do
            self.Config[i] = {
                Limit = {},
            };
            self.Data[i] = {
                Potential = {},
                Current = {},
            };
        end
        self:SetupSynchronization();
        self:FindInitialPlayerEntities();
        self:OverrideUpgradeBuilding();
        self:StartTriggers();
    end
end

function EntityTracker.Internal:SetupSynchronization()
    self.SyncEvent = {
        UpgradeStarted = 1,
        UpgradeCanceled = 2,
    };

    self.NetworkCall = Syncer.CreateEvent(
        function(_PlayerID, _Action, ...)
            if _Action == EntityTracker.Internal.SyncEvent.UpgradeStarted then
                EntityTracker.Internal:OnUpgradeStarted(_PlayerID, arg[1]);
            end
            if _Action == EntityTracker.Internal.SyncEvent.UpgradeCanceled then
                EntityTracker.Internal:OnUpgradeCanceled(_PlayerID, arg[1]);
            end
        end
    );
end

function EntityTracker.Internal:GetLimitForType(_PlayerID, _Type)
    return self.Config[_PlayerID].Limit[_Type] or -1
end

function EntityTracker.Internal:SetLimitForType(_PlayerID, _Type, _Limit)
    if _PlayerID == -1 then
        for i= 1, GetMaxAmountOfPlayer() do
            self:SetLimitForType(i, _Type, _Limit);
        end
    else
        self.Config[_PlayerID].Limit[_Type] = _Limit
    end
end

function EntityTracker.Internal:GetCurrentAmountOfType(_PlayerID, _Type, _Upgrades)
    local Amount = 0;
    if _Upgrades == true then
        local UpgradedEntity = GetUpgradedEntityType(_Type);
        if UpgradedEntity > 0 then
            Amount = self:GetCurrentAmountOfType(_PlayerID, UpgradedEntity, _Upgrades);
        end
    end
    if self.Data[_PlayerID].Potential[_Type] then
        Amount = Amount + table.getn(self.Data[_PlayerID].Potential[_Type]);
    end
    if self.Data[_PlayerID].Current[_Type] then
        Amount = Amount + table.getn(self.Data[_PlayerID].Current[_Type]);
    end
    return Amount;
end

function EntityTracker.Internal:FindInitialPlayerEntities()
    for PlayerID,_ in pairs(self.Config) do
        local PlayerEntities = GetPlayerEntities(PlayerID, 0);
        for _,EntityID in pairs(PlayerEntities) do
            self:OnEntityCreated(PlayerID, EntityID);
        end
    end
end

function EntityTracker.Internal:OnEntityCreated(_PlayerID, _EntityID)
    if self.Data[_PlayerID] then
        local Type = Logic.GetEntityType(_EntityID);
        self:AddToList("Current", Type, _PlayerID, _EntityID);
        self:UpdateSelectionBuildingUpgradeButtons(_PlayerID, _EntityID);
        self:UpdateSelectionSerfConstrucButtons(_PlayerID);
    end
end

function EntityTracker.Internal:OnEntityDestroyed(_PlayerID, _EntityID)
    if self.Data[_PlayerID] then
        local Type = Logic.GetEntityType(_EntityID);
        local NextType = GetUpgradedEntityType(Type);
        if NextType > 0 then
            self:RemoveFromList("Potential", NextType, _PlayerID, _EntityID);
        end
        self:RemoveFromList("Potential", Type, _PlayerID, _EntityID);
        self:RemoveFromList("Current", Type, _PlayerID, _EntityID);
        self:UpdateSelectionBuildingUpgradeButtons(_PlayerID, _EntityID);
        self:UpdateSelectionSerfConstrucButtons(_PlayerID);
    end
end

function EntityTracker.Internal:OnUpgradeStarted(_PlayerID, _EntityID)
    if self.Data[_PlayerID] then
        local Type = Logic.GetEntityType(_EntityID);
        self.Data[_PlayerID].UpgradeBuildingLock = false;
        local NextType = GetUpgradedEntityType(Type);
        if NextType > 0 then
            self:AddToList("Potential", NextType, _PlayerID, _EntityID);
        end
        self:RemoveFromList("Current", Type, _PlayerID, _EntityID);
    end
end

function EntityTracker.Internal:OnUpgradeCanceled(_PlayerID, _EntityID)
    if self.Data[_PlayerID] then
        local Type = Logic.GetEntityType(_EntityID);
        local NextType = GetUpgradedEntityType(Type);
        if NextType > 0 then
            self:RemoveFromList("Potential", NextType, _PlayerID, _EntityID);
        end
        self:AddToList("Current", Type, _PlayerID, _EntityID);
        self:UpdateSelectionBuildingUpgradeButtons(_PlayerID, _EntityID);
        self:UpdateSelectionSerfConstrucButtons(_PlayerID);
    end
end

function EntityTracker.Internal:AddToList(_ListName, _Type, _PlayerID, _EntityID)
    if self.Data[_PlayerID] then
        if not self.Data[_PlayerID][_ListName][_Type] then
            self.Data[_PlayerID][_ListName][_Type] = {};
        end
        if not self:IsEntityInList(_ListName, _PlayerID, _EntityID) then
            table.insert(self.Data[_PlayerID][_ListName][_Type], _EntityID);
        end
    end
end

function EntityTracker.Internal:RemoveFromList(_ListName, _Type, _PlayerID, _EntityID)
    if self.Data[_PlayerID] then
        if self.Data[_PlayerID][_ListName][_Type] then
            for i= table.getn(self.Data[_PlayerID][_ListName][_Type]), 1, -1 do
                if self.Data[_PlayerID][_ListName][_Type][i] == _EntityID then
                    table.remove(self.Data[_PlayerID][_ListName][_Type], i);
                    return;
                end
            end
        end
    end
end

function EntityTracker.Internal:IsEntityInList(_ListName, _PlayerID, _EntityID)
    if self.Data[_PlayerID] then
        local Type = Logic.GetEntityType(_EntityID);
        if self.Data[_PlayerID][_ListName][Type] then
            for i= 1, table.getn(self.Data[_PlayerID][_ListName][Type]) do
                if self.Data[_PlayerID][_ListName][Type][i] == _EntityID then
                    return true;
                end
            end
        end
    end
    return false;
end

-- -------------------------------------------------------------------------- --
-- UI

function EntityTracker.Internal:UpdateSelectionSerfConstrucButtons(_PlayerID)
    if GUI.GetPlayerID() == _PlayerID then
        local SelectedID = GUI.GetSelectedEntity();
        if Logic.GetEntityType(SelectedID) == Entities.PU_Serf then
            if XGUIEng.IsButtonHighLighted(gvGUI_WidgetID.ToSerfBeatificationMenu) == 0 then
                GUIUpdate_BuildingButtons("Build_Beautification01", Technologies.B_Beautification01);
                GUIUpdate_BuildingButtons("Build_Beautification02", Technologies.B_Beautification02);
                for i= 3, 12 do
                    local Num = (i < 10 and "0" ..i) or i;
                    GUIUpdate_UpgradeButtons("Build_Beautification" ..Num, Technologies["B_Beautification" ..Num]);
                end
            else
                GUIUpdate_BuildingButtons("Build_Residence", Technologies.B_Residence);
                GUIUpdate_BuildingButtons("Build_Farm", Technologies.B_Farm);
                GUIUpdate_BuildingButtons("Build_Mine", Technologies.B_Claymine);
                GUIUpdate_BuildingButtons("Build_Village", Technologies.B_Village);
                GUIUpdate_BuildingButtons("Build_Monastery", Technologies.B_Monastery);
                GUIUpdate_BuildingButtons("Build_University", Technologies.B_University);
                GUIUpdate_BuildingButtons("Build_Market", Technologies.B_Market);

                GUIUpdate_BuildingButtons("Build_Blacksmith", Technologies.B_Blacksmith);
                GUIUpdate_BuildingButtons("Build_Stonemason", Technologies.B_StoneMason);
                GUIUpdate_BuildingButtons("Build_Alchemist", Technologies.B_Alchemist);
                GUIUpdate_BuildingButtons("Build_Bank", Technologies.B_Bank);
                GUIUpdate_BuildingButtons("Build_Brickworks", Technologies.B_Brickworks);
                GUIUpdate_BuildingButtons("Build_Sawmill", Technologies.B_Sawmill);
                GUIUpdate_BuildingButtons("Build_GunsmithWorkshop", Technologies.B_GunsmithWorkshop);

                GUIUpdate_BuildingButtons("Build_Barracks", Technologies.B_Barracks);
                GUIUpdate_BuildingButtons("Build_Archery", Technologies.B_Archery);
                GUIUpdate_BuildingButtons("Build_Stables", Technologies.B_Stables);
                GUIUpdate_BuildingButtons("Build_Foundry", Technologies.B_Foundry);
                GUIUpdate_BuildingButtons("Build_Tower", Technologies.B_Tower);

                GUIUpdate_BuildingButtons("Build_Weathermachine", Technologies.B_Weathermachine);
                GUIUpdate_BuildingButtons("Build_PowerPlant", Technologies.B_PowerPlant);
                GUIUpdate_BuildingButtons("Build_Tavern", Technologies.B_Tavern);
                GUIUpdate_BuildingButtons("Build_MasterBuilderWorkshop", Technologies.B_MasterBuilderWorkshop);
                GUIUpdate_BuildingButtons("Build_Bridge", Technologies.B_Bridge);
            end
        end
    end
end

function EntityTracker.Internal:UpdateSelectionBuildingUpgradeButtons(_PlayerID, _EntityID)
    if GUI.GetPlayerID() == _PlayerID then
        local SelectedID = GUI.GetSelectedEntity();
        if _EntityID == SelectedID and Logic.IsBuilding(SelectedID) == 1 then
            GUIUpdate_UpgradeButtons("Upgrade_Headquarter1", Technologies.UP1_Headquarter);
            GUIUpdate_UpgradeButtons("Upgrade_Headquarter2", Technologies.UP2_Headquarter);
            GUIUpdate_UpgradeButtons("Upgrade_Farm1", Technologies.UP1_Farm);
            GUIUpdate_UpgradeButtons("Upgrade_Farm2", Technologies.UP2_Farm);
            GUIUpdate_UpgradeButtons("Upgrade_Residence1", Technologies.UP1_Residence);
            GUIUpdate_UpgradeButtons("Upgrade_Residence2", Technologies.UP2_Residence);
            GUIUpdate_UpgradeButtons("Upgrade_Village1", Technologies.UP1_Village);
            GUIUpdate_UpgradeButtons("Upgrade_Village2", Technologies.UP2_Village);

            GUIUpdate_UpgradeButtons("Upgrade_Tower1", Technologies.UP1_Tower);
            GUIUpdate_UpgradeButtons("Upgrade_Tower2", Technologies.UP2_Tower);
            GUIUpdate_UpgradeButtons("Upgrade_Archery1", Technologies.UP1_Archery);
            GUIUpdate_UpgradeButtons("Upgrade_Stables1", Technologies.UP1_Stables);
            GUIUpdate_UpgradeButtons("Upgrade_Foundry1", Technologies.UP1_Foundry);
            GUIUpdate_UpgradeButtons("Upgrade_Barracks1", Technologies.UP1_Barracks);

            GUIUpdate_UpgradeButtons("Upgrade_Claymine1", Technologies.UP1_Claymine);
            GUIUpdate_UpgradeButtons("Upgrade_Claymine2", Technologies.UP2_Claymine);
            GUIUpdate_UpgradeButtons("Upgrade_Stonemine1", Technologies.UP1_Stonemine);
            GUIUpdate_UpgradeButtons("Upgrade_Stonemine2", Technologies.UP2_Stonemine);
            GUIUpdate_UpgradeButtons("Upgrade_Ironmine1", Technologies.UP1_Ironmine);
            GUIUpdate_UpgradeButtons("Upgrade_Ironmine2", Technologies.UP2_Ironmine);
            GUIUpdate_UpgradeButtons("Upgrade_Sulfurmine1", Technologies.UP1_Sulfurmine);
            GUIUpdate_UpgradeButtons("Upgrade_Sulfurmine2", Technologies.UP2_Sulfurmine);
            GUIUpdate_UpgradeButtons("Upgrade_Alchemist1", Technologies.UP1_Alchemist);
            GUIUpdate_UpgradeButtons("Upgrade_Bank1", Technologies.UP1_Bank);
            GUIUpdate_UpgradeButtons("Upgrade_Brickworks1", Technologies.UP1_Brickworks);
            GUIUpdate_UpgradeButtons("Upgrade_Blacksmith1", Technologies.UP1_Blacksmith);
            GUIUpdate_UpgradeButtons("Upgrade_Blacksmith2", Technologies.UP2_Blacksmith);
            GUIUpdate_UpgradeButtons("Upgrade_Sawmill1", Technologies.UP1_Sawmill);
            GUIUpdate_UpgradeButtons("Upgrade_Stonemason1", Technologies.UP1_StoneMason);

            GUIUpdate_UpgradeButtons("Upgrade_University1", Technologies.UP1_University);
            GUIUpdate_UpgradeButtons("Upgrade_Monastery1", Technologies.UP1_Monastery);
            GUIUpdate_UpgradeButtons("Upgrade_Monastery2", Technologies.UP2_Monastery);
            GUIUpdate_UpgradeButtons("Upgrade_Market1", Technologies.UP1_Market);

            GUIUpdate_UpgradeButtons("Upgrade_Tavern1", Technologies.UP1_Tavern);
            GUIUpdate_UpgradeButtons("Upgrade_GunsmithWorkshop1", Technologies.UP1_GunsmithWorkshop);
        end
    end
end

function EntityTracker.Internal:OverrideUpgradeBuilding()
    self.Orig_GUIAction_UpgradeSelectedBuilding = GUIAction_UpgradeSelectedBuilding;
	GUIAction_UpgradeSelectedBuilding = function()
        local PlayerID = GUI.GetPlayerID();
		local EntityID = GUI.GetSelectedEntity();

        if InterfaceTool_IsBuildingDoingSomething(EntityID) == true then
            return;
        end
        -- Check for alarm mode
        if Logic.IsAlarmModeActive(EntityID) == true then
            GUI.AddNote(XGUIEng.GetStringTableText("InGameMessages/Note_StoptAlarmFirst"));
            return;
        end
        -- Check for training leaders
        local LeadersTrainingAtMilitaryBuilding = Logic.GetLeaderTrainingAtBuilding(EntityID);
        if LeadersTrainingAtMilitaryBuilding ~= 0 then
            GUI.AddNote(XGUIEng.GetStringTableText("InGameMessages/GUI_UpgradeNotPossibleBecauseOfTraining"));
            return;
        end
        -- Check for overtime
        if Logic.IsOvertimeActiveAtBuilding(EntityID) == true then
            return;
        end
        -- Check if burning badly
        local MaxHealth = Logic.GetEntityMaxHealth(EntityID);
        local Health = Logic.GetEntityHealth(EntityID);
        if MaxHealth > 0 and Health / MaxHealth <= 0.2 then
            return;
        end

		local Type = Logic.GetEntityType(EntityID);
        gvGUI_UpdateButtonIDArray[EntityID] = XGUIEng.GetCurrentWidgetID();
        Logic.FillBuildingUpgradeCostsTable(Type, InterfaceGlobals.CostTable);
        if InterfaceTool_HasPlayerEnoughResources_Feedback(InterfaceGlobals.CostTable) == 1 then
            if not EntityTracker.Internal.Data[PlayerID] then
                GUI.UpgradeSingleBuilding(EntityID);
            else
                if not EntityTracker.Internal.Data[PlayerID].UpgradeBuildingLock then
                    EntityTracker.Internal.Data[PlayerID].UpgradeBuildingLock = true;
                    GUI.UpgradeSingleBuilding(EntityID);
                    Syncer.InvokeEvent(
                        EntityTracker.Internal.NetworkCall,
                        EntityTracker.Internal.SyncEvent.UpgradeStarted,
                        EntityID
                    );
                end
            end
            XGUIEng.ShowWidget(gvGUI_WidgetID.UpgradeInProgress, 1);
            XGUIEng.TransferMaterials(XGUIEng.GetCurrentWidgetID(), "Cancelupgrade");
        end
	end
end

-- -------------------------------------------------------------------------- --
-- Trigger

function EntityTracker.Internal:StartTriggers()
    Trigger.RequestTrigger(
        Events.LOGIC_EVENT_ENTITY_CREATED,
        nil,
        "EntityTracker_Trigger_EntityCreated",
        1
    );

    Trigger.RequestTrigger(
        Events.LOGIC_EVENT_ENTITY_DESTROYED,
        nil,
        "EntityTracker_Trigger_EntityDestroyed",
        1
    );

    GUIAction_CancelUpgrade = function()
        local EntityID = GUI.GetSelectedEntity();
        local PlayerID = Logic.EntityGetPlayer(EntityID);
        GUI.CancelBuildingUpgrade(EntityID);
        XGUIEng.ShowWidget(gvGUI_WidgetID.UpgradeInProgress, 0);

        Syncer.InvokeEvent(
            EntityTracker.Internal.NetworkCall,
            EntityTracker.Internal.SyncEvent.UpgradeCanceled,
            EntityID
        );
    end
end

function EntityTracker_Trigger_EntityCreated()
    local EntityID = Event.GetEntityID();
    local PlayerID = Logic.EntityGetPlayer(EntityID);
    EntityTracker.Internal:OnEntityCreated(PlayerID, EntityID);
end

function EntityTracker_Trigger_EntityDestroyed()
    local EntityID = Event.GetEntityID();
    local PlayerID = Logic.EntityGetPlayer(EntityID);
    EntityTracker.Internal:OnEntityDestroyed(PlayerID, EntityID);
end

