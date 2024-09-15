Lib.Require("comfort/GetMaxAmountOfPlayer");
Lib.Require("comfort/Localize");
Lib.Require("comfort/IsInTable");
Lib.Require("comfort/Round");
Lib.Require("module/cinematic/Cinematic");
Lib.Require("module/ui/Placeholder");
Lib.Require("module/mp/Syncer");
Lib.Require("module/trigger/Job");
Lib.Register("module/cinematic/BriefingSystem");

--- @diagnostic disable: duplicate-set-field

--- 
--- Briefing System
---
--- Briefings are a method of giving exposition to the player. Usually they are
--- only used in singleplayer but they can also be used in multiplayer and even
--- shown to other players who are mere watchers and can not interact with the
--- briefing in any way apart from reading the text.
---
--- Defines the following callbacks:
--- - GameCallback_Logic_BriefingStarted(_PlayerID, _Briefing)
---   A briefing started for the player.
---
--- - GameCallback_Logic_BriefingFinished(_PlayerID, _Briefing)
---   A briefing finished for the player.
---
--- - GameCallback_Logic_BriefingPageShown(_PlayerID, _Briefing, _PageID)
---   A page of a briefing is shown to the player.
---
--- - GameCallback_Logic_BriefingOptionSelected(_PlayerID, _Briefing, _PageID, _OptionID, _NextPageID)
---   An option was selected
---
--- Version 1.4.1
--- 
BriefingSystem = BriefingSystem or {
    TimerPerChar = 0.6,
    FakeHeight = 150,
    FOV = 42,
    DialogZoomDistance = 1500,
    DialogZoomAngle = 35,
    DialogRotationAngle = -45,
    BriefingZoomDistance = 6000,
    BriefingZoomAngle = 48,
    BriefingRotationAngle = -45,
    BriefingExploration = 6000,
    MCButtonAmount = 2,
}

-- -------------------------------------------------------------------------- --
-- API

--- Starts a briefing for a player.
---
--- If the briefing table contains a function `Starting` then it is called
--- before the briefing starts.
---
--- If the briefing table contains a function `Finished` then it is called
--- after the briefing is finished.
---
--- Fields to configure:
--- * NoSkip      - Page skipping is disabled
--- * ResetCamera - Camera position before the briefing is restored
--- * RenderFoW   - Show or hide the FoW
--- * RenderSky   - Show or hide the Sky
---
--- @param _PlayerID number     Player the briefing is started for
--- @param _BriefingName string Name of Briefing (must be unique for player)
--- @param _Briefing table      Definition of briefing
--- @param ... integer          List of watchers
function BriefingSystem.Start(_PlayerID, _BriefingName, _Briefing, ...)
    -- Transmute some fields
    if _Briefing.NoSkip ~= nil then
        _Briefing.DisableSkipping = _Briefing.NoSkip == true;
    end
    if _Briefing.ResetCamera ~= nil then
        _Briefing.RestoreCamera = _Briefing.ResetCamera == true;
    end

    BriefingSystem.Internal:StartBriefing(_PlayerID, _BriefingName, _Briefing, unpack(arg));
end

--- Binds the page function to the briefing.
---
--- Usage:
--- local AP, ASP, AMC = BriefingSystem.AddPages(Briefing);
---
--- @param _Briefing table Definition of briefing
--- @return function AP  Functon to create a page
--- @return function ASP Function for simplyfied pages
--- @return function AMC Function for simplyfied selection pages
function BriefingSystem.AddPages(_Briefing)
    return BriefingSystem.Internal:AddPages(_Briefing);
end

--- Changes the amount of multiple choice buttons.
--- (More than 2 buttons must be created inside the GUI XML!)
--- @param _Amount number Amount of buttons
function BriefingSystem.SetMCButtonCount(_Amount)
    BriefingSystem.MCButtonAmount = _Amount;
end

--- Returns the selected answer from the page.
--- @param _PageName string Page name
--- @param _PlayerID number ID of player
--- @return number Index Selected answer index
function BriefingSystem.GetSelectedAnswer(_PageName, _PlayerID)
    _PlayerID = _PlayerID or 1;
    local PageID = BriefingSystem.Internal:GetPageID(_PageName, _PlayerID)
    local Page = BriefingSystem.Internal.Data.Book[_PlayerID][PageID];
    if Page and Page.MC and Page.MC.Selected then
        return Page.MC.Selected;
    end
    return 0;
end

--- Checks if a briefing is active for the player.
--- @param _PlayerID number ID of Player
--- @return boolean Active Briefing is active
function BriefingSystem.IsActive(_PlayerID)
    return BriefingSystem.Internal:IsBriefingActive(_PlayerID);
end

