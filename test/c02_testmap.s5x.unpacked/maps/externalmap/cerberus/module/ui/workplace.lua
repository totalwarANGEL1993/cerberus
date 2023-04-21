Lib.Require("comfort/GetLanguage");
Lib.Require("comfort/GetSeparatedTooltipText");
Lib.Require("comfort/IsBuildingBeingUpgraded");
Lib.Require("module/lua/Overwrite");
Lib.Require("module/mp/Syncer");
Lib.Require("module/trigger/Job");
Lib.Register("module/ui/Workplace");

--- 
--- Changeable worker amount
--- 
--- Enables the player to set the amount of workers in a workplace. The
--- amount can be set to zero, half or full.
--- 
--- @require GetLanguage
--- @require GetSeparatedTooltipText
--- @require IsBuildingBeingUpgraded
--- @require Job
--- @require Overwrite
--- @require Syncer
--- @author totalwarANGEL
--- @version 1.0.0
--- 

Workplace = Workplace or {};

-- -------------------------------------------------------------------------- --
-- API

--- Initalizes the feature.
--- (Must be called on game start.)
function Workplace.Install()
    Workplace.Internal:Install()
end

-- -------------------------------------------------------------------------- --
-- Internal

Workplace.Internal = Workplace.Internal or {
    WorkerAmountChangeable = true,
    Event = {},
    Data = {
        WorkplaceStates = {},
    },
};

function Workplace.Internal:Install()
    Syncer.Install();
    Overwrite.Install();

    if not self.IsInstalled then
        self.IsInstalled = true;

        self:CreateScriptEvent();
        self:OverwriteOnSaveGameLoaded();
        self:OverrideInterfaceAction();
        self:OverrideInterfaceTooltip();
        self:OverrideInterfaceUpdate();
        self:InitDisplay();
    end
end

function Workplace.Internal:OverwriteOnSaveGameLoaded()
    self.Orig_Mission_OnSaveGameLoaded = Mission_OnSaveGameLoaded;
    Mission_OnSaveGameLoaded = function()
        Workplace.Internal.Orig_Mission_OnSaveGameLoaded();
        Workplace.Internal:InitDisplay();
    end
end

function Workplace.Internal:CreateScriptEvent()
    self.Event.AdjustWorker = Syncer.CreateEvent(function(_PlayerID, _BuildingID, _State)
        Workplace.Internal:SetWorkerAmountInBuilding(_BuildingID, _State);
        Workplace.Internal:UpdateDisplay();
    end);
end

-- UI Action --

function Workplace.Internal:SetWorkerAmountInBuilding(_BuildingID, _State)
    local Amount = Workplace.Internal:CalculateWorkerAmountInBuilding(_BuildingID, _State);
    self.Data.WorkplaceStates[_BuildingID] = _State or "full";
    local Worker = {Logic.GetAttachedWorkersToBuilding(_BuildingID)};
    for i= Worker[1]+1, 2, -1 do
        local TaskList = Logic.GetCurrentTaskList(Worker[i]);
        if TaskList and Logic.IsSettlerAtWork(Worker[i]) then
            local s, e = string.find(TaskList, "^TL_[A-Z]+_");
            local TaskPrefix = string.sub(TaskList, s, e);
            if TaskLists[TaskPrefix.. "WORK_INSIDE_START"] then
                Logic.SetTaskList(Worker[i], TaskLists[TaskPrefix.. "WORK_INSIDE_START"]);
            end
        end
    end
    Logic.SetCurrentMaxNumWorkersInBuilding(_BuildingID, Amount);
end

function Workplace.Internal:CalculateWorkerAmountInBuilding(_BuildingID, _State)
    local MaxNumberOfworkers = Logic.GetMaxNumWorkersInBuilding(_BuildingID);
    local CurrentWorkerAmount = 0;
    if _State == "half" then
        CurrentWorkerAmount = math.ceil(MaxNumberOfworkers/2);
    elseif _State == "full" then
        CurrentWorkerAmount = MaxNumberOfworkers;
    end
    return CurrentWorkerAmount;
end

