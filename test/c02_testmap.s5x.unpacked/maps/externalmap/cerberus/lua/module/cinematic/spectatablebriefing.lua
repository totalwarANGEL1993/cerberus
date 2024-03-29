Lib.Require("comfort/IsInTable");
Lib.Require("module/cinematic/BriefingSystem");
Lib.Register("module/cinematic/SpectatableBriefing");

--- 
--- Spectatable Briefing
--- 
--- This addition to the Briefing System allows to create briefings that other
--- players can participate. But they can not change it's state.
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
        self:OverwritePageShownCallback();
    end
end

function SpectatableBriefing.Internal:StartBriefing(_PlayerID, _BriefingName, _Briefing, ...)
    SpectatableBriefing.Internal:Install();

    -- Setup spectating players
    _Briefing.IsSpectatable = true;
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
        BriefingSystem.Internal:StartBriefing(Briefing.Watchers[i], _BriefingName, Briefing);
    end
end

function SpectatableBriefing.Internal:NextPageForSpactators(_PlayerID, _PageID)
    local Briefing = BriefingSystem.Internal.Data.Book[_PlayerID];
    if not Briefing or not Briefing.IsSpectatable then
        return;
    end
    for i= 1, table.getn(Briefing.Watchers) do
        SpectatedBriefing = BriefingSystem.Internal.Data.Book[Briefing.Watchers[i]];
        if SpectatedBriefing then
            local FirstPage = SpectatedBriefing.Page == 1;
            BriefingSystem.Internal:NextPage(Briefing.Watchers[i], FirstPage);
        end
    end
end

function SpectatableBriefing.Internal:OverwritePageShownCallback()
    self.Orig_GameCallback_Logic_BriefingPageShown = GameCallback_Logic_BriefingPageShown;
    GameCallback_Logic_BriefingPageShown = function(_PlayerID, _Briefing, _PageID)
        SpectatableBriefing.Internal.Orig_GameCallback_Logic_BriefingPageShown(_PlayerID, _Briefing, _PageID);
        SpectatableBriefing.Internal:NextPageForSpactators(_PlayerID, _PageID);
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

