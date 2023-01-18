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
--- @require Syncer
--- @require GetUpgradeCategoryByEntityType
--- @require GetUpgradeLevelByEntityType
--- @author totalwarANGEL
--- @version 1.0.0
---

EntityTracker = {
    Internal = {
        Data = {},
        Config = {
            Limit = {},
        },
    },
}

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
--- @return number Limit Current limit for type
function EntityTracker.GetLimitOfType(_Type)
    return EntityTracker.Internal:GetLimitForType(_Type);
end

--- Sets a limit for the type.
---  * -1   No limit
---  *  0   Forbidden
---  * >0   Limit
--- 
--- @param _Type number Entity type
--- @param _Limit number Limit for type
function EntityTracker.SetLimitOfType(_Type, _Limit)
    EntityTracker.Internal:SetLimitForType(_Type, _Limit);
end

--- Returns the amount of tracked entities of the player.
--- @param _PlayerID number ID of player
--- @param _Type number Entity type
--- @return number amount of entities
function EntityTracker.GetUsageOfType(_PlayerID, _Type)
    return EntityTracker.Internal:GetCurrentAmountOfType(_PlayerID, _Type);
end

-- -------------------------------------------------------------------------- --
-- Internal

function EntityTracker.Internal:Install()
    if not self.IsInstalled then
        self.IsInstalled = true;

        for i= 1, table.getn(Score.Player) do
            self.Data[i] = {
                Potential = {},
                Current = {},
            };
        end
        self:SetupSynchronization();
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

function EntityTracker.Internal:GetLimitForType(_Type)
    local UpgradeCategory = GetUpgradeCategoryByEntityType(_Type);
    local UpgradeLevel = GetUpgradeLevelByEntityType(_Type);
    if UpgradeCategory ~= 0 and self.Config.Limit[UpgradeCategory] then
        return self.Config.Limit[UpgradeCategory][UpgradeLevel +1];
    end
    return -1;
end

function EntityTracker.Internal:SetLimitForType(_Type, _Limit)
    local UpgradeCategory = GetUpgradeCategoryByEntityType(_Type);
    local UpgradeLevel = GetUpgradeLevelByEntityType(_Type);
    if UpgradeCategory ~= 0 then
        if not self.Config.Limit[UpgradeCategory] then
            self.Config.Limit[UpgradeCategory] = {-1, -1, -1, -1};
        end
        self.Config.Limit[UpgradeCategory][UpgradeLevel +1] = _Limit;
    end
end

function EntityTracker.Internal:GetCurrentAmountOfType(_PlayerID, _Type)
    local Amount = 0;
    local UpgradeCategory = GetUpgradeCategoryByEntityType(_Type);
    if self.Data[_PlayerID] and self.Config.Limit[UpgradeCategory] then
        if self.Data[_PlayerID].Potential[_Type] then
            Amount = Amount + table.getn(self.Data[_PlayerID].Potential[_Type]);
        end
        if self.Data[_PlayerID].Current[_Type] then
            Amount = Amount + table.getn(self.Data[_PlayerID].Current[_Type]);
        end
    end
    return Amount;
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
        self:RemoveFromList("Potential", Type +1, _PlayerID, _EntityID);
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
        self:AddToList("Potential", Type +1, _PlayerID, _EntityID);
        self:RemoveFromList("Current", Type, _PlayerID, _EntityID);
        -- self:UpdateSelectionBuildingUpgradeButtons(_PlayerID, _EntityID);
        -- self:UpdateSelectionSerfConstrucButtons(_PlayerID);
    end
end

function EntityTracker.Internal:OnUpgradeCanceled(_PlayerID, _EntityID)
    if self.Data[_PlayerID] then
        local Type = Logic.GetEntityType(_EntityID);
        self:RemoveFromList("Potential", Type +1, _PlayerID, _EntityID);
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
                GameCallback_GUI_SelectionChanged();
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
		local Type = Logic.GetEntityType(EntityID);

        if InterfaceTool_IsBuildingDoingSomething(EntityID) == true then
            return;
        end
        if Logic.IsAlarmModeActive(EntityID) == true then
            GUI.AddNote(XGUIEng.GetStringTableText("InGameMessages/Note_StoptAlarmFirst"));
            return;
        end
        local LeadersTrainingAtMilitaryBuilding = Logic.GetLeaderTrainingAtBuilding(EntityID);
        if LeadersTrainingAtMilitaryBuilding ~= 0 then
            GUI.AddNote(XGUIEng.GetStringTableText("InGameMessages/GUI_UpgradeNotPossibleBecauseOfTraining"));
            return;
        end

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
                        PlayerID,
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
            PlayerID,
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