--- Creates a page from the page definition.
--- 
--- Fields to configure:
--- * Name       - Name of Page
--- * Title      - Headline of the page
--- * TitleAlter - Headline alteration for watchers
--- * Text       - Text of the page
--- * TextAlter  - Text alteration for watchers
--- * CloseUp    - Use dialog camera settings
--- * Action     - Function called when page is shown
--- * Flight     - Fly from last position
--- * Duration   - Display duration of page
--- * Target     - Entity the camera shows
--- * Height     - Camera hight emulation
--- * Distance   - Distance of the camera
--- * Rotation   - Rotation of the camera
--- * Angle      - Angle of the camera
--- * NoSkip     - Disable skipping on this page
--- * RenderFoW  - Render FoW for this page
--- * RenderSky  - Render Sky for this page
--- * FadeIn     - Duration of fading in from black
--- * FadeOut    - Duration of fading out to black
--- * FaderAlpha - Opacity of fader mask
--- * MiniMap    - Display the minimap on this page
--- * Signal     - Mark the camera position on the minimap
--- * Explore    - Show an area while page is shown
---
--- @param _Data table Page definition
--- @return table Page Page definition
function AP(_Data)
    assert(false, "Must be initalized with BriefingSystem.AddPages!");
    return {};
end

--- Simplyfied call for creating normal pages.
---
--- Parameter order: [name, ] position, title, text, dialogCamera, action
---
--- @param ... any List of parameter
--- @return table Page Page definition
function ASP(...)
    assert(false, "Must be initalized with BriefingSystem.AddPages!");
    return {};
end

--- Simplyfied call for creating multiple choice pages.
---
--- Parameter order: [name, ] position, title, text, dialogCamera, action,
--- option1Text, option1Target, ...
---
--- @param ... any List of parameter
--- @return table Page Page definition
function AMC(...)
    assert(false, "Must be initalized with BriefingSystem.AddPages!");
    return {};
end

-- -------------------------------------------------------------------------- --
-- Callbacks

function GameCallback_Logic_BriefingStarted(_PlayerID, _Briefing)
end

function GameCallback_Logic_BriefingFinished(_PlayerID, _Briefing, _Abort)
end

function GameCallback_Logic_BriefingPageShown(_PlayerID, _Briefing, _PageID)
end

function GameCallback_Logic_BriefingOptionSelected(_PlayerID, _Briefing, _PageID, _OptionID, _NextPageID)
end

-- -------------------------------------------------------------------------- --
-- Internal

BriefingSystem.Internal = BriefingSystem.Internal or {
    UniqieID = 0,
    Local = {},
    Events = {},

    Data = {
        Fader = {},
        Book = {},
        Queue = {},
    },
}

function BriefingSystem.Internal:Install()
    Syncer.Install();
    Placeholder.Install();
    Cinematic.Install();

    if not self.IsInstalled then
        self.IsInstalled = true;

        for i= 1, GetMaxAmountOfPlayer() do
            self.Data.Book[i] = nil;
            self.Data.Queue[i] = {};
        end
        self:CreateScriptEvents();
        self:OverrideBriefingFunctions();

        self.Job = Job.Second(function()
            BriefingSystem.Internal:ControlBriefing();
        end);
    end
end

function BriefingSystem.Internal:CreateScriptEvents()
    -- Player pressed escape
    self.Events.PostEscapePressed = Syncer.CreateEvent(function(_PlayerID)
        if BriefingSystem.Internal:IsBriefingActive(_PlayerID) then
            if BriefingSystem.Internal:CanPageBeSkipped(_PlayerID) then
                BriefingSystem.Internal:NextPage(_PlayerID, false);
            end
        end
    end);

    -- Multiple choice option selected
    self.Events.PostOptionSelected = Syncer.CreateEvent(function( _PlayerID, _PageID, _OptionID)
        if BriefingSystem.Internal:IsBriefingActive(_PlayerID) then
            local Briefing = BriefingSystem.Internal.Data.Book[_PlayerID];
            local Page = Briefing[_PageID];
            if Page then
                if Page.MC then
                    for k, v in pairs(Page.MC) do
                        if v and v.ID == _OptionID then
                            local NextPageID = 0;
                            if type(v[2]) == "function" then
                                NextPageID = BriefingSystem.Internal:GetPageID(v[2](v), _PlayerID) -1;
                            else
                                NextPageID = BriefingSystem.Internal:GetPageID(v[2], _PlayerID) -1;
                            end
                            BriefingSystem.Internal.Data.Book[_PlayerID].Page = NextPageID;
                            BriefingSystem.Internal.Data.Book[_PlayerID][_PageID].MC.Selected = _OptionID;
                            GameCallback_Logic_BriefingOptionSelected(_PlayerID, Briefing, _PageID, _OptionID, NextPageID);
                            BriefingSystem.Internal:NextPage(_PlayerID, false);
                            return;
                        end
                    end
                end
            end
        end
    end);
end

function BriefingSystem.Internal:OverrideBriefingFunctions()
    self.Orig_GameCallback_Logic_PlayerEscape = GameCallback_Logic_PlayerEscape;
    GameCallback_Logic_PlayerEscape = function(_PlayerID)
        if BriefingSystem.Internal:IsBriefingActive(_PlayerID) then
            Syncer.InvokeEvent(BriefingSystem.Internal.Events.PostEscapePressed);
            return false;
        end
        return true;
    end

    BriefingMCButtonSelected = function(_Selected)
        BriefingSystem.Internal:BriefingMCButtonSelected(_Selected);
    end
end

