Lib.Require("module/cinematic/BriefingSystem");
Lib.Require("module/cinematic/CutsceneSystem");
Lib.Require("module/mp/Syncer");
Lib.Register("module/camera/FreeCam");

--- 
--- Allows to use the free camera.
---
--- Controls:
--- * CTRL + ALT + Num9 Toggle camera
--- * CTRL + Space      Activate/Deactivate free camera
--- * CTRL + R          Reset camera
--- * CTRL + E          Increase angle
--- * CTRL + Q          Decrease angle
--- * CTRL + S          Zoom out
--- * CTRL + W          Zoom in
--- * CTRL + A          Rotate left
--- * CTRL + D          Rotate right
--- * CTRL + Y          Decrease FOV
--- * CTRL + C          Increase FOV
---
--- @author totalwarANGEL
--- @version 1.0.0
---

FreeCam = FreeCam or {};

-- -------------------------------------------------------------------------- --
-- API

--- Toggles the free camera by script.
function FreeCam.Toggle()
    FreeCam.Internal:ToggleFreeCamera();
end

--- Returns if the free camera is active.
--- @return boolean Active Is active
function FreeCam.IsActive()
    return FreeCam.Internal:IsActive();
end

--- Allows to toggle the free camera with hotkey
--- @param _Flag boolean Allow toggle
function FreeCam.SetToggleable(_Flag)
    FreeCam.Internal:SetToggleable(_Flag == true);
end

--- Returns if the free camera is toggable.
--- @return boolean Toggleable Is toggleable
function FreeCam.IsToggleable()
    return FreeCam.Internal:IsAllowed();
end

-- -------------------------------------------------------------------------- --
-- Internal

FreeCam.Internal = FreeCam.Internal or {
    Data = {
        IsAllowed = false,
        IsActive = false,

        Angle = 48,
        Rotation = -45,
        Distance = 9000,
        FOV = 42,
    },
}

function FreeCam.Internal:Install()
    if not self.IsInstalled then
        self.IsInstalled = true;

        self:InitRestoreAfterLoad();
        self:OverwriteFunctions();
        self:OnSavegameLoaded();
    end
end

function FreeCam.Internal:InitRestoreAfterLoad()
	self.Orig_Mission_OnSaveGameLoaded = Mission_OnSaveGameLoaded;
	Mission_OnSaveGameLoaded = function()
		FreeCam.Internal.Orig_Mission_OnSaveGameLoaded();
		FreeCam.Internal:OnSavegameLoaded();
	end
end

function FreeCam.Internal:OverwriteFunctions()
    self.Orig_GameCallback_Logic_BriefingStarted = GameCallback_Logic_BriefingStarted;
    GameCallback_Logic_BriefingStarted = function(_PlayerID, _Briefing)
        FreeCam.Internal.Orig_GameCallback_Logic_BriefingStarted(_PlayerID, _Briefing);
        if _PlayerID == GUI.GetPlayerID() then
            if FreeCam.IsActive() then
                FreeCam.Internal:ToggleFreeCamera();
            end
        end
    end

    self.Orig_GameCallback_Logic_CutsceneStarted = GameCallback_Logic_CutsceneStarted;
    GameCallback_Logic_CutsceneStarted = function(_PlayerID, _Briefing)
        FreeCam.Internal.Orig_GameCallback_Logic_CutsceneStarted(_PlayerID, _Briefing);
        if _PlayerID == GUI.GetPlayerID() then
            if FreeCam.IsActive() then
                FreeCam.Internal:ToggleFreeCamera();
            end
        end
    end

    ---

	Camera_ToggleDefault = function()
        if FreeCam.IsToggleable() or FreeCam.IsActive() then
            if not Cinematic.IsAnyActive(GUI.GetPlayerID()) then
                FreeCam.Internal:ToggleFreeCamera();
            end
        end
    end

    Camera_DecreaseAngle = function()
        if FreeCam.IsActive() then
            FreeCam.Internal.Data.Angle = FreeCam.Internal.Data.Angle - 1;
            Camera.ZoomSetAngle(FreeCam.Internal.Data.Angle);
        end
    end

    Camera_IncreaseAngle = function()
        if FreeCam.IsActive() then
            FreeCam.Internal.Data.Angle = FreeCam.Internal.Data.Angle + 1;
            Camera.ZoomSetAngle(FreeCam.Internal.Data.Angle);
        end
    end

    Camera_DecreaseZoom = function()
        if FreeCam.IsActive() then
            FreeCam.Internal.Data.Distance = FreeCam.Internal.Data.Distance - 100;
            Camera.ZoomSetDistance(FreeCam.Internal.Data.Distance);
        end
    end

    Camera_IncreaseZoom = function()
        if FreeCam.IsActive() then
            FreeCam.Internal.Data.Distance = FreeCam.Internal.Data.Distance + 100;
            Camera.ZoomSetDistance(FreeCam.Internal.Data.Distance);
        end
    end

    Camera_DecreaseFOV = function()
        if FreeCam.IsActive() then
            FreeCam.Internal.Data.FOV = FreeCam.Internal.Data.FOV - 1;
            Camera.ZoomSetFOV(FreeCam.Internal.Data.FOV);
        end
    end

    Camera_IncreaseFOV = function()
        if FreeCam.IsActive() then
            FreeCam.Internal.Data.FOV = FreeCam.Internal.Data.FOV + 1;
            Camera.ZoomSetFOV(FreeCam.Internal.Data.FOV);
        end
    end

    Camera_RotateLeft = function()
        if FreeCam.IsActive() then
            FreeCam.Internal.Data.Rotation = FreeCam.Internal.Data.Rotation - 1;
            Camera.RotSetAngle(FreeCam.Internal.Data.Rotation);
        end
    end

    Camera_RotateRight = function()
        if FreeCam.IsActive() then
            FreeCam.Internal.Data.Rotation = FreeCam.Internal.Data.Rotation + 1;
            Camera.RotSetAngle(FreeCam.Internal.Data.Rotation);
        end
    end

    Camera_Reset = function()
        if FreeCam.IsActive() then
            self:ResetCamera();
        end
    end
