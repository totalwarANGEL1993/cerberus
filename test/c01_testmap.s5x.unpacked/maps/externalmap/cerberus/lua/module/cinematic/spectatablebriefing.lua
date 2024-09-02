Lib.Require("comfort/IsInTable");
Lib.Require("module/cinematic/BriefingSystem");
Lib.Register("module/cinematic/SpectatableBriefing");

--- 
--- Spectatable Briefing
--- 
--- This addition to the Briefing System enables the user to create briefings
--- that can be watched by other players.
--- 
--- - One player must be the leading player
--- - The leading player can skip pages.
--- - Other players are watching but can't change the briefing state
--- - Other players can not skip pages and must wait for the leading player
--- - Other players can not select options of multiple choice pages and must
---   wait until the leading player has made a decision
--- 
--- Version 1.0.0
--- 

SpectatableBriefing = SpectatableBriefing or {}

-- -------------------------------------------------------------------------- --
-- API

--- Starts a briefing for a player.
---
--- This method follows the same rules as the one in BriefingSystem.
---
--- Additionally a list of players can be defined that only watching the
--- briefing but can not interact with it.
---
--- @param _PlayerID number     Player the briefing is started for
--- @param _BriefingName string Name of Briefing (must be unique for player)
--- @param _Briefing table      Definition of briefing
--- @param ... number           List of spectating players
--- @see BriefingSystem.Start
function SpectatableBriefing.Start(_PlayerID, _BriefingName, _Briefing, ...)
    -- Transmute some fields
    if _Briefing.NoSkip ~= nil then
        _Briefing.DisableSkipping = _Briefing.NoSkip == true;
    end
    if _Briefing.ResetCamera ~= nil then
        _Briefing.RestoreCamera = _Briefing.ResetCamera == true;
    end

    SpectatableBriefing.Internal:StartBriefing(_PlayerID, _BriefingName, _Briefing, unpack(arg));
end

--- Creates a page from the page definition.
--- 
--- Fields to configure:
--- * Name       - Name of Page
--- * Title      - Headline of the page
--- * Text       - Text of the page
--- * TitleAlter - Headline shown to a spectating player.
--- * TextAlter  - Text shown to a spectating player.
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

-- -------------------------------------------------------------------------- --
-- Internal

SpectatableBriefing.Internal = SpectatableBriefing.Internal or {}

function SpectatableBriefing.Internal:Install()
    if not self.IsInstalled then
        self.IsInstalled = true;

        self:OverwriteGetPageHeadline();
        self:OverwriteGetPageText();
        self:OverwriteBriefingTickCallback();
        self:OverwritePageShownCallback();
        self:OverwriteOptionSelectedCallback();
    end
end

function SpectatableBriefing.Internal:StartBriefing(_PlayerID, _BriefingName, _Briefing, ...)
    SpectatableBriefing.Internal:Install();

    -- Setup spectating players
    _Briefing.IsSpectatable = true;
    _Briefing.LeaderPlayerID = _PlayerID;
    _Briefing.Watchers = {};
    for i= 1, table.getn(arg) do
        ---@diagnostic disable-next-line: param-type-mismatch
        if arg[i] ~= _PlayerID and not Cinematic.IsAnyActive(arg[i]) then
            table.insert(_Briefing.Watchers, arg[i]);
        end
    end

    -- Start all briefing instances
    BriefingSystem.Internal:StartBriefing(_PlayerID, _BriefingName, _Briefing);
    for i= 1, table.getn(_Briefing.Watchers) do
        local Briefing = CopyTable(_Briefing);
        Briefing.IsReadOnly = true;
        Briefing.DisableSkipping = true;
        Briefing.Watchers = {};
        BriefingSystem.Internal:StartBriefing(_Briefing.Watchers[i], _BriefingName, Briefing);
    end
end

-- Skips page for spectators if leader has skipped a page.
function SpectatableBriefing.Internal:NextPageForSpactators(_PlayerID, _Briefing)
    -- Check if briefing is spectatable and leader is player
    if _Briefing and _Briefing.IsSpectatable and _Briefing.LeaderPlayerID == _PlayerID then
        -- Skip page for all spectators
        for i = 1, table.getn(_Briefing.Watchers) do
            local SpectatorID = _Briefing.Watchers[i];
            local Data = BriefingSystem.Internal.Data.Book[SpectatorID];
            if Data and Data.IsSpectatable and _Briefing.LeaderPlayerID == _PlayerID then
                local FirstPage = _Briefing.Page == 1;
                BriefingSystem.Internal.Data.Book[SpectatorID].Page = _Briefing.Page -1;
                BriefingSystem.Internal:NextPage(SpectatorID, FirstPage);
            end
        end
    end