function BriefingSystem.Internal:AddPages(_Briefing)
    local AP = function(_Page)
        if _Page == nil then
            _Page = -1;
        end
        if type(_Page) == "table" then
            -- Transmute some fields
            if _Page.CloseUp ~= nil then
                _Page.DialogCamera = _Page.CloseUp == true;
            end
            if _Page.Flight ~= nil then
                _Page.CameraFlight = _Page.Flight == true;
            end
            if _Page.NoSkip ~= nil then
                _Page.DisableSkipping = _Page.NoSkip == true;
            end
            -- Fader pages must be automatic
            if _Page.FadeIn then
                _Page.Duration = _Page.Duration or _Page.FadeIn;
                _Page.DisableSkipping = true;
            end
            if _Page.FadeOut then
                _Page.Duration = _Page.Duration or _Page.FadeOut;
                _Page.DisableSkipping = true;
            end
            -- Lock MC pages
            if _Page.MC then
                _Page.DisableSkipping = true;
                _Page.Duration = nil;
                for i= 1, table.getn(_Page.MC) do
                    _Page.MC[i].ID = _Page.MC[i].ID or i;
                end
            end
        end
        table.insert(_Briefing, _Page);
        return _Page;
    end

    -- Creates a simple dialog page.
    --
    -- Parameter order: [name, ] position, title, text, dialogCamera, action
    --
    -- @param ... Page arguments
    -- @return[type=table] Created page
    local ASP = function(...)
        -- Add invalid page name
        if type(arg[5]) ~= "boolean" then
            table.insert(arg, 1, -1);
        end
        -- Add default action
        if arg[6] == nil then
            ---@diagnostic disable-next-line: assign-type-mismatch, duplicate-set-field
            arg[6] = function() end;
        elseif type(arg[6]) ~= "function" then
            table.insert(arg, 6, function() end);
        end
        -- Create short page
        local Page = AP {
            Name         = arg[1],
            Target       = arg[2],
            Title        = arg[3],
            Text         = arg[4],
            DialogCamera = arg[5],
            Action       = arg[6],
        };
        --- @diagnostic disable-next-line: inject-field
        Page.Explore   = 0;
        --- @diagnostic disable-next-line: inject-field
        Page.MiniMap   = false;
        --- @diagnostic disable-next-line: inject-field
        Page.RenderFoW = false;
        --- @diagnostic disable-next-line: inject-field
        Page.RenderSky = true;
        --- @diagnostic disable-next-line: inject-field
        Page.Signal    = false;
        return Page;
    end

    -- Creates a simple multiple choice page.
    --
    -- Parameter order: [name, ] position, title, text, dialogCamera, action,
    -- option1Text, option1Target, ...
    --
    -- @param ... Page arguments
    -- @return[type=table] Created page
    local AMC = function(...)
        -- Add invalid page name
        if type(arg[5]) ~= "boolean" then
            table.insert(arg, 1, -1);
        end
        -- Add default action
        if arg[6] == nil then
            ---@diagnostic disable-next-line: assign-type-mismatch, duplicate-set-field
            arg[6] = function() end;
        elseif type(arg[6]) ~= "function" then
            table.insert(arg, 6, function() end);
        end
        -- Create short page
        local Page = AP {
            Name         = arg[1],
            Target       = arg[2],
            Title        = arg[3],
            Text         = arg[4],
            DialogCamera = arg[5],
            Action       = arg[6],
            MC           = {}
        };
        --- @diagnostic disable-next-line: inject-field
        Page.Explore   = 0;
        --- @diagnostic disable-next-line: inject-field
        Page.MiniMap   = false;
        --- @diagnostic disable-next-line: inject-field
        Page.RenderFoW = false;
        --- @diagnostic disable-next-line: inject-field
        Page.RenderSky = true;
        --- @diagnostic disable-next-line: inject-field
        Page.Signal    = false;

        local AnswerID = 1;
        for i= 7, table.getn(arg), 2 do
            --- @diagnostic disable-next-line: undefined-field
            table.insert(Page.MC, {ID = AnswerID, arg[i], arg[i+1]});
            AnswerID = AnswerID +1;
        end
        return Page;
    end
    return AP, ASP, AMC;
end

function BriefingSystem.Internal:IsBriefingActive(_PlayerID)
    local PlayerID = _PlayerID or GUI.GetPlayerID();
    return self.Data.Book[PlayerID] ~= nil;
end

function BriefingSystem.Internal:IsPlayerWatching(_PlayerID, _WatchingID)
    if self:IsBriefingActive(_PlayerID) then
        local Data = self.Data.Book[_PlayerID];
        return Data and Data.IsSpectated and IsInTable(_WatchingID, Data.Watchers);
    end
    return false;
end

function BriefingSystem.Internal:IsBriefingActiveForAnyPlayer()
    for PlayerID = 1, GetMaxAmountOfPlayer() do
        if self:IsBriefingActive(PlayerID) then
            return true;
        end
    end
    return false;
end

