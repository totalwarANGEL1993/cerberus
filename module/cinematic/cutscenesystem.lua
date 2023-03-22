Lib.Require("comfort/Round");
Lib.Require("module/cinematic/Cinematic");
Lib.Require("module/ui/Placeholder");
Lib.Require("module/mp/Syncer");
Lib.Require("module/trigger/Job");
Lib.Register("module/cinematic/CutsceneSystem");

--- 
--- Cutscene System
---
--- THIS IS EXPERIMENTAL!
--- 
--- Implements a system to display cutscenes.
--- 
--- @author totalwarANGEL
--- @version 1.0.0
--- 

CutsceneSystem = CutsceneSystem or {}

-- -------------------------------------------------------------------------- --
-- API

---
-- Starts the passed cutscene As cinematic event.
--
-- @param[type=number] _PlayerID ID of Player
-- @param[type=number] _Name     Name of cutscene
-- @param[type=table]  _Cutscene Cutscene description
-- @within Methods
--
function CutsceneSystem.Start(_PlayerID, _Name, _Cutscene)
    CutsceneSystem.Internal:StartCutscene(_PlayerID, _Name, _Cutscene);
end

---
-- Returns true if a cutscene is active for the player. If no player was
-- passed, the local player is checked.
--
-- @param[type=number] _PlayerID (Optional) ID of player
-- @return[type=boolean] Cutscene is active
-- @within Methods
--
function CutsceneSystem.IsActive(_PlayerID)
    return CutsceneSystem.Internal:IsCutsceneActive(_PlayerID);
end

-- -------------------------------------------------------------------------- --
-- Internal

CutsceneSystem.Internal = CutsceneSystem.Internal or {
    UniqieID = 0,
    Local = {},
    Events = {},

    Data = {
        Fader = {},
        Book = {},
        Queue = {},
    },
}

function CutsceneSystem.Internal:Install()
    Syncer.Install();
    Placeholder.Install();
    Cinematic.Install();

    if not self.IsInstalled then
        self.IsInstalled = true;
        for i= 1, table.getn(Score.Player) do
            self.Data.Book[i] = nil;
            self.Data.Queue[i] = {};
        end
        self:CreateScriptEvents();

    end
end

function CutsceneSystem.Internal:CreateScriptEvents()
    self.Event.CutsceneStarted = Syncer.CreateEvent(function(_PlayerID)
        CutsceneSystem.Internal:CutsceneStarted(_PlayerID);
    end);
    self.Event.CutsceneFinished = Syncer.CreateEvent(function(_PlayerID)
        CutsceneSystem.Internal:CutsceneFinished(_PlayerID);
    end);
    self.Event.PageDisplayed = Syncer.CreateEvent(function(_PlayerID)
        CutsceneSystem.Internal:NextPage(_PlayerID);
    end);
end

function CutsceneSystem.Internal:StartCutscene(_PlayerID, _CutsceneName, _Data)
    -- Abort if event can not be created
    if not Cinematic.Define(_PlayerID, _CutsceneName) then
        return;
    end
    -- Insert in m_Queue
    table.insert(self.Data.Queue[_PlayerID], {_CutsceneName, _Data});
    -- Start cutscene if possible
    if Cinematic.IsAnyActive(_PlayerID) then
        return;
    end
    self:NextCutscene(_PlayerID);
end

function CutsceneSystem.Internal:NextCutscene(_PlayerID)
    if not self.Data.Queue[_PlayerID] then
        return;
    end
    local Cutscene = table.remove(self.Data.Queue[_PlayerID], 1);
    Cutscene.CurrentPage = 0;

    _G["Cutscene_" ..Cutscene[1].. "_Start"] = _G["Cutscene_" ..Cutscene[1].. "_Start"] or function()
        Syncer.InvokeEvent(CutsceneSystem.Internal.Events.CutsceneStarted);
    end
    _G["Cutscene_" ..Cutscene[1].. "_Finished"] = _G["Cutscene_" ..Cutscene[1].. "_Finished"] or function()
        Syncer.InvokeEvent(CutsceneSystem.Internal.Events.CutsceneFinished);
    end
    _G["Cutscene_" ..Cutscene[1].. "_Cancel"] = _G["Cutscene_" ..Cutscene[1].. "_Cancel"] or function()
        _G["Cutscene_" ..Cutscene[1].. "_Finished"]();
    end
    for i= 1, table.getn(Cutscene[2]) do
        _G["Cutscene_" ..Cutscene[1].. "_" ..Cutscene[2][i].Flight] = _G["Cutscene_" ..Cutscene[1].. "_" ..Cutscene[2][i].Flight] or function()
            Syncer.InvokeEvent(CutsceneSystem.Internal.Events.PageDisplayed);
        end
    end

    self.Data.Book[_PlayerID] = CopyTable(Cutscene);
    if GUI.GetPlayerID() ~= _PlayerID then
        return;
    end
    StartCutscene(Cutscene[1]);
end

function CutsceneSystem.Internal:CutsceneStarted(_PlayerID)
    Cinematic.Activate(_PlayerID, self.m_Book[_PlayerID][1]);
    if self.Data.Book[_PlayerID][2].Starting then
        self.Data.Book[_PlayerID][2]:Starting();
    end
    -- Enable cinematic mode
    Cinematic.Show(_PlayerID, self.Data.Book[_PlayerID].RestoreCamera, true);
end

function CutsceneSystem.Internal:CutsceneFinished(_PlayerID)
    Cinematic.Conclude(_PlayerID, self.m_Book[_PlayerID][1]);
    if self.Data.Book[_PlayerID][2].Finished then
        self.Data.Book[_PlayerID][2]:Finished();
    end
    -- Disable cinematic mode
    Cinematic.Hide(_PlayerID);
end

function CutsceneSystem.Internal:NextPage(_PlayerID)
    self.Data.Book[_PlayerID][2].CurrentPage = self.Data.Book[_PlayerID][2].CurrentPage +1;

    local PageID = self.Data.Book[_PlayerID][2].CurrentPage;
    local Page = self.Data.Book[_PlayerID][2][PageID];
    if Page.Action then
        Page:Action();
    end

    if GUI.GetPlayerID() ~= _PlayerID then
        return;
    end
    local Title = Page.Title;
    PrintBriefingHeadline(Title);
    local Text  = Page.Text;
    PrintBriefingHeadline(Text);

    Cinematic.Internal:SetPageStyle(false, 0, 3);

    -- Fader?
end

