--[[
Connector/S5Hook/S5Hook

Copyright (C) 2022 totalwarANGEL - All Rights Reserved.

This file is part of Cerberus. Cerberus is created by totalwarANGEL.
You may use and modify this file unter the terms of the MIT licence.
(See https://en.wikipedia.org/wiki/MIT_License)
]]

Script.Load(gvBasePath.. "qsb/external/s5hook.lua");

S5HookConnector = {
    Data = {
        IsInstalled = false
    }
};

function S5HookConnector:OnGameStart()
    if not InstallS5Hook() then
        return;
    end
    self:OverwriteMapClosingFunctions();

    local ExtraFolder = "extra1";
    if Cerberus:GetExtensionNumber() > 1 then
        ExtraFolder = "extra2";
    end
    if Cerberus:GetExtensionNumber() > 2 then
        ExtraFolder = "extra3";
    end
    S5Hook.AddArchive(ExtraFolder.. "/shr/maps/user/" ..Framework.GetCurrentMapName().. ".s5x");
    S5Hook.ReloadCutscenes();
    self.Data.IsInstalled = true;
end

function S5HookConnector:OnSaveGameLoad()
    self.Data.IsInstalled = false;
    self:Install();
end

function S5HookConnector:UnloadS5Hook()
    if Cerberus:GetExtensionNumber() <= 2 and S5Hook then
        S5Hook.RemoveArchive();
        Trigger.DisableTriggerSystem(1);
        self.Data.IsInstalled = false;
    end
end

function S5HookConnector:OverwriteMapClosingFunctions()
    if QuestTools.GetExtensionNumber() <= 2 then
        GUIAction_RestartMap_Orig_S5Hook = GUIAction_RestartMap;
        GUIAction_RestartMap = function()
            S5HookConnector:UnloadS5Hook();
            GUIAction_RestartMap_Orig_S5Hook();
        end

        QuitGame_Orig_S5Hook = QuitGame;
        QuitGame = function()
            S5HookConnector:UnloadS5Hook();
            QuitGame_Orig_S5Hook();
        end

        QuitApplication_Orig_S5Hook = QuitApplication;
        QuitApplication = function()
            S5HookConnector:UnloadS5Hook();
            QuitApplication_Orig_S5Hook();
        end

        QuickLoad_Orig_S5Hook = QuickLoad;
        QuickLoad = function()
            S5HookConnector:UnloadS5Hook();
            QuickLoad_Orig_S5Hook();
        end

        MainWindow_LoadGame_DoLoadGame_Orig_S5Hook = MainWindow_LoadGame_DoLoadGame;
        MainWindow_LoadGame_DoLoadGame = function(_Slot)
            S5HookConnector:UnloadS5Hook();
            MainWindow_LoadGame_DoLoadGame_Orig_S5Hook(_Slot);
        end
    end
end

-- -------------------------------------------------------------------------- --

function S5HookConnector.Test()
    Message("Original S5Hook is used.");
end

function S5HookConnector.WriteToLog(_Text)
    S5Hook.Log(_Text);
end

function S5HookConnector.Execute(_Lua)
    S5Hook.Eval(_Lua);
end