function BriefingSystem.Internal:StartBriefing(_PlayerID, _BriefingName, _Briefing, ...)
    -- Just to be sure...
    self:Install();
    -- watchers mode
    _Briefing.Watchers = {};
    if arg and table.getn(arg) > 0 then
        _Briefing.IsSpectated = true;
        for i= 1, table.getn(arg) do
            if arg[i] ~= 17 and arg[i] ~= _PlayerID then
                table.insert(_Briefing.Watchers, arg[i]);
            end
        end
    end
    -- Abort if event can not be created
    if not Cinematic.Define(_PlayerID, _BriefingName) then
        return;
    end
    -- Insert in Queue
    table.insert(self.Data.Queue[_PlayerID], {_BriefingName, CopyTable(_Briefing)});
    -- Start briefing if possible
    if Cinematic.IsAnyActive(_PlayerID) then
        return;
    end
    self:NextBriefing(_PlayerID);
    return true;
end

function BriefingSystem.Internal:EndBriefing(_PlayerID, _Abort)
    local Data = self.Data.Book[_PlayerID];
    -- Disable cinematic mode
    for i= 1, BriefingSystem.MCButtonAmount, 1 do
        XGUIEng.ShowWidget("CinematicMC_Button" ..i, 0);
    end
    -- Destroy explorations
    for k, v in pairs(Data.Exploration) do
        DestroyEntity(v);
    end
    -- Register briefing as finished
    local BriefingName = Data.ID;
    Cinematic.Conclude(_PlayerID, BriefingName);
    -- Call finished
    if self.Data.Book[_PlayerID].Finished then
        self.Data.Book[_PlayerID]:Finished(_Abort);
    end
    -- Call game callback
    GameCallback_Logic_BriefingFinished(_PlayerID, Data, _Abort);
    -- Hide cinematic
    Cinematic.Hide(_PlayerID);
    -- End briefing for watchers
    if Data.IsSpectated and Data.Watchers then
        for _, WatchingID in pairs(Data.Watchers) do
            if self:IsPlayerWatching(_PlayerID, WatchingID) then
                if Cinematic.IsActive(WatchingID, BriefingName) then
                    Cinematic.Conclude(WatchingID, BriefingName);
                    Cinematic.Hide(WatchingID);
                end
            end
        end
    end
    -- Invalidate briefing
    self.Data.Book[_PlayerID] = nil;
    -- Dequeue next briefing
    if self.Data.Queue[_PlayerID] and table.getn(self.Data.Queue[_PlayerID]) > 0 then
        local NewBriefing = table.remove(self.Data.Queue[_PlayerID], 1);
        self:StartBriefing(_PlayerID, NewBriefing[1], NewBriefing[2]);
    end
end

function BriefingSystem.Internal:NextBriefing(_PlayerID)
    if not self.Data.Queue[_PlayerID] then
        return;
    end
    local Briefing = table.remove(self.Data.Queue[_PlayerID], 1);

    self.Data.Book[_PlayerID]             = CopyTable(Briefing[2]);
    self.Data.Book[_PlayerID].Exploration = {};
    self.Data.Book[_PlayerID].ID          = Briefing[1];
    self.Data.Book[_PlayerID].PlayerID    = _PlayerID;
    self.Data.Book[_PlayerID].Page        = 0;

    local Data = self.Data.Book[_PlayerID];

    -- Calculate duration and height
    for k, v in pairs(Data) do
        if type(v) == "table" then
            if v.Target then
                self.Data.Book[_PlayerID][k].Position = GetPosition(v.Target);
            end
            self.Data.Book[_PlayerID][k] = self:AdjustBriefingPageCamHeight(v);
            if not v.Duration then
                local Text = v.Text or "";
                if type(Text) == "table" then
                    Text = Text.de or "";
                end
                local TextLength = (string.len(Text) +60) * BriefingSystem.TimerPerChar;
                local Duration   = v.Duration or TextLength;
                self.Data.Book[_PlayerID][k].Duration = Duration;
            else
                self.Data.Book[_PlayerID][k].Duration = v.Duration * 10;
            end
        end
    end

    -- Register briefing as active
    Cinematic.Activate(_PlayerID, Data.ID);
    -- Call function on start
    if Data.Starting then
        Data:Starting();
    end
    -- Call game callback
    GameCallback_Logic_BriefingStarted(_PlayerID, Data);
    -- Show cinematic
    Cinematic.Show(_PlayerID, Data.RestoreCamera, true);
    -- Start briefing for watchers
    if Data.IsSpectated and Data.Watchers then
        for _, WatchingID in pairs(Data.Watchers) do
            if self:IsPlayerWatching(_PlayerID, WatchingID) then
                if not Cinematic.IsAnyActive(WatchingID) then
                    Cinematic.Activate(WatchingID, Data.ID);
                    Cinematic.Show(WatchingID, Data.RestoreCamera, true);
                end
            end
        end
    end
    -- Show nex page
    self:NextPage(_PlayerID, true);
end