function Workplace.Internal:OverrideInterfaceAction()
    Overwrite.CreateOverwrite(
        "GUIAction_SetAmountOfWorkers",
        function(_State)
            if GUI.GetPlayerID() ~= 17 then
                local BuildingID = GUI.GetSelectedEntity();
                Syncer.InvokeEvent(
                    Workplace.Internal.Event.AdjustWorker,
                    BuildingID,
                    _State
                );
            end
        end
    );
end

-- UI Tooltip --

function Workplace.Internal:OverrideInterfaceTooltip()
    Overwrite.CreateOverwrite(
        "GUITooltip_NormalButton", function(_Key)
            Overwrite.CallOriginal();
            local lang = GetLanguage();
            if _Key == "MenuBuildingGeneric/setworkerfew" then
                XGUIEng.SetText(gvGUI_WidgetID.TooltipBottomText, Workplace.Internal.Text["SettingFew"][lang]);
                XGUIEng.SetText(gvGUI_WidgetID.TooltipBottomCosts, "");
                XGUIEng.SetText(gvGUI_WidgetID.TooltipBottomShortCut, "");
            elseif _Key == "MenuBuildingGeneric/setworkerhalf" then
                XGUIEng.SetText(gvGUI_WidgetID.TooltipBottomText, Workplace.Internal.Text["SettingHalf"][lang]);
                XGUIEng.SetText(gvGUI_WidgetID.TooltipBottomCosts, "");
                XGUIEng.SetText(gvGUI_WidgetID.TooltipBottomShortCut, "");
            elseif _Key == "MenuBuildingGeneric/setworkerfull" then
                XGUIEng.SetText(gvGUI_WidgetID.TooltipBottomText, Workplace.Internal.Text["SettingFull"][lang]);
                XGUIEng.SetText(gvGUI_WidgetID.TooltipBottomCosts, "");
                XGUIEng.SetText(gvGUI_WidgetID.TooltipBottomShortCut, "");
            end
        end
    );

    Overwrite.CreateOverwrite(
        "GUITooltip_ResearchTechnologies", function(_Technology, _TextKey, _ShortCut)
            local PlayerID = GUI.GetPlayerID();
            local TechState = Logic.GetTechnologyState(PlayerID, _Technology);
            local TooltipText =  "MenuGeneric/TechnologyNotAvailable";
            if TechState == 1 or  TechState == 5 then
                TooltipText = _TextKey .. "_disabled";
            elseif TechState == 2 or TechState == 3 then
                TooltipText = _TextKey .. "_normal";
            elseif TechState == 4 then
                TooltipText = _TextKey .. "_researched";
            end
            Overwrite.CallOriginal();

            if _Technology == Technologies.GT_Literacy then
                local lang = GetLanguage();
                local Text = GetSeparatedTooltipText(TooltipText);
                if TechState == 1 or  TechState == 5 then
                    Text[3] = Text[3] .. Workplace.Internal.Text.Literacy.Privilege[lang];
                elseif TechState == 2 or TechState == 3 then
                    Text[2] = Text[2] .. Workplace.Internal.Text.Literacy.Privilege[lang];
                end
                XGUIEng.SetText(gvGUI_WidgetID.TooltipBottomText, table.concat(Text, " @cr "));
            end
        end
    );
end

-- UI Update --

