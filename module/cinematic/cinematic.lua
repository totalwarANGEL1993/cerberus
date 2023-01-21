Lib.Register("module/cinematic/Cinematic");

--- 
--- Provides means of control for cinematic events.
---
--- This file is supposed to be used as dependency for other scripts. Only use
--- the functions, if you know what you are doing!
--- 
--- @author totalwarANGEL
--- @version 1.0.0
--- 

Cinematic = Cinematic or {}

--- List of states for cinematic events.
--- * Inactive Event is not active
--- * Active   Event is currently running
--- * Over     Event is over
CinematicEventStatus = {
    Inactive = 1,
    Active   = 2,
    Over     = 3
};

-- -------------------------------------------------------------------------- --
-- API

--- Installs the cinematic event controller
--- (Will be called by code!)
function Cinematic.Install()
    Cinematic.Internal:Install();
end

--- Creates a new event with the name for the player.
--- @param _PlayerID number ID of player
--- @param _Name string     Name of event
--- @return boolean EventCreated Event was created
function Cinematic.CreateCinematicEvent(_PlayerID, _Name)
    return Cinematic.Internal:CreateCinematicEvent(_PlayerID, _Name);
end

--- Checks if any cinematic event is currently active for the player.
--- @param _PlayerID number ID of player
--- @return boolean AnyActive An event is active
function Cinematic.IsAnyCinematicActive(_PlayerID)
    return Cinematic.Internal:IsAnyCinematicEventActive(_PlayerID)
end

--- Returns the state of the cinematic event.
--- @param _PlayerID number ID of player
--- @param _Name string     Name of event
--- @return number State State of cinematic event
function Cinematic.GetCinematicEventState(_PlayerID, _Name)
    return Cinematic.Internal:GetCinematicEventState(_PlayerID, _Name);
end

--- Sets the state of the cinematic event.
--- @param _PlayerID number ID of player
--- @param _Name string     Name of event
--- @param _State number    New state for event
--- @return boolean StateChanged State was changed
function Cinematic.SetCinematicEventState(_PlayerID, _Name, _State)
    return Cinematic.Internal:SetCinematicEventState(_PlayerID, _Name, _State);
end

--- Activates the cinematic mode.
--- @param _SaveCamera boolean    Save camera position
--- @param _SaveSelection boolean Save selected entities
function Cinematic.EnableCinematicMode(_SaveCamera, _SaveSelection)
    Cinematic.Internal:EnableCinematicMode(_SaveCamera, _SaveSelection);
end

--- Deactivates the cinematic mode.
function Cinematic.DisableCinematicMode()
    Cinematic.Internal:DisableCinematicMode();
end

-- -------------------------------------------------------------------------- --
-- Internal

Cinematic.Internal = Cinematic.Internal or {
    Local = {},
    Data = {
        CinematicEventID = 0;
        EventStatus = {},
    },
};

function Cinematic.Internal:Install()
    if not self.IsInstalled then
        self.IsInstalled = true;

        for k, v in pairs(Score.Player) do
            self.Data.EventStatus[k] = {};
        end
    end
end

function Cinematic.Internal:IsAnyCinematicEventActive(_PlayerID)
    if self.Data.EventStatus[_PlayerID] then
        for k,v in pairs(self.Data.EventStatus[_PlayerID]) do
            if v == CinematicEventStatus.Active then
                return true;
            end
        end
    end
    return false;
end

function Cinematic.Internal:CreateCinematicEvent(_PlayerID, _Name)
    if self.Data.EventStatus[_PlayerID] then
        self.Data.EventStatus[_PlayerID][_Name] = CinematicEventStatus.Inactive;
        return true;
    end
    return false;
end

function Cinematic.Internal:DeleteCinematicEvent(_PlayerID, _Name)
    self.Data.EventStatus[_PlayerID][_Name] = nil;
end

function Cinematic.Internal:GetCinematicEventState(_PlayerID, _Name)
    if self.Data.EventStatus[_PlayerID] then
        if not self.Data.EventStatus[_PlayerID][_Name] then
            self:CreateCinematicEvent(_PlayerID, _Name);
        end
        return self.Data.EventStatus[_PlayerID][_Name];
    end
    return 0;