function BriefingSystem.Internal:NextPage(_PlayerID, _FirstPage)
    -- Check briefing exists
    if not self.Data.Book[_PlayerID] then
        return;
    end
    -- Increment page
    self.Data.Book[_PlayerID].Page = self.Data.Book[_PlayerID].Page +1;
    -- End briefing if page does not exist
    local PageID = self.Data.Book[_PlayerID].Page;
    local Page   = self.Data.Book[_PlayerID][PageID];
    if not Page then
        self:EndBriefing(_PlayerID);
        return;
    elseif type(Page) ~= "table" then
        self.Data.Book[_PlayerID].Page = self:GetPageID(Page, _PlayerID) -1;
        self:NextPage(_PlayerID, false);
        return;
    end
    -- Set start time
    self.Data.Book[_PlayerID][PageID].StartTime = Round(Logic.GetCurrentTurn());
    -- Create exploration entity
    if Page.Target and Page.Explore and Page.Explore > 0 then
        local Position = GetPosition(Page.Target);
        local ID = Logic.CreateEntity(Entities.XD_ScriptEntity, Position.X, Position.Y, 0, _PlayerID);
        Logic.SetEntityExplorationRange(ID, math.ceil(Page.Explore/100));
        table.insert(self.Data.Book[_PlayerID].Exploration, ID);
        -- TODO: Exploration for other players
    end
    -- Stop Speech
    Stream.Stop();
    -- Start Fader
    self:InitalizeFaderForBriefingPage(_PlayerID, Page);
    -- Render the page
    self:RenderPage(_PlayerID);
end

function BriefingSystem.Internal:CanPageBeSkipped(_PlayerID)
    local PlayerID = GUI.GetPlayerID();
    local Data = self.Data.Book[_PlayerID];
    -- Skipping is disabled for the briefing
    if not Data or Data.DisableSkipping then
        return false;
    end
    -- Only local/leading player can skip
    if PlayerID ~= _PlayerID and not self:IsPlayerWatching(_PlayerID, PlayerID) then
        return false;
    end

    local PageID = Data.Page;
    if Data[PageID] then
        -- Skipping is disabled for the current page
        if Data[PageID].DisableSkipping then
            return false;
        end
        -- Multiple choice can not be skipped
        if Data[PageID].MC then
            return false;
        end
        -- 0.5 seconds must have passed between two page skips
        if math.abs(Data[PageID].StartTime - Logic.GetCurrentTurn()) < 5 then
            return false;
        end
    end
    -- Page can be skipped
    return true;
end

function BriefingSystem.Internal:GetPageID(_Name, _PlayerID)
    local PlayerID = _PlayerID or GUI.GetPlayerID();
    if PlayerID ~= 17 then
        -- Number is assumed valid ID
        if type(_Name) == "number" then
            return _Name;
        end
        -- Check briefing for page
        if self.Data.Book[PlayerID] then
            for i= 1, table.getn(self.Data.Book[PlayerID]), 1 do
                if type(self.Data.Book[PlayerID][i]) == "table" then
                    if self.Data.Book[PlayerID][i].Name == _Name then
                        return i;
                    end
                end
            end
        end
    end
    -- Page not found
    return -1;
end

function BriefingSystem.Internal:RenderPage(_PlayerID)
    local PlayerID = GUI.GetPlayerID();
    -- Check page exists
    if not self.Data.Book[_PlayerID] then
        return;
    end
    local Data = self.Data.Book[_PlayerID];
    local Page = Data[self.Data.Book[_PlayerID].Page];
    if not Page then
        return;
    end
    -- Call page action for all players
    if Page.Action then
        Page:Action(Data);
    end
    -- Invoke game callback
    GameCallback_Logic_BriefingPageShown(_PlayerID, Data, Page);
    -- Only for local player
    if _PlayerID ~= GUI.GetPlayerID() and not self:IsPlayerWatching(_PlayerID, PlayerID) then
        return;
    end
    -- Render signal
    if Page.Target and Page.Signal then
        local Position = GetPosition(Page.Target);
        GUI.ScriptSignal(Position.X, Position.Y, 0);
    end

    Cinematic.Internal:SetPageStyle(
        Page.MiniMap ~= true,
        (Page.MC and table.getn(Page.MC)) or 0,
        (BriefingSystem.MCButtonAmount > 2 and 2)
            or Data.PageStyle
            or 1
    );

    local RenderFoW = (Data.RenderFoW and 1) or (Page.RenderFoW and 1) or 0;
    local RenderSky = (Data.RenderSky and 1) or (Page.RenderSky and 1) or 0;
    Display.SetRenderFogOfWar(RenderFoW);
    Display.SetRenderSky(RenderSky);
    Camera.ScrollUpdateZMode(0);
    Camera.FollowEntity(0);

    if Page.Target then
        local EntityID = GetID(Page.Target);

        if not Page.CameraFlight then
            local Rotation = Logic.GetEntityOrientation(EntityID);
            Camera.StopCameraFlight();
            if Logic.IsSettler(EntityID) == 1 then
                Rotation = Rotation +90;
                Camera.FollowEntity(EntityID);
            elseif Logic.IsBuilding(EntityID) == 1 then
                Rotation = Rotation -90;
                Camera.ScrollSetLookAt(Page.Position.X, Page.Position.Y);
            else
                Camera.ScrollSetLookAt(Page.Position.X, Page.Position.Y);
            end
            if Page.DialogCamera then
                Camera.ZoomSetDistance(Page.Distance or BriefingSystem.DialogZoomDistance);
                Camera.ZoomSetAngle(Page.Angle or BriefingSystem.DialogZoomAngle);
            else
                Camera.ZoomSetDistance(Page.Distance or BriefingSystem.BriefingZoomDistance);
                Camera.ZoomSetAngle(Page.Angle or BriefingSystem.BriefingZoomAngle);
            end
            Camera.RotSetAngle(Rotation or Page.Rotation or BriefingSystem.BriefingRotationAngle);
            Camera.ZoomSetFOV(Page.FOV or BriefingSystem.FOV);
        else
            local LastPage = Data[Data.Page -1];
            if not LastPage or type(LastPage) ~= "table" then
                Camera.ScrollSetLookAt(Page.Position.X, Page.Position.Y);
                Camera.ZoomSetDistance(Page.Distance or BriefingSystem.BriefingZoomDistance);
                Camera.ZoomSetAngle(Page.Angle or BriefingSystem.BriefingZoomAngle);
                Camera.RotSetAngle(Page.Rotation or BriefingSystem.BriefingRotationAngle);
            else
                local x, y, z = Logic.EntityGetPos(GetID(LastPage.Target));
                Camera.ScrollSetLookAt(x, y);
                Camera.ZoomSetDistance(LastPage.Distance or BriefingSystem.BriefingZoomDistance);
                Camera.ZoomSetAngle(LastPage.Angle or BriefingSystem.BriefingZoomAngle);
                Camera.RotSetAngle(LastPage.Rotation or BriefingSystem.BriefingRotationAngle);

                Camera.InitCameraFlight();
                Camera.ZoomSetDistanceFlight(Page.Distance, Page.Duration/10);
                Camera.ZoomSetAngleFlight(Page.Angle, Page.Duration/10);
                Camera.RotFlight(Page.Rotation, Page.Duration/10);
                Camera.FlyToLookAt(Page.Position.X, Page.Position.Y, Page.Duration/10);
            end
            Camera.ZoomSetFOV(Page.FOV or BriefingSystem.FOV);
        end
    end

    local Title = self:GetPageHeadline(_PlayerID, Data.Page);
    self:PrintHeadline(_PlayerID, Title);

    local Text = self:GetPageText(_PlayerID, Data.Page);
    self:PrintText(_PlayerID, Text);

    if Page.MC then
        self:PrintOptions(_PlayerID, Data, Page);
    else
        Mouse.CursorHide();
        for i= 1, BriefingSystem.MCButtonAmount, 1 do
            XGUIEng.ShowWidget("CinematicMC_Button" ..i, 0);
        end
    end