end

-- Aborts briefing if leading player leaves.
-- This is to prevent soft locks in vanilla multiplayer.
function SpectatableBriefing.Internal:AbortBriefingOnHostDisconnet(_PlayerID, _Briefing, _PageID)
    -- Multiplayer not on community server must abort on disconnect
    if Syncer.IsMultiplayer() and not CNetwork then
        if _Briefing.IsSpectatable and _Briefing.IsReadOnly then
            if Logic.PlayerGetGameState(_Briefing.LeadingPlayerID) == 4 then
                -- Ends Briefing with abort flag
                -- (Must be handeled by user)
                BriefingSystem.Internal:EndBriefing(_PlayerID, true);
                return false;
            end
        end
    end
    return true;
end

function SpectatableBriefing.Internal:OverwriteBriefingTickCallback()
    self.Orig_GameCallback_Logic_BriefingTick = GameCallback_Logic_BriefingTick;
    GameCallback_Logic_BriefingTick = function(_PlayerID, _Briefing, _PageID)
        if not SpectatableBriefing.Internal:AbortBriefingOnHostDisconnet(_PlayerID, _Briefing, _PageID) then
            return false;
        end
        return SpectatableBriefing.Internal.Orig_GameCallback_Logic_BriefingTick(_PlayerID, _Briefing, _PageID);
    end
end

function SpectatableBriefing.Internal:OverwritePageShownCallback()
    self.Orig_GameCallback_Logic_BriefingFinished = GameCallback_Logic_BriefingFinished;
    GameCallback_Logic_BriefingFinished = function(_PlayerID, _Briefing, _Abort)
        SpectatableBriefing.Internal.Orig_GameCallback_Logic_BriefingFinished(_PlayerID, _Briefing, _Abort);
        SpectatableBriefing.Internal:NextPageForSpactators(_PlayerID, _Briefing);
    end

    self.Orig_GameCallback_Logic_BriefingPageShown = GameCallback_Logic_BriefingPageShown;
    GameCallback_Logic_BriefingPageShown = function(_PlayerID, _Briefing, _PageID)
        SpectatableBriefing.Internal.Orig_GameCallback_Logic_BriefingPageShown(_PlayerID, _Briefing, _PageID);
        SpectatableBriefing.Internal:NextPageForSpactators(_PlayerID, _Briefing);
    end
end

function SpectatableBriefing.Internal:OverwriteOptionSelectedCallback()
    self.Orig_GameCallback_Logic_BriefingOptionSelected = GameCallback_Logic_BriefingOptionSelected;
    GameCallback_Logic_BriefingOptionSelected = function(_PlayerID, _Briefing, _PageID, _OptionID, _NextPageID)
        SpectatableBriefing.Internal.Orig_GameCallback_Logic_BriefingOptionSelected(_PlayerID, _Briefing, _PageID, _OptionID, _NextPageID);
        if _Briefing and _Briefing.IsSpectatable then
            for _, PlayerID in pairs(_Briefing.Watchers) do
                if BriefingSystem.Internal.Data.Book[PlayerID] then
                    BriefingSystem.Internal.Data.Book[PlayerID].Page = _NextPageID;
                    BriefingSystem.Internal:NextPage(PlayerID, false);
                end
            end
        end
    end
end

function SpectatableBriefing.Internal:OverwriteGetPageHeadline()
    ---@diagnostic disable-next-line: duplicate-set-field
    BriefingSystem.Internal.GetPageHeadline = function(self, _PlayerID, _PageID)
        if self:IsBriefingActive(_PlayerID) then
            local Page = self.Data.Book[_PlayerID][_PageID];
            -- Alternate spectator text
            if self.Data.Book[_PlayerID].IsSpectatable then
                if self.Data.Book[_PlayerID].IsReadOnly and Page.TitleAlter then
                    return Page.TitleAlter;
                end
            end
            -- Normal text
            if Page.Title then
                return Page.Title;
            end
        end
        return "";
    end
end

function SpectatableBriefing.Internal:OverwriteGetPageText()
    ---@diagnostic disable-next-line: duplicate-set-field
    BriefingSystem.Internal.GetPageText = function(self, _PlayerID, _PageID)
        if self:IsBriefingActive(_PlayerID) then
            local Page = self.Data.Book[_PlayerID][_PageID];
            -- Alternate spectator text
            if self.Data.Book[_PlayerID].IsSpectatable then
                if self.Data.Book[_PlayerID].IsReadOnly and Page.TextAlter then
                    return Page.TextAlter;
                end
            end
            -- Normal text
            if Page.Text then
                return Page.Text;
            end
        end
        return "";
    end
end