end

function FreeCam.Internal:OnSavegameLoaded()
    Input.KeyBindDown(Keys.ModifierControl + Keys.ModifierAlt + Keys.NumPad9, "Camera_ToggleDefault");
    Camera.RotSetFlipBack((self.Data.IsActive and 0) or 1);
    self:SetShortcuts();
end

function FreeCam.Internal:IsActive()
    return self.Data.IsActive == true;
end

function FreeCam.Internal:IsAllowed()
    return self.Data.IsAllowed == true;
end

function FreeCam.Internal:SetToggleable(_Flag)
    self.Data.IsAllowed = _Flag == true;
end

function FreeCam.Internal:ResetCamera()
    self.Data.Rotation = -45;
    Camera.RotSetAngle(self.Data.Rotation);
    self.Data.Angle = 49;
    Camera.ZoomSetAngle(self.Data.Angle);
    self.Data.FOV = 42;
    Camera.ZoomSetFOV(self.Data.FOV);
    self.Data.Distance = 9000;
    Camera.ZoomSetDistance(self.Data.Distance);
end

function FreeCam.Internal:ToggleFreeCamera()
    self:Install();

    self.Data.IsActive = not self.Data.IsActive;
    Camera.RotSetFlipBack((self.Data.IsActive and 0) or 1);
    if self.Data.IsActive then
        gvCamera.DefaultFlag = 0;
        self:ResetCamera();
        XGUIEng.ShowWidget("Normal", 0);
        XGUIEng.ShowWidget("3dOnScreenDisplay", 0);
        XGUIEng.ShowWidget("3dWorldView", 0);
        Display.SetRenderFogOfWar(0);
        Display.SetRenderSky(1);
        -- Game.GUIActivate(0);
    else
        gvCamera.DefaultFlag = 1;
        self:ResetCamera();
        XGUIEng.ShowWidget("Normal", 1);
        XGUIEng.ShowWidget("3dOnScreenDisplay", 1);
        XGUIEng.ShowWidget("3dWorldView", 1);
        Display.SetRenderFogOfWar(1);
        Display.SetRenderSky(0);
        -- Game.GUIActivate(1);
    end
end

function FreeCam.Internal:SetShortcuts()
    Input.KeyBindDown(Keys.ModifierControl + Keys.Space, "Camera_ToggleDefault()", 2);
    Input.KeyBindDown(Keys.ModifierControl + Keys.R, "Camera_Reset()", 2);
    Input.KeyBindDown(Keys.ModifierControl + Keys.E, "Camera_IncreaseAngle()", 2);
    Input.KeyBindDown(Keys.ModifierControl + Keys.Q, "Camera_DecreaseAngle()", 2);
    Input.KeyBindDown(Keys.ModifierControl + Keys.S, "Camera_IncreaseZoom()", 2);
    Input.KeyBindDown(Keys.ModifierControl + Keys.W, "Camera_DecreaseZoom()", 2);
    Input.KeyBindDown(Keys.ModifierControl + Keys.Y, "Camera_DecreaseFOV()", 2);
    Input.KeyBindDown(Keys.ModifierControl + Keys.C, "Camera_IncreaseFOV()", 2);
    Input.KeyBindDown(Keys.ModifierControl + Keys.A, "Camera_RotateLeft()", 2);
    Input.KeyBindDown(Keys.ModifierControl + Keys.D, "Camera_RotateRight()", 2);
end