end

function Cinematic.Internal:SetCinematicEventState(_PlayerID, _Name, _State)
    if self.Data.EventStatus[_PlayerID] then
        if not self.Data.EventStatus[_PlayerID][_Name] then
            self:CreateCinematicEvent(_PlayerID, _Name);
        end
        self.Data.EventStatus[_PlayerID][_Name] = _State;
        return true;
    end
    return false;
end

function Cinematic.Internal:EnableCinematicMode(_RestoreCamera, _RestoreSelection)
    -- Only for receiving player
    local PlayerID = GUI.GetPlayerID();
    if PlayerID == 17 then
        return;
    end
    -- Backup camera
    if _RestoreCamera then
        local x, y = Camera.ScrollGetLookAt();
        self.Local.RestorePosition = {X= x, Y= y};
    end
    -- Backup selection
    if _RestoreSelection then
        local SelectedEntities = {GUI.GetSelectedEntities()};
        self.Local.SelectedEntities = SelectedEntities;
    end

    GUI.ClearSelection();
    GUIAction_GoBackFromHawkViewInNormalView();
    Interface_SetCinematicMode(1);
    Camera.StopCameraFlight();
    Camera.ScrollUpdateZMode(0);
    Camera.RotSetAngle(-45);
    Display.SetRenderFogOfWar(0);
    GUI.MiniMap_SetRenderFogOfWar(1);
    Display.SetRenderSky(1);
    GUI.EnableBattleSignals(false);
    Sound.PlayFeedbackSound(0,0);
    Input.CutsceneMode();
    GUI.SetFeedbackSoundOutputState(0);
    Logic.SetGlobalInvulnerability(1);
    LocalMusic.SongLength = 0;

    XGUIEng.ShowWidget("Cinematic",1);
    XGUIEng.ShowWidget("Cinematic_Text",0);
    XGUIEng.ShowWidget("Cinematic_Headline",0);
    XGUIEng.ShowWidget("CinematicMC_Container", 1);
    XGUIEng.ShowWidget("CinematicMC_Text", 1);
    XGUIEng.ShowWidget("CinematicMC_Headline", 1);
    XGUIEng.ShowWidget("CinematicMiniMapContainer",1);

    XGUIEng.ShowWidget("Normal",1);
    XGUIEng.ShowAllSubWidgets("Windows",0);
    XGUIEng.ShowWidget("Top",0);
    XGUIEng.ShowWidget("MiniMapOverlay",0);
    XGUIEng.ShowWidget("ResourceView",0);
    XGUIEng.ShowWidget("SelectionView",0);
    XGUIEng.ShowWidget("TooltipBottom",0);
    XGUIEng.ShowWidget("ShortMessagesListWindow",0);
    XGUIEng.ShowWidget("ShortMessagesOutputWindow",0);
    XGUIEng.ShowWidget("BackGround_Top",0);
    XGUIEng.ShowWidget("MapProgressStuff",0);
    XGUIEng.ShowWidget("MultiSelectionContainer",0);
    XGUIEng.ShowWidget("MinimapButtons",0);
    XGUIEng.ShowWidget("BackGroundBottomContainer",0);
    XGUIEng.ShowWidget("TutorialMessageBG",0);
    XGUIEng.ShowWidget("MiniMap",0);
    XGUIEng.ShowWidget("VideoPreview",0);
    XGUIEng.ShowWidget("Movie",0);

    GUIAction_ToggleMenu("NetworkWindow", 0);
end

