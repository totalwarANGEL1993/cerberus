Lib.Require("comfort/GetLanguage");
Lib.Require("comfort/CopyTable");
Lib.Require("module/trigger/Job");
Lib.Require("module/ui/Placeholder");
Lib.Register("module/tutorial/Tutorial");

---
--- Tutorial script
---
--- An simple tutorial script. It allows to display tutorial text in the message
--- window. Texts can either be skipped by pressing enter or automatically if a
--- condition is fulfilled.
---
--- While a tutorial is running messages can not be added to the screen unless
--- GUI.AddStaticNote is used.
---
--- Version 1.0.3
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
--- Fields:
--- * Text        Text to print
--- * Arrow       (Optional) Position of arrow
--- * ArrowWidget (Optional) Name of widget used for the arrow
--- * Condition   (Optional) Next page condition function
--- * Action      (Optional) Page display action function
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
            es = "(Continuar con Enter)",
            fr = "(Continuez avec Entrer)",
            it = "(Prosegui con Invio)",
            pl = "(Kontynuuj za pomocą Enter)",
            ru = "(Prodolzhit' nazhatiyem Enter",
        }
    },
};

function Tutorial.Internal:Install()
    if not self.IsInstalled then
        self.m_Language = GetLanguage();
        self.Data.ContinueText = self.Text.ContinueText[self.m_Language];
        self:OverwriteMessageFunctions();
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
        self:OverwriteMessageFunctions();
        self:PrintTutorialMessage();
        self:ShowTutorialBackground();
        self:ActivateHotkey();
    end
end

function Tutorial.Internal:Start()
    self.Data.Iterator = 1
    self.Data.Running = true;

    GUI.ClearNotes();
    self:ShowTutorialBackground();
    self:ActivateHotkey();
    self:PrintTutorialMessage();
    self:ActivateNextPageTrigger();
end

function Tutorial.Internal:Stop()
    GUI.ClearNotes();
    self:HideTutorialArrow();
    self:HideTutorialBackground();

    self.Data.Iterator = 0
    self.Data.Running = false;
    self.Data.Messages = {};
    if self.Data.Callback then
        self.Data:Callback();
        self.Data.Callback = nil;
    end
end

function Tutorial.Internal:OverwriteMessageFunctions()
    self.Orig_GUI_AddNote = GUI.AddNote;
    GUI.AddNote = function(_Text)
        if not Tutorial.Internal.Data.Running then
            Tutorial.Internal.Orig_GUI_AddNote(_Text);
        end
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
    if string.find(_Page.Text, "^[A-Za-z0-9_]+/[A-Za-z0-9_]+$") then
        _Page.Text = XGUIEng.GetStringTableText(_Page.Text);
    end
    -- Add continuation text
    if not _Page.Condition then
        _Page.Text = Placeholder.Replace(_Page.Text).. " @cr @color:66,206,244 " ..self.Data.ContinueText;
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
    self:ShowTutorialArrow();
    -- Call action
    if self.Data.Messages[self.Data.Iterator].Action then
        self.Data.Messages[self.Data.Iterator].Action(self.Data.Messages[self.Data.Iterator]);
    end
end

function Tutorial.Internal:OnEnterPressed()
    if self.Data.Running then
        local Iterator = self.Data.Iterator;
        if not self.Data.Messages[Iterator].Trigger then
            -- Continue to next page
            self:HideTutorialArrow();
            self.Data.Iterator = Iterator +1;
            self:ActivateNextPageTrigger();
            self:PrintTutorialMessage();
        end
    end
end

function Tutorial.Internal:ActivateNextPageTrigger()
    if self.Data.Running then
        local Iterator = self.Data.Iterator;
        -- Start condition job of next page
        if self.Data.Messages[Iterator] then
            if self.Data.Messages[Iterator].Condition then
                if not self.Data.Messages[Iterator].Trigger then
                    self.Data.Messages[Iterator].Trigger = Job.Second(function()
                        return Tutorial.Internal:NextPageTrigger();
                    end);
                end
            end
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
        self:HideTutorialArrow();
        self.Data.Iterator = self.Data.Iterator +1;
        self:ActivateNextPageTrigger();
        self:PrintTutorialMessage();
        return true;
    end
end

function Tutorial.Internal:ShowTutorialArrow()
    local Data = self.Data.Messages[self.Data.Iterator];
    local Widget = Data.ArrowWidget or "TutorialArrow";
    if Data and Data.Arrow then
        local Position = self.Data.Messages[self.Data.Iterator].Arrow;
        XGUIEng.SetWidgetPosition(Widget, Position[1], Position[2]);
        XGUIEng.SetWidgetSize(Widget, 30, 30);
        XGUIEng.ShowWidget(Widget, 1);
    end
end

function Tutorial.Internal:HideTutorialArrow()
    local Data = self.Data.Messages[self.Data.Iterator];
    if Data then
        local Widget = Data.ArrowWidget or "TutorialArrow";
        XGUIEng.ShowWidget(Widget, 0);
    end
end

function Tutorial.Internal:ShowTutorialBackground()
    XGUIEng.ShowWidget("TutorialMessageBG", 1);
end

function Tutorial.Internal:HideTutorialBackground()
    XGUIEng.ShowWidget("TutorialMessageBG", 0);
end

function Tutorial.Internal:ActivateHotkey()
    Input.KeyBindDown(Keys.Enter, "Tutorial.Internal:OnEnterPressed()", 2);
end