function Workplace.Internal:OverrideInterfaceUpdate()
    Overwrite.CreateOverwrite(
        "GameCallback_GUI_SelectionChanged", function()
            Overwrite.CallOriginal();
            Workplace.Internal:UpdateDisplay();
        end
    );

    Overwrite.CreateOverwrite(
        "GameCallback_OnTechnologyResearched", function(_EntityIDOld, _EntityIDNew)
            Overwrite.CallOriginal();
            Workplace.Internal:UpdateDisplay();
        end
    );

    Overwrite.CreateOverwrite(
        "GameCallback_OnCannonConstructionComplete", function(_BuildingID, _null)
            Overwrite.CallOriginal();
            Workplace.Internal:UpdateDisplay();
        end
    );

    Overwrite.CreateOverwrite(
        "GameCallback_OnTransactionComplete", function(_BuildingID, _null)
            Overwrite.CallOriginal();
            Workplace.Internal:UpdateDisplay();
        end
    );

    Overwrite.CreateOverwrite(
        "GameCallback_OnBuildingConstructionComplete", function(_EntityID, _PlayerID)
            Overwrite.CallOriginal();
            Workplace.Internal:UpdateDisplay();
        end
    );

    Overwrite.CreateOverwrite(
        "GameCallback_OnBuildingUpgradeComplete", function(_OldID, _NewID)
            Overwrite.CallOriginal();
            -- Delay is needed to readjust worker count
            Job.Turn(
                function(_Turn, _ID, _State)
                    if Logic.GetCurrentTurn() > _Turn+1 then
                        Workplace.Internal:SetWorkerAmountInBuilding(_ID, _State);
                        Workplace.Internal:UpdateDisplay();
                        return true;
                    end
                end,
                Logic.GetCurrentTurn(),
                _NewID,
                Workplace.Internal.Data.WorkplaceStates[_OldID] or "full"
            );
        end
    );
end

function Workplace.Internal:InitDisplay()
    XGUIEng.SetWidgetPositionAndSize("Details_Generic", 452,70,100,90);
    XGUIEng.SetWidgetPosition("DetailsArmor", 2, 25);
    XGUIEng.SetWidgetPosition("DetailsDamage", 2, 40);
    XGUIEng.SetWidgetPositionAndSize("DetailsExperience", 4, 64, 80, 20);
    XGUIEng.SetWidgetPositionAndSize("DetailsGroupStrength", 7, 82, 80, 10);
    XGUIEng.SetWidgetPositionAndSize("DetailsGroupStrength_Soldier01", 0, 0, 13, 13);
    XGUIEng.SetWidgetPositionAndSize("DetailsGroupStrength_Soldier02", 9, 0, 13, 13);
    XGUIEng.SetWidgetPositionAndSize("DetailsGroupStrength_Soldier03", 18, 0, 13, 13);
    XGUIEng.SetWidgetPositionAndSize("DetailsGroupStrength_Soldier04", 27, 0, 13, 13);
    XGUIEng.SetWidgetPositionAndSize("DetailsGroupStrength_Soldier05", 36, 0, 13, 13);
    XGUIEng.SetWidgetPositionAndSize("DetailsGroupStrength_Soldier06", 45, 0, 13, 13);
    XGUIEng.SetWidgetPositionAndSize("DetailsGroupStrength_Soldier07", 54, 0, 13, 13);
    XGUIEng.SetWidgetPositionAndSize("DetailsGroupStrength_Soldier08", 63, 0, 13, 13);
    XGUIEng.SetWidgetPositionAndSize("Details_Workers", 455, 135, 100, 55);
    XGUIEng.SetWidgetPosition("Thief_StolenRessourceAmount", 469, 85);
    XGUIEng.SetWidgetPosition("Thief_StolenRessourceType", 455, 78);
    XGUIEng.SetWidgetPosition("DetailsHealth", 11, 5);

    XGUIEng.SetWidgetPosition("SetWorkersAmountFew", 4, 25);
    XGUIEng.SetWidgetPosition("SetWorkersAmountHalf", 30, 25);
    XGUIEng.SetWidgetPosition("SetWorkersAmountFull", 54, 25);
    XGUIEng.SetWidgetPosition("WorkersAmountFew", 1, 45);
    XGUIEng.SetWidgetPosition("WorkersAmountHalf", 27, 45);
    XGUIEng.SetWidgetPosition("WorkersAmountFull", 51, 45);
    XGUIEng.SetWidgetPosition("WorkersIcon", 27, 0);
end