end

--- @diagnostic disable-next-line: duplicate-set-field
function BriefingSystem.Internal:GetPageHeadline(_PlayerID, _PageID)
    local PlayerID = GUI.GetPlayerID();
    if self:IsBriefingActive(_PlayerID) then
        local Page = self.Data.Book[_PlayerID][_PageID];
        if self:IsPlayerWatching(_PlayerID, PlayerID) then
            if Page.TitleAlter then
                return Page.TitleAlter;
            end
        end
        if Page.Title then
            return Page.Title;
        end
    end
    return "";
end

--- @diagnostic disable-next-line: duplicate-set-field
function BriefingSystem.Internal:GetPageText(_PlayerID, _PageID)
    local PlayerID = GUI.GetPlayerID();
    if self:IsBriefingActive(_PlayerID) then
        local Page = self.Data.Book[_PlayerID][_PageID];
        if self:IsPlayerWatching(_PlayerID, PlayerID) then
            if Page.TextAlter then
                return Page.TextAlter;
            end
        end
        if Page.Text then
            return Page.Text;
        end
    end
    return "";
end

function BriefingSystem.Internal:BriefingMCButtonSelected(_Selected)
    local PlayerID = GUI.GetPlayerID();
    if PlayerID ~= 17 then
        Syncer.InvokeEvent(
            self.Events.PostOptionSelected,
            self.Data.Book[PlayerID].Page,
            _Selected
        );
    end
end