function Cinematic.Internal:DisableCinematicMode()
    -- Only for receiving player
    local PlayerID = GUI.GetPlayerID();
    if PlayerID == 17 then
        return;
    end
    -- Restore camera
    if self.Local.RestorePosition then
        Camera.ScrollSetLookAt(self.Local.RestorePosition.X, self.Local.RestorePosition.Y);
        self.Local.RestorePosition = nil;
    end
    -- Restore selection
    if self.Local.SelectedEntities then
        for i= 1, table.getn(self.Local.SelectedEntities), 1 do
            GUI.SelectEntity(self.Local.SelectedEntities[i]);
        end
        self.Local.SelectedEntities = nil;
    end

    Interface_SetCinematicMode(0);
    Display.SetRenderFogOfWar(1);
    Display.SetRenderSky(0);
    Camera.FollowEntity(0);
    Logic.SetGlobalInvulnerability(0);
    GUI.EnableBattleSignals(true);
    GUI.ActivateSelectionState();
    Input.GameMode();
    GUI.SetFeedbackSoundOutputState(1);
    Stream.Stop();
    LocalMusic.SongLength = 0;

    XGUIEng.ShowWidget("Normal",1);
    XGUIEng.ShowWidget("3dOnScreenDisplay",1);
    XGUIEng.ShowWidget("Cinematic",0);
    XGUIEng.ShowWidget("CinematicMiniMapContainer",0);

    XGUIEng.ShowWidget("Windows",1);
    XGUIEng.ShowWidget("Top",1);
    XGUIEng.ShowWidget("MiniMapOverlay",1);
    XGUIEng.ShowWidget("ResourceView",1);
    XGUIEng.ShowWidget("SelectionView",1);
    XGUIEng.ShowWidget("ShortMessagesListWindow",1);
    XGUIEng.ShowWidget("BackGround_Top",1);
    XGUIEng.ShowWidget("MapProgressStuff",1);
    XGUIEng.ShowWidget("MinimapButtons",1);
    XGUIEng.ShowWidget("BackGroundBottomContainer",1);
    XGUIEng.ShowWidget("MiniMap",1);

    GUIAction_ToggleMenu("NetworkWindow", 0);
end

function Cinematic.Internal:SetPageStyle(_DisableMap, _MCAmount, _ForceVN)
    if _MCAmount and _MCAmount > 2 or _ForceVN then
        self:SetVisualNovelPageStyle(_DisableMap, _MCAmount);
    else
        self:SetRegularPageStyle(_DisableMap, _MCAmount);
    end
end

function Cinematic.Internal:SetRegularPageStyle(_DisableMap, _MCAmount)
    local size = {GUI.GetScreenSize()};
    local titlePosY = 45;
    local textPosY = ((size[2]*(768/size[2])))-100;
    local titleSize = (size[1]-200);

    XGUIEng.SetWidgetPositionAndSize("CinematicMC_Container",0,0,size[1],size[2]);
    XGUIEng.SetWidgetPositionAndSize("Cinematic_Text",(200),textPosY,(680),100);
    XGUIEng.SetWidgetPositionAndSize("CinematicMC_Text",(200),textPosY,(680),100);
    XGUIEng.SetWidgetPositionAndSize("CinematicMC_Headline",100,titlePosY,titleSize,15);
    XGUIEng.SetWidgetPositionAndSize("Cinematic_Headline",100,titlePosY,titleSize,15);
    XGUIEng.SetWidgetPositionAndSize("CinematicBar01",0,size[2],size[1],180);
    XGUIEng.SetWidgetPositionAndSize("CinematicBar00",0,0,size[1],size[2]);
    XGUIEng.SetMaterialTexture("CinematicBar02", 0, "data/graphics/textures/gui/cutscene_top.dds");
    XGUIEng.SetMaterialColor("CinematicBar02", 0, 255, 255, 255, 255);
    XGUIEng.SetWidgetPositionAndSize("CinematicBar02", 0, 0, size[1], 180);

    local choiceHeight = Round(46*(768/size[2]));
    local choiceWidth  = Round(400*(1024/size[1]));
    local choicePosX1 = 100 * (1024/size[1]);
    local choicePosY1 = (size[2] * (1024/size[1])) - choiceHeight;
    local choicePosX2 = size[1] - (choiceWidth + (100 * (1024/size[1])));
    local choicePosY2 = (size[2] * (1024/size[1])) - choiceHeight;
    XGUIEng.SetWidgetPositionAndSize("CinematicMC_Button1", choicePosX1, choicePosY1, 400, 46);
    XGUIEng.SetWidgetPositionAndSize("CinematicMC_Button2", choicePosX2, choicePosY2, 400, 46);

    XGUIEng.ShowWidget("CinematicMiniMapOverlay", (_DisableMap and 0) or 1);
    XGUIEng.ShowWidget("CinematicMiniMap", (_DisableMap and 0) or 1);
    XGUIEng.ShowWidget("CinematicFrameBG", (_DisableMap and 0) or 1);
    XGUIEng.ShowWidget("CinematicFrame", (_DisableMap and 0) or 1);
    XGUIEng.ShowWidget("CinematicMC_Button1", 1);
    XGUIEng.ShowWidget("CinematicMC_Button2", 1);
    XGUIEng.ShowWidget("CinematicBar02", 1);
    XGUIEng.ShowWidget("CinematicBar01", 1);
    XGUIEng.ShowWidget("CinematicBar00", 1);
