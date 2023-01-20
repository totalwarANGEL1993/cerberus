Lib.Require("module/archive/S5Hook");
Lib.Register("module/archive/Archive");

---
--- Archive Loader
---
--- If the map is in S5X format the archive is automatically loaded on game
--- start and automatically unloaded when leaving the game.
---
--- If the map is a folder nothing happens.
---
--- Also some common functions that are both available in the original hook
--- and in the community server API are provided.
---
--- @author totalwarANGEL
--- @version 1.0.0
---

Archive = {}

-- -------------------------------------------------------------------------- --
-- API

--- Installs the archive loader.
--- (Must be called on game start!)
function Archive.Install()
    Archive.Internal:Install();
end

--- Changes a string from the string table to a new value.
--- (Must be repeated after savegame is loaded.)
--- @param _Key string  Key to change 
--- @param _Text string New text  
function Archive.ChangeString(_Key, _Text)
    if Archive.Internal.Data.HookType == 1 then
        CUtil.SetStringTableText(_Key, _Text);
    elseif Archive.Internal.Data.HookType == 2 then
        Archive.ChangeString(_Key, _Text);
    end
end

--- Changes the display name of the entity.
--- (Must be repeated after savegame is loaded.)
--- @param _Entity string Entity to change
--- @param _Text string   Display name
function Archive.ChangeName(_Entity, _Text)
    if Archive.Internal.Data.HookType == 1 then
        CUtil.SetEntityDisplayName(GetID(_Entity), _Text);
    elseif Archive.Internal.Data.HookType == 2 then
        Archive.Internal.Data.Names = Archive.Internal.Data.Names or {};
        Archive.Internal.Data.Names[_Entity] = _Text;
        Archive.SetCustomNames(Archive.Internal.Data.Names);
    end
end

--- Reloads the GUI XML from the path.
--- (Must be repeated after savegame is loaded.)
--- @param _Path string Path to XML
function Archive.ReloadGUI(_Path)
    if Archive.Internal.Data.HookType == 1 then
        CUtil.LoadGUI(_Path);
    elseif Archive.Internal.Data.HookType == 2 then
        Archive.LoadGUI(_Path);
    end
end

--- Returns the X and Y position of the widget.
--- @param _Name string Name of widget
--- @return number X X position of widget
--- @return number Y Y position of widget
function Archive.GetWidgetPosition(_Name)
    if Archive.Internal.Data.HookType == 1 then
        return CWidget.GetPosition(XGUIEng.GetWidgetID(_Name));
    elseif Archive.Internal.Data.HookType == 2 then
        return Archive.GetWidgetPosition(_Name);
    end
    return 0, 0;
end

--- Returns the width and the height of the widget.
--- @param _Name string Name of widget
--- @return number Width Widht of widget
--- @return number Height Height of widget
function Archive.GetWidgetSize(_Name)
    if Archive.Internal.Data.HookType == 1 then
        return CWidget.GetSize(XGUIEng.GetWidgetID(_Name));
    elseif Archive.Internal.Data.HookType == 2 then
        return Archive.GetWidgetSize(_Name);
    end
    return 0, 0;
end

--- Reloads the definition of all entities.
--- (Files can be overwritten file by putting them in the right path.)
function Archive.ReloadEntities()
    if Archive.Internal.Data.HookType == 1 then
        CEntity.ReloadEntities();
    elseif Archive.Internal.Data.HookType == 2 then
        Archive.ReloadEntities();
    end
end

--- Changes the motivation of the settler.
--- (1.0 = 100%)
--- @param _Entity     number Entity to change
--- @param _Motivation number Motivation
function Archive.SetSettlerMotivation(_Entity, _Motivation)
    if Archive.Internal.Data.HookType == 1 then
        CEntity.SetMotivation(GetID(_Entity), _Motivation);
    elseif Archive.Internal.Data.HookType == 2 then
        Archive.SetSettlerMotivation(GetID(_Entity), _Motivation);
    end
end

--- Creates a projectile that deals damage.
--- @param _Effect   number ID of Effect
--- @param _X1       number Start Position X
--- @param _Y1       number Start Position Y
--- @param _X2       number End Position X
--- @param _Y2       number End Position Y
--- @param _Dmg      number Damage
--- @param _AoE      number Area of effect
--- @param _Target   number ID of target
--- @param _Attacker number ID of attacker
function Archive.CreateProjectile(_Effect, _X1, _Y1, _X2, _Y2, _Dmg, _AoE, _Target, _Attacker)
    if Archive.Internal.Data.HookType == 1 then
        local PlayerID = Logic.EntityGetPlayer(_Attacker);
        CUtil.CreateProjectile(_Effect, _X1, _Y1, _X2, _Y2, _Dmg, _AoE, _Target, _Attacker, PlayerID);
    elseif Archive.Internal.Data.HookType == 1 then
        Archive.CreateProjectile(_Effect, _X1, _Y1, _X2, _Y2, _Dmg, _AoE, _Target, _Attacker);
    end
end

-- -------------------------------------------------------------------------- --
-- Game Callback

--- Called after the map archive has been loaded.
--- (Archive is loaded when starting the game or loading a savegame.)
function GameCallback_Logic_AfterMapLoaded()
end