function BriefingSystem.Internal:ControlBriefing()
    for PlayerID= 1, GetMaxAmountOfPlayer() do
        if self.Data.Book[PlayerID] then
            -- Check page exists
            local PageID = self.Data.Book[PlayerID].Page;
            if not self.Data.Book[PlayerID][PageID] then
                return false;
            end
            -- Stop briefing
            if type(self.Data.Book[PlayerID][PageID]) == nil then
                self:EndBriefing(PlayerID);
                return false;
            end
            -- HACK: fix MC buttons
            -- (Dosen't work on display for some reason)
            for j= 1, BriefingSystem.MCButtonAmount, 1 do
                XGUIEng.DisableButton("CinematicMC_Button" ..j, 1);
                XGUIEng.DisableButton("CinematicMC_Button" ..j, 0);
            end
            -- Jump to page
            if type(self.Data.Book[PlayerID][PageID]) ~= "table" then
                self.Data.Book[PlayerID].Page = self:GetPageID(self.Data.Book[PlayerID][PageID], PlayerID) -1;
                self:NextPage(PlayerID, self.Data.Book[PlayerID].Page > 0);
                return false;
            end
            -- Next page after duration is up
            local TimePassed = Logic.GetCurrentTurn() - self.Data.Book[PlayerID][PageID].StartTime;
            if not self.Data.Book[PlayerID][PageID].MC and TimePassed > self.Data.Book[PlayerID][PageID].Duration then
                self:NextPage(PlayerID, false);
            end
        end
    end
end

---
-- Fakes camera hight on the unusable Z-achis. This function must be called
-- after all camera calculations are done.
-- @param[type=table] _Page Briefing page
-- @return[type=table] Page
-- @within BriefingSystem
-- @local
--
function BriefingSystem.Internal:AdjustBriefingPageCamHeight(_Page)
    if _Page.Position then
        -- Set defaults
        _Page.Angle = _Page.Angle or ((_Page.DialogCamera and BriefingSystem.DialogZoomAngle) or BriefingSystem.BriefingZoomAngle);
        _Page.Rotation = _Page.Rotation or ((_Page.DialogCamera and BriefingSystem.DialogRotationAngle) or BriefingSystem.BriefingRotationAngle);
        _Page.Distance = _Page.Distance or ((_Page.DialogCamera and BriefingSystem.DialogZoomDistance) or BriefingSystem.BriefingZoomDistance);
        -- Set height
        if Logic.IsSettler(GetID(_Page.Target)) == 1 then
            _Page.Height = _Page.Height or BriefingSystem.FakeHeight;
        else
            _Page.Height = _Page.Height or 0;
        end
        if _Page.Angle >= 90 then
            _Page.Height = 0;
        end

        if _Page.Height > 0 and _Page.Angle > 0 and _Page.Angle < 90 then
            local AngleTangens = _Page.Height / math.tan(math.rad(_Page.Angle));
            local RotationRadiant = math.rad(_Page.Rotation or -45);
            -- Save backup for when page is visited again
            if not _Page.PositionOriginal then
                _Page.PositionOriginal = CopyTable(_Page.Position);
            end

            -- New position
            local NewPosition = {
                X = _Page.PositionOriginal.X - math.sin(RotationRadiant) * AngleTangens,
                Y = _Page.PositionOriginal.Y + math.cos(RotationRadiant) * AngleTangens
            };
            -- Update if valid position
            if NewPosition.X > 0 and NewPosition.Y > 0 and NewPosition.X < Logic.WorldGetSize() and NewPosition.Y < Logic.WorldGetSize() then
                -- Save backup for when page is visited again
                if not _Page.ZoomOriginal then
                    _Page.ZoomOriginal = _Page.Distance;
                end
                _Page.Distance = _Page.ZoomOriginal + math.sqrt(math.pow(_Page.Height, 2) + math.pow(AngleTangens, 2));
                _Page.Position = NewPosition;
            end
        end
    end
    return _Page;
end

function BriefingSystem.Internal:PrintHeadline(_PlayerID, _Text)
    local PlayerID = GUI.GetPlayerID();
    if _PlayerID ~= PlayerID and not self:IsPlayerWatching(_PlayerID, PlayerID) then
        return;
    end
    -- Create local copy of text
    local Text = Localize(_Text);
    -- Add title format
    if not string.find(string.sub(Text, 1, 2), "@") then
        Text = "@center " ..Text;
    end
    -- Replace placeholders
    Text = Placeholder.Replace(Text);

    XGUIEng.SetText("CinematicMC_Headline", Text or "");
end

function BriefingSystem.Internal:PrintText(_PlayerID, _Text)
    local PlayerID = GUI.GetPlayerID();
    if _PlayerID ~= PlayerID and not self:IsPlayerWatching(_PlayerID, PlayerID) then
        return;
    end
    -- Create local copy of text
    local Text = Localize(_Text);
    -- Replace placeholders
    Text = Placeholder.Replace(Text);

    XGUIEng.SetText("CinematicMC_Text", Text or "");
end

function BriefingSystem.Internal:PrintOptions(_PlayerID, _Briefing, _Page)
    local PlayerID = GUI.GetPlayerID();
    if _Page.MC then
        if _PlayerID == PlayerID then
            -- Display choices normally
            Mouse.CursorShow();
            for i= 1, table.getn(_Page.MC), 1 do
                if BriefingSystem.MCButtonAmount >= i then
                    -- Fix buttons (doesn't work here)
                    XGUIEng.DisableButton("CinematicMC_Button" ..i, 1);
                    XGUIEng.DisableButton("CinematicMC_Button" ..i, 0);
                    -- Set text
                    local Text = Localize(_Page.MC[i][1]);
                    Text = Placeholder.Replace(Text);
                    XGUIEng.SetText("CinematicMC_Button" ..i, Text or "");
                end
            end
        elseif self:IsPlayerWatching(_PlayerID, PlayerID) then
            -- Add the option to hide choices so that a player is stuck on the
            -- choice page until external intervention
            Mouse.CursorHide();
            for i= 1, table.getn(_Page.MC), 1 do
                if BriefingSystem.MCButtonAmount >= i then
                    XGUIEng.ShowWidget("CinematicMC_Button" ..i, 0);
                end
            end
        end
    end
end

function BriefingSystem.Internal:InitalizeFaderForBriefingPage(_PlayerID, _Page)
    if _Page then
        self.Data.Fader[_PlayerID] = {};
        if _Page.FaderAlpha then
            self:StopFader(_PlayerID);
            self:SetFaderAlpha(_PlayerID, _Page.FaderAlpha);
        else
            if not _Page.FadeIn and not _Page.FadeOut then
                self:StopFader(_PlayerID);
                self:SetFaderAlpha(_PlayerID, 0);
            end
            if _Page.FadeIn then
                self:StopFader(_PlayerID);
                self:StartFader(_PlayerID, _Page.FadeIn, true);
            end
            if _Page.FadeOut then
                local Waittime = (Logic.GetTime() + (_Page.Duration/10)) - _Page.FadeOut;
                self:StartFaderDelayed(_PlayerID, Waittime, _Page.FadeOut, false);
            end
        end
    end
end

function BriefingSystem.Internal:StartFader(_PlayerID, _Duration, _FadeIn)
    self.Data.Fader[_PlayerID].FadeInJob = Job.Turn(
        function(_PlayerID, _Duration, _StartTime, _FadeIn)
            return BriefingSystem.Internal:FaderVisibilityController(_PlayerID, _Duration, _StartTime, _FadeIn)
        end,
        _PlayerID,
        _Duration * 1000,
        Logic.GetTimeMs(),
        _FadeIn == true
    );
    self:SetFaderAlpha(_PlayerID, (_FadeIn == true and 1) or 0);
end

function BriefingSystem.Internal:StartFaderDelayed(_PlayerID, _Waittime, _Duration, _FadeIn)
    self.Data.Fader[_PlayerID].FadeOutJob = Job.Turn(
        function(_PlayerID, _Duration, _StartTime, _FadeIn)
            return BriefingSystem.Internal:FaderDelayController(_PlayerID, _Duration, _StartTime, _FadeIn)
        end,
        _PlayerID,
        _Duration,
        _Waittime * 1000,
        _FadeIn == true
    );
end

function BriefingSystem.Internal:StopFader(_PlayerID)
    if not self.Data.Fader[_PlayerID] then
        return;
    end
    if self.Data.Fader[_PlayerID].FadeInJob and JobIsRunning(self.Data.Fader[_PlayerID].FadeInJob) then
        EndJob(self.Data.Fader[_PlayerID].FadeInJob);
        self.Data.Fader[_PlayerID].FadeInJob = nil;
    end
    if self.Data.Fader[_PlayerID].FadeOutJob and JobIsRunning(self.Data.Fader[_PlayerID].FadeOutJob) then
        EndJob(self.Data.Fader[_PlayerID].FadeOutJob);
        self.Data.Fader[_PlayerID].FadeOutJob = nil;
    end
end

function BriefingSystem.Internal:SetFaderAlpha(_PlayerID, _AlphaFactor)
    local PlayerID = GUI.GetPlayerID();
    if PlayerID ~= _PlayerID and not self:IsPlayerWatching(_PlayerID, PlayerID) then
        return;
    end
    local AlphaFactor = _AlphaFactor;

    local FaderWidget = "CinematicBar00";
    if XGUIEng.IsWidgetExisting("CinematicFader") == 1 then
        FaderWidget = "CinematicFader";
    end
    if XGUIEng.IsWidgetShown("Cinematic") == 1 then
        AlphaFactor = (AlphaFactor > 1 and 1) or AlphaFactor;
        AlphaFactor = (AlphaFactor < 0 and 0) or AlphaFactor;

        local sX, sY = GUI.GetScreenSize();
        XGUIEng.SetWidgetPositionAndSize(FaderWidget, 0, 0, sX, sY);
        XGUIEng.SetMaterialTexture(FaderWidget, 0, "");
        XGUIEng.ShowWidget(FaderWidget, 1);
        XGUIEng.SetMaterialColor(FaderWidget, 0, 0, 0, 0, math.floor(255 * AlphaFactor));
    end
end

function BriefingSystem.Internal:GetFadingFactor(_PlayerID, _StartTime, _Duration, _FadeIn)
    if self:IsBriefingActive(_PlayerID) == false then
        return 0;
    end
    local CurrentTime = Logic.GetTimeMs();
    local FadingFactor = (CurrentTime - _StartTime) / _Duration;
    FadingFactor = (FadingFactor > 1 and 1) or FadingFactor;
    FadingFactor = (FadingFactor < 0 and 0) or FadingFactor;
    if _FadeIn then
        FadingFactor = 1 - FadingFactor;
    end
    return FadingFactor;
end

function BriefingSystem.Internal:FaderVisibilityController(_PlayerID, _Duration, _StartTime, _FadeIn)
    if self:IsBriefingActive(_PlayerID) == false then
        return true;
    end
    if Logic.GetTimeMs() > _StartTime + _Duration then
        return true;
    end
    self:SetFaderAlpha(_PlayerID, self:GetFadingFactor(_PlayerID, _StartTime, _Duration, _FadeIn));
    return false;
end

function BriefingSystem.Internal:FaderDelayController(_PlayerID, _Duration, _StartTime, _FadeIn)
    if self:IsBriefingActive(_PlayerID) == false then
        return true;
    end
    if Logic.GetTimeMs() > _StartTime then
        self:StopFader(_PlayerID);
        self:StartFader(_PlayerID, _Duration, _FadeIn);
        return true;
    end
    return false;
end