function Workplace.Internal:UpdateDisplay()
    local SeletedID = GUI.GetSelectedEntity();
    local PlayerID = Logic.EntityGetPlayer(SeletedID);
    if SeletedID ~= 0 and PlayerID == GUI.GetPlayerID() then
        if  Workplace.Internal.WorkerAmountChangeable == true
        and Logic.IsEntityInCategory(SeletedID, EntityCategories.Workplace) == 1
        and Logic.GetEntityType(SeletedID) ~= Entities.PB_Market1
        and Logic.IsConstructionComplete(SeletedID) == 1
        and not IsBuildingBeingUpgraded(SeletedID)
        and Logic.IsTechnologyResearched( 1, Technologies.GT_Literacy ) == 1 then
            -- Update visibility
            XGUIEng.ShowWidget("Details_Workers", 1);
            XGUIEng.ShowWidget("WorkersAmountFew", 1);
            XGUIEng.ShowWidget("WorkersAmountHalf", 1);
            XGUIEng.ShowWidget("WorkersAmountFull", 1);
            XGUIEng.ShowWidget("SetWorkersAmountFew", 1);
            XGUIEng.ShowWidget("SetWorkersAmountHalf", 1);
            XGUIEng.ShowWidget("SetWorkersAmountFull", 1);
            XGUIEng.ShowWidget("WorkersIcon", 1);

            -- Update Button text
            local MaxNumberOfworkers = Logic.GetMaxNumWorkersInBuilding(SeletedID);
            local FewAmount = 0;
            local HalfAmount = math.ceil( MaxNumberOfworkers/2);
            local FullAmount = MaxNumberOfworkers;
            XGUIEng.SetTextByValue(gvGUI_WidgetID.WorkersAmountFew, FewAmount, 1);
            XGUIEng.SetTextByValue(gvGUI_WidgetID.WorkersAmountHalf, HalfAmount, 1);
            XGUIEng.SetTextByValue(gvGUI_WidgetID.WorkersAmountFull, FullAmount, 1);

            -- Update button highlighting
            local HighlightStates = {0, 0, 1};
            if self.Data.WorkplaceStates[SeletedID] then
                if self.Data.WorkplaceStates[SeletedID] == "few" then
                    HighlightStates[1] = 1;
                    HighlightStates[3] = 0;
                elseif self.Data.WorkplaceStates[SeletedID] == "half" then
                    HighlightStates[2] = 1;
                    HighlightStates[3] = 0;
                end
            end
            XGUIEng.UnHighLightGroup(gvGUI_WidgetID.InGame, "SetWorkersGroup");
            XGUIEng.HighLightButton("SetWorkersAmountFew", HighlightStates[1]);
            XGUIEng.HighLightButton("SetWorkersAmountHalf", HighlightStates[2]);
            XGUIEng.HighLightButton("SetWorkersAmountFull", HighlightStates[3]);
        else
            XGUIEng.ShowWidget("WorkersIcon", 0);
        end
    end
end

-- Text Config --

Workplace.Internal.Text = {
    SettingFew = {
        de = "@color:180,180,180 Betrieb stilllegen @cr @color:255,255,255 "..
             "Die Arbeit im Betrieb wird stillgelegt. Alle Arbeiter suchen "..
             "sich einen neuen Arbeitsplatz oder verlassen die Siedlung.",
        en = "@color:180,180,180 Stop work @cr @color:255,255,255 The "..
             "production of the workplace is halted. All workers will "..
             "leave the settlement if they can not find a new job.",
    },
    SettingHalf = {
        de = "@color:180,180,180 Halbe Belegschaft @cr @color:255,255,255 "..
             "Halbiert die Belegschaft des Betrieb. Die Arbeiter verlassen "..
             "die Siedlung, wenn sie keinen neuen Arbeitsplatz finden.",
        en = "@color:180,180,180 Half utilization @cr @color:255,255,255 "..
             "The amount of workers is halved. The surplus workers leave "..
             "the settlement if they can not find a new job.",
    },
    SettingFull = {
        de = "@color:180,180,180 Volle Auslastung @cr @color:255,255,255 "..
             "Alle Arbeitstellen werden mit Arbeitern beseitzt, sofern noch "..
             "Platz in der Siedlung für sie vorhanden ist.",
        en = "@color:180,180,180 Full utilization @cr @color:255,255,255 "..
             "All possible workplaces will be manned with workers if there "..
             "is enough space in the settlement.",
    },

    Literacy = {
        Privilege = {
            de = " Bestimmt zudem die Menge an Arbeiter in Gebäuden.",
            en = " You can also set the worker count in a building.",
        }
    }
};

