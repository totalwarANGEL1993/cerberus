--[[
Connector/S5Hook/CppLogic

Copyright (C) 2022 totalwarANGEL - All Rights Reserved.

This file is part of Cerberus. Cerberus is created by totalwarANGEL.
You may use and modify this file unter the terms of the MIT licence.
(See https://en.wikipedia.org/wiki/MIT_License)
]]

S5HookConnector = {
    Data = {
        IsInstalled = false
    }
};

function S5HookConnector:OnGameStart()
    if not CppLogic or not CppLogic.Logic.ReloadCutscene then
        GUI.AddStaticNote("ERROR: Can not find CppLogic!");
        return;
    end
    self:OverwriteMapClosingFunctions();
end

function S5HookConnector:OnSaveGameLoad()
    CppLogic_ResetGlobal();
    if not CppLogic.Logic.ReloadCutscene then
        GUI.AddStaticNote("ERROR: Can not find CppLogic!");
        return;
    end
    if string.find(Folders.Map, "externalmap") then
        CppLogic.Logic.ReloadCutscene();
    else
        CppLogic.Logic.ReloadCutscene(Folders.Map);
    end
end

function S5HookConnector:UnloadS5Hook()
    if not CppLogic.OnLeaveMap then
        Message("ERROR: Can not find CppLogic!");
        return;
    end
    if Cerberus:GetExtensionNumber() <= 2 and CppLogic then
        if string.find(Folders.Map, "externalmap") then
            CppLogic.Logic.RemoveTopArchive();
        end
        CppLogic.OnLeaveMap();
        Trigger.DisableTriggerSystem(1);
    end
end

function S5HookConnector:OverwriteMapClosingFunctions()
    if Cerberus:GetExtensionNumber() <= 2 then
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
    Message("Cpp Logic is used.");
end

function S5HookConnector.WriteToLog(_Text)
    CppLogic.API.Log(_Text);
end

function S5HookConnector.Execute(_Lua)
    CppLogic.API.Eval(_Lua);
end

