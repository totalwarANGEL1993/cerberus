Lib.Require("comfort/GetLanguage");
Lib.Require("module/lua/Overwrite");
Lib.Register("module/ui/Clock");

--- 
--- Game Speed Button
---
--- Implements the clock button from THE SETTLERS - Rise of an Empire that
--- changes the game speed. This script overwrites the online help button
--- and replaces it with something useful.
---
--- Can not be used in multiplayer!
--- 
--- Version 1.0.0
--- 

Clock = Clock or {};

-- -------------------------------------------------------------------------- --
-- API

--- Install the feature.
--- (Must be called on game start.)
function Clock.Install()
    Clock.Internal:Install();
end

--- Resets the game speed to 1.
function Clock.Reset()
    Clock.Internal:ResetGameSpeed();
end

--- Allows to change the game speed.
function Clock.Allow()
    Clock.Internal:SetSpeedUpAllowed(true);
end

--- Forbids to change the game speed.
---
--- If the speed was increased it is automatically reset to 1.
function Clock.Forbid()
    Clock.Internal:SetSpeedUpAllowed(false);
end

-- -------------------------------------------------------------------------- --
-- Internal

Clock.Internal = Clock.Internal or {
    Data = {
        SpeedUpAllowed = true,
        SpeedLimit = 3,
        CurrentSpeed = 1,
    },
};

function Clock.Internal:Install()
    if not self.IsInstalled then
        self.IsInstalled = true;

        Overwrite.Install();
        self:SetSpeedUpAllowed(XNetwork.Manager_DoesExist() == 0);
        XGUIEng.TransferMaterials("StatisticsWindowTimeScaleButton", "OnlineHelpButton");
        XGUIEng.SetWidgetPositionAndSize("OnlineHelpButton",200,2,35,35);
        self:OverwriteOnlineHelp();
    end
end

function Clock.Internal:SetSpeedLimit(_Limit)
    if XNetwork.Manager_DoesExist() == 0 then
        _Limit = (_Limit >= 1 and _Limit) or 1;
        if self.Data.CurrentSpeed > _Limit then
            Game.GameTimeSetFactor(_Limit);
            self.Data.CurrentSpeed = _Limit;
        end
        self.Data.SpeedLimit = _Limit;
    end
end

function Clock.Internal:SetSpeedUpAllowed(_Flag)
    if XNetwork.Manager_DoesExist() == 0 then
        self.Data.SpeedUpAllowed = _Flag == true;
        if _Flag == false then
            self:ResetGameSpeed();
        end
    end
end

function Clock.Internal:ResetGameSpeed()
    if XNetwork.Manager_DoesExist() == 0 then
        self.Data.CurrentSpeed = 1;
        Game.GameTimeSetFactor(1);
    end
end

function Clock.Internal:IncrementSpeed()
    if XNetwork.Manager_DoesExist() == 0 then
        self.Data.CurrentSpeed = self.Data.CurrentSpeed +1;
        if self.Data.CurrentSpeed > self.Data.SpeedLimit then
            self.Data.CurrentSpeed = 1;
        end
        Game.GameTimeSetFactor(self.Data.CurrentSpeed);
    end
end

function Clock.Internal:OnSaveGameLoaded()
    XGUIEng.TransferMaterials("StatisticsWindowTimeScaleButton", "OnlineHelpButton");
    XGUIEng.SetWidgetPositionAndSize("OnlineHelpButton",200,2,35,35);
    Game.GameTimeSetFactor(1);
    self.Data.CurrentSpeed = 1;
end

function Clock.Internal:OnGameSpeedChanged(_Speed)
    if _Speed == 0 then
        XGUIEng.ShowWidget("PauseScreen", 1);
    else
        XGUIEng.ShowWidget("PauseScreen", 0);
        self.Data.CurrentSpeed = _Speed;
    end
end

function Clock.Internal:OverwriteOnlineHelp()
    GUIAction_OnlineHelp = function()
        Clock.Internal:IncrementSpeed();
    end

    GameCallback_GameSpeedChanged = function(_Speed)
        Clock.Internal:OnGameSpeedChanged(_Speed);
    end

    self.Orig_Mission_OnSaveGameLoaded = Mission_OnSaveGameLoaded;
    Mission_OnSaveGameLoaded = function()
        Clock.Internal.Orig_Mission_OnSaveGameLoaded();
        Clock.Internal:OnSaveGameLoaded();
    end

    Overwrite.CreateOverwrite(
        "GUITooltip_Generic", function(_Key)
            Overwrite.CallOriginal();
            if _Key == "MenuMap/OnlineHelp" then
                local Tooltip = Clock.Internal:GetTooltipText();
                XGUIEng.SetText(gvGUI_WidgetID.TooltipBottomText, Tooltip);
                XGUIEng.SetText(gvGUI_WidgetID.TooltipBottomCosts, "");
                XGUIEng.SetText(gvGUI_WidgetID.TooltipBottomShortCut, "");
            end
        end
    );
end

function Clock.Internal:GetTooltipText()
    local Title = {de = "@color:180,180,180 Spielgeschwindigkeit ändern @color:255,255,255 @cr ",
                   en = "@color:180,180,180 Change game speed @color:255,255,255 @cr "};
    local Text  = {de = "Die Geschwindigkeit kann nicht geändert werden!",
                   en = "The game speed can not be changed!"}
    if Clock.Internal.Data.SpeedUpAllowed then
        Text.de = "Erhöht die Spielgeschwindigkeit bis zum Limit oder setzt sie zurück. @cr (Aktuell: %d / %d)";
        Text.en = "Increases the game speed up to the limit or resets it back to normal. @cr (Current: %d / %d)";
    end

    local Lang = GetLanguage();
    return Title[Lang] .. string.format(
        Text[Lang],
        Clock.Internal.Data.CurrentSpeed,
        Clock.Internal.Data.SpeedLimit
    );
end