end

function Cinematic.Internal:SetVisualNovelPageStyle(_DisableMap, _MCAmount)
    local size = {GUI.GetScreenSize()};
    local Is4To3 = (size[2]/3) * 4 == size[1];
    local button1Y = (size[2]*(768/size[2]))-10;
    local button2Y = (size[2]*(768/size[2]))-10;
    local titlePosY = 45;
    local textPosY = ((size[2]*(768/size[2])))-100;
    local titleSize = (size[1]-200);
    local choiceHeight = Round(46*(768/size[2]));
    local choiceWidth  = Round(800*(1024/size[1]));
    local choicePosX   = Round(((Is4To3 and 112) or (112*1.4))*(size[1]/1024));
    local choicePosY   = Round(((size[2]*(768/size[2]))/2) - ((_MCAmount/2)*(choiceHeight+10)));

    -- Set widget apperance
    XGUIEng.SetWidgetPositionAndSize("CinematicMC_Container",0,0,size[1],size[2]);
    XGUIEng.SetWidgetPositionAndSize("Cinematic_Text",(200),textPosY,(680),100);
    XGUIEng.SetWidgetPositionAndSize("CinematicMC_Text",(200),textPosY,(680),100);
    XGUIEng.SetWidgetPositionAndSize("CinematicMC_Headline",100,titlePosY,titleSize,15);
    XGUIEng.SetWidgetPositionAndSize("Cinematic_Headline",100,titlePosY,titleSize,15);
    XGUIEng.SetWidgetPositionAndSize("CinematicBar01",0,size[2],size[1],180);
    XGUIEng.SetWidgetPositionAndSize("CinematicBar00",0,0,size[1],size[2]);
    XGUIEng.SetMaterialTexture("CinematicBar02", 0, "data/graphics/textures/gui/cutscene_top.dds");
    XGUIEng.SetMaterialColor("CinematicBar02", 0, 255, 255, 255, 255);
    XGUIEng.SetWidgetPositionAndSize("CinematicBar02", 0, 0, size[1], 180);

    -- Set answers
    for i= 1, _MCAmount, 1 do
        if XGUIEng.IsWidgetExisting("CinematicMC_Button" ..i) == 1 then
            XGUIEng.SetWidgetPositionAndSize("CinematicMC_Button" ..i, choicePosX, choicePosY, choiceWidth, choiceHeight);
            choicePosY = choicePosY + (choiceHeight+10);
        end
    end

    -- Set widget visability
    XGUIEng.ShowWidget("CinematicMiniMapOverlay", (_DisableMap and 0) or 1);
    XGUIEng.ShowWidget("CinematicMiniMap", (_DisableMap and 0) or 1);
    XGUIEng.ShowWidget("CinematicFrameBG", (_DisableMap and 0) or 1);
    XGUIEng.ShowWidget("CinematicFrame", (_DisableMap and 0) or 1);
    XGUIEng.ShowWidget("CinematicBar02", 1);
    XGUIEng.ShowWidget("CinematicBar01", 1);
    XGUIEng.ShowWidget("CinematicBar00", 1);
    for i= 1, _MCAmount, 1 do
        if XGUIEng.IsWidgetExisting("CinematicMC_Button" ..i) == 1 then
            XGUIEng.ShowWidget("CinematicMC_Button" ..i, 1);
        else
            GUI.AddStaticNote("Debug: Widget CinematicMC_Button" ..i.. " does not exist!");
        end
    end
end

