--[[
Library/Cerberus_0_Core/Source

Copyright (C) 2022 totalwarANGEL - All Rights Reserved.

This file is part of Cerberus. Cerberus is created by totalwarANGEL.
You may use and modify this file unter the terms of the MIT licence.
(See https://en.wikipedia.org/wiki/MIT_License)
]]

Cerberus                = {};
Cerberus.Version        = "1.0.0";
Cerberus.Modules        = {};
Cerberus.EventListener  = {};
Cerberus.Events         = {};

Cerberus.Connectors     = {
    -- Any connector is deactivated by typing nil.

    -- Load the implementation for the hook
    -- * s5hook     -> Original S5Hook by yoq
    -- * cpplogic   -> CppLogic by mcb
    S5Hook              = "s5hook",
};

QSB.ScriptEvents = QSB.ScriptEvents or {};

-- -------------------------------------------------------------------------- --

function Cerberus:Install()
    self:OverrideSaveGameLoaded();
    self:InitEvents();
    self:InitModules();
    self:InitConnectors();
end

function Cerberus:OverrideSaveGameLoaded()
    if MultiplayerTools then
        Mission_OnSaveGameLoaded_Orig_Cerberus_Core = MultiplayerTools.OnSaveGameLoaded;
        MultiplayerTools.OnSaveGameLoaded = function()
            Mission_OnSaveGameLoaded_Orig_Cerberus_Core();
            Cerberus:OnSaveGameLoaded();
        end
    else
        Mission_OnSaveGameLoaded_Orig_Cerberus_Core = Mission_OnSaveGameLoaded;
        Mission_OnSaveGameLoaded = function()
            Mission_OnSaveGameLoaded_Orig_Cerberus_Core();
            Cerberus:OnSaveGameLoaded();
        end
    end
end

function Cerberus:OnSaveGameLoaded()
    self:RestoreConnectors();
    self:DispatchScriptEvent(QSB.ScriptEvents.SaveGameLoaded);
end

-- -------------------------------------------------------------------------- --

-- TODO DEBUG

-- -------------------------------------------------------------------------- --

function Cerberus:InitModules()
    for i= 1, table.getn(self.Modules), 1 do
        if self.Modules[i].OnGameStart then
            self.Modules[i]:OnGameStart();
        end
    end
end

function Cerberus:RegisterModule(_Module)
    if (type(_Module) ~= "table") then
        assert(false, "Modules must be tables!");
        return;
    end
    if _Module.Properties == nil or _Module.Properties.Name == nil then
        assert(false, "Expected name for Module!");
        return;
    end
    table.insert(self.Modules, _Module);
end

function Cerberus:IsModuleRegistered(_Name)
    for k, v in pairs(self.Modules) do
        return v.Properties and v.Properties.Name == _Name;
    end
end

-- -------------------------------------------------------------------------- --

function Cerberus:InitConnectors()
    for k, v in pairs(self.Connectors) do
        local Path = gvBasePath.. "qsb/connector/" ..string.lower(k).. "/" ..v".lua";
        Script.Load(Path);
        if _G[k.. "Connector"] then
            if _G[k.. "Connector"].OnGameStart then
                _G[k.. "Connector"]:OnGameStart();
            end
        else
            GUI.AddStaticNote("Connector \""..k.. ":" ..v.. "\" not found!");
        end
    end
end

function Cerberus:RestoreConnectors()
    for k, v in pairs(self.Connectors) do
        if _G[k.. "Connector"] then
            if _G[k.. "Connector"].OnSaveGameLoaded then
                _G[k.. "Connector"]:OnSaveGameLoaded();
            end
        else
            GUI.AddStaticNote("Connector \""..k.. ":" ..v.. "\" not found!");
        end
    end
end

-- -------------------------------------------------------------------------- --

function Cerberus:InitEvents()
    QSB.ScriptEvents.SaveGameLoaded = self:CreateScriptEvent("Event_SaveGameLoaded");
    QSB.ScriptEvents.LanguageSet = self:CreateScriptEvent("Event_LanguageSet");
end

function Cerberus:CreateScriptEvent(_Name)
    for i= 1, table.getn(self.Events), 1 do
        if self.Events[i] == _Name then
            return 0;
        end
    end
    local ID = table.getn(self.Events)+1;
    self.Events[ID] = _Name;
    return ID;
end

function Cerberus:DispatchScriptEvent(_ID, ...)
    if not self.Events[_ID] then
        return;
    end
    -- Dispatch module events
    for i= 1, table.getn(self.Modules), 1 do
        if self.Modules[i] and self.Modules[i].OnEvent then
            self.Modules[i]:OnEvent(_ID, unpack(arg));
        end
    end
    -- Call event callback
    if GameCallback_QSB_OnEventReceived then
        GameCallback_QSB_OnEventReceived(_ID, unpack(arg));
    end
    -- Call event listeners
    if self.EventListener[_ID] then
        for k, v in pairs(self.EventListener[_ID]) do
            if tonumber(k) then
                v(_ID, unpack(arg));
            end
        end
    end
end

-- -------------------------------------------------------------------------- --

function Cerberus:GetExtensionNumber()
    local Version = Framework.GetProgramVersion();
    local extensionNumber = tonumber(string.sub(Version, string.len(Version))) or 0;
    return extensionNumber;
end

