Lib.Require("comfort/GetLanguage");
Lib.Require("comfort/CopyTable");
Lib.Require("module/trigger/Job");
Lib.Register("module/tutorial/Tutorial");

---
--- Tutorial script
---
--- An simple tutorial script. It allows to display tutorial text in the message
--- window. Texts can either be skipped by pressing enter or automatically if a
--- condition is fulfilled.
---
--- @author totalwarANGEL
--- @version 1.0.0
---

Tutorial = Tutorial or {};

-- -------------------------------------------------------------------------- --
-- API

--- Initalizes the tutorial script.
function Tutorial.Install()
    Tutorial.Internal:Install();
end

--- Starts the prepared tutorial.
function Tutorial.Start()
    Tutorial.Internal:Start();
end

--- Stops the currently running tutorial.
function Tutorial.Stop()
    Tutorial.Internal:Stop();
end

--- Adds a tutorial message to the tutorial.
--- 
--- A message consists of a .Text field with the text of the message, an
--- optional .Action field to perform an action when the page is shown and
--- an optional .Condition field for automatically skipping the page after
--- a condition is fulfilled.
--- 
--- @param _Page table Tutorial message
function Tutorial.AddMessage(_Page)
    Tutorial.Internal:AddMessage(_Page);
end

--- Adds an callback at the end of the tutorial.
--- @param _Function function Callback function
function Tutorial.SetCallback(_Function)
    Tutorial.Internal:SetCallback(_Function);
end

-- -------------------------------------------------------------------------- --
-- Internal

Tutorial.Internal = Tutorial.Internal or {
    Data = {
        Running = false,
        ContinueText = "",
        Messages = {},
        Iterator = 0,
    },
    Text = {
        ContinueText = {
            de = "(Weiter mit Enter)",
            en = "(Continue with return)",
        }
    },
};

function Tutorial.Internal:Install()
    if not self.IsInstalled then
        self.m_Language = GetLanguage();
        self.Data.ContinueText = self.Text.ContinueText[self.m_Language];
        self.IsInstalled = true;
    end
end

function Tutorial.Internal:InitRestoreAfterLoad()
	self.Orig_Mission_OnSaveGameLoaded = Mission_OnSaveGameLoaded;
    Mission_OnSaveGameLoaded = function()
        Tutorial.Internal.Orig_Mission_OnSaveGameLoaded();
        Tutorial.Internal:OnSaveGameLoaded();
    end
end

function Tutorial.Internal:OnSaveGameLoaded()
	if self.Data.Running then
        self:PrintTutorialMessage();
        self:DisplayTutorialBackground(true);
        self:ActivateHotkey();
    end
end

function Tutorial.Internal:Start()
    self.Data.Iterator = 1
    self.Data.Running = true;

    GUI.ClearNotes();
    self:DisplayTutorialBackground(true);
    self:ActivateHotkey();
    self:PrintTutorialMessage();
end

function Tutorial.Internal:Stop()
    GUI.ClearNotes();
    self:DisplayTutorialArrow(false);
    self:DisplayTutorialBackground(false);

    self.Data.Iterator = 0
    self.Data.Running = false;
    self.Data.Messages = {};
    if self.Data.Callback then
        self.Data:Callback();
        self.Data.Callback = nil;
    end
end

function Tutorial.Internal:SetCallback(_Function)
    self.Data.Callback = _Function;
end

function Tutorial.Internal:AddMessage(_Page)
    assert(_Page.Text);
    -- Check for multi language
    if type(_Page.Text) == "table" then
        _Page.Text = _Page.Text[self.m_Language];
    end
    -- Add continuation text
    if not _Page.Condition then
        _Page.Text = _Page.Text.. " @cr @color:66,206,244 " ..self.Data.ContinueText;
    end
    -- Add page
    table.insert(self.Data.Messages, CopyTable(_Page));
end

function Tutorial.Internal:PrintTutorialMessage()
    -- Stop if invalid
    if not self.Data.Messages[self.Data.Iterator] then
        self:Stop();
        return;
    end
    -- Display text
    GUI.ClearNotes();
    GUI.AddStaticNote(self.Data.Messages[self.Data.Iterator].Text);
    -- Display arrow
    self:DisplayTutorialArrow(self.Data.Messages[self.Data.Iterator].Arrow ~= nil);
    -- Call action
    if self.Data.Messages[self.Data.Iterator].Action then
        self.Data.Messages[self.Data.Iterator].Action(self.Data.Messages[self.Data.Iterator]);
    end
end

function Tutorial.Internal:DisplayTutorialArrow(_Flag)
    XGUIEng.ShowWidget("TutorialArrow", (_Flag and 1) or 0);
    XGUIEng.SetWidgetSize("TutorialArrow", 30, 30);
    if _Flag and self.Data.Messages[self.Data.Iterator].Arrow then
        local Position = self.Data.Messages[self.Data.Iterator].Arrow;
        XGUIEng.SetWidgetPosition("TutorialArrow", Position[1], Position[2]);
    end
end

function Tutorial.Internal:OnEnterPressed()
    if self.Data.Running then
        local Iterator = self.Data.Iterator;
        -- Start condition job of next page
        if self.Data.Messages[Iterator +1] then
            if self.Data.Messages[Iterator +1].Condition then
                if not self.Data.Messages[Iterator +1].Trigger then
                    self.Data.Messages[Iterator +1].Trigger = Job.Second(function()
                        return Tutorial.Internal:NextPageTrigger();
                    end);
                end
            end
        end
        -- Continue to next page
        if not self.Data.Messages[Iterator].Trigger then
            self.Data.Iterator = Iterator +1;
            self:PrintTutorialMessage();
        end
    end
end

function Tutorial.Internal:NextPageTrigger()
    -- Tutorial not valid
    if not self.Data.Running then
        return true;
    end
    if not self.Data.Messages[self.Data.Iterator] then
        return true;
    end
    -- No condition
    if not self.Data.Messages[self.Data.Iterator].Condition then
        self:PrintTutorialMessage();
        return true;
    end
    -- Condition fulfilled
    if self.Data.Messages[self.Data.Iterator].Condition(self.Data.Messages[self.Data.Iterator]) then
        self.Data.Messages[self.Data.Iterator].Trigger = nil;
        self.Data.Iterator = self.Data.Iterator +1;
        self:PrintTutorialMessage();
        return true;
    end
end

function Tutorial.Internal:ActivateHotkey()
    Input.KeyBindDown(Keys.Enter, "Tutorial.Internal:OnEnterPressed()", 2);
end

function Tutorial.Internal:DisplayTutorialBackground(_Flag)
    XGUIEng.ShowWidget("TutorialMessageBG", (_Flag and 1) or 0);
end