--- Called before the map archive is unloaded.
--- (Archive is unloaded when closing the game or loading another savegame.)
function GameCallback_Logic_BeforeMapUnloaded()
end

-- -------------------------------------------------------------------------- --
-- Internal

Archive.Internal = {
    Data = {
        HookType = 0;
    }
}

function Archive.Internal:Install()
    self:InitRestoreAfterLoad();
    self:InitAutomaticMapArchiveUnload();
    self:OverrideFrameworkRestartMap();
    self:DetectHookType();
    if self.Data.HookType == -1 then
        Message("Installing Hook failed. You propably run an incompatible game version!");
        return;
    end
    self:LoadHook();
end

function Archive.Internal:InitRestoreAfterLoad()
    Mission_OnSaveGameLoaded = Mission_OnSaveGameLoaded or function() end
	self.Orig_Mission_OnSaveGameLoaded = Mission_OnSaveGameLoaded;
	Mission_OnSaveGameLoaded = function()
		Archive.Internal:OnSavegameLoaded();
	end
end

function Archive.Internal:OnSavegameLoaded()
    self:OverrideFrameworkRestartMap();
    self:DetectHookType();
    self:LoadHook();
end

function Archive.Internal:DetectHookType()
    if self.Data.HookType == 0 then
        self.Data.HookType = (CMod and 1) or 2;
        if XNetwork.Manager_IsNATReady ~= nil then
            self.Data.HookType = -1;
        end
        if not string.find(Framework.GetProgramVersion(), "1.06.0217") then
            self.Data.HookType = -1;
        end
    end
end

function Archive.Internal:LoadHook()
    if self.Data.HookType > 0 then
        self:LoadSettlers5Hook();
        self:CommunityServerLoadArchive();
        self:Settlers5HookLoadArchive();
    end
end

function Archive.Internal:UnloadHook()
    if self.Data.HookType > 0 then
        self:CommunityServerUnloadArchive();
        self:Settlers5HookUnloadArchive();
        self:UnloadSettlers5Hook();
    end
end

function Archive.Internal:OverrideFrameworkRestartMap()
    self.Orig_FrameworkRestartMap = Framework.RestartMap;
    Framework.RestartMap = function()
        Archive.Internal:UnloadHook();
        Archive.Internal.Orig_FrameworkRestartMap();
    end
end

function Archive.Internal:InitAutomaticMapArchiveUnload()
    self.Orig_GUIAction_RestartMap = GUIAction_RestartMap;
    GUIAction_RestartMap = function()
        Archive.Internal:UnloadHook();
        Archive.Internal.Orig_GUIAction_RestartMap();
    end

    self.Orig_QuitGame = QuitGame;
    QuitGame = function()
        Archive.Internal:UnloadHook();
        Archive.Internal.Orig_QuitGame();
    end

    self.Orig_QuitApplication = QuitApplication;
    QuitApplication = function()
        Archive.Internal:UnloadHook();
        Archive.Internal.Orig_QuitApplication();
    end

    self.Orig_QuickLoad = QuickLoad;
    QuickLoad = function()
        Archive.Internal:UnloadHook();
        Archive.Internal.Orig_QuickLoad();
    end

    self.Orig_MainWindow_LoadGame_DoLoadGame = MainWindow_LoadGame_DoLoadGame;
    MainWindow_LoadGame_DoLoadGame = function(_Slot)
        Archive.Internal:UnloadHook();
        Archive.Internal.Orig_MainWindow_LoadGame_DoLoadGame(_Slot);
    end
end

-- Community Server Hook --

function Archive.Internal:CommunityServerLoadArchive()
    if self.Data.HookType == 1 then
        local MapName = Framework.GetCurrentMapName() .. ".s5x";
        local TopArchive = CMod.GetAllArchives();
        if not TopArchive or not string.find(TopArchive, "s5x") then
            CMod.PushArchive(MapName);
        end
        GameCallback_Logic_AfterMapLoaded();
    end
end

function Archive.Internal:CommunityServerUnloadArchive()
    if self.Data.HookType == 1 then
        GameCallback_Logic_BeforeMapUnloaded();
        local TopArchive = CMod.GetAllArchives();
        if TopArchive and string.find(TopArchive, "s5x") then
            CMod.PopArchive();
        end
    end
end

-- Settlers5Hook --

function Archive.Internal:LoadSettlers5Hook()
    if self.Data.HookType == 2 then
        InstallS5Hook();
    end
end

function Archive.Internal:UnloadSettlers5Hook()
    if self.Data.HookType == 2 then
        Trigger.DisableTriggerSystem(1);
    end
end

function Archive.Internal:Settlers5HookLoadArchive()
    if self.Data.HookType == 2 then
        local TopArchive = Archive.GetTopArchive();
        if not TopArchive or not string.find(TopArchive, "s5x") then
            Archive.AddArchive();
        end
        GameCallback_Logic_AfterMapLoaded();
    end
end

function Archive.Internal:Settlers5HookUnloadArchive()
    if self.Data.HookType == 2 then
        GameCallback_Logic_BeforeMapUnloaded();
        local TopArchive = Archive.GetTopArchive()
        if TopArchive and string.find(TopArchive, "s5x") then
            Archive.RemoveArchive();
        end
    end
end

