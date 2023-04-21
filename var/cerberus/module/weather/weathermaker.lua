Lib.Require("module/weather/DesertWeatherSet");
Lib.Require("module/weather/EuropeanWeatherSet");
Lib.Require("module/weather/EvelanceWeatherSet");
Lib.Require("module/weather/HighlandsWeatherSet");
Lib.Require("module/weather/MediterranWeatherSet");
Lib.Require("module/weather/SwampWeatherSet");
Lib.Register("module/weather/WeatherMaker");

--- 
--- Weather Stuff
---
--- Fixes weather sets for zoom factors up until 2.5 (more is just stupid).
--- 
--- @author totalwarANGEL
--- @version 1.0.0
--- 

WeatherMaker = WeatherMaker or {};

-- -------------------------------------------------------------------------- --
-- API

--- Loads a weather set.
---
--- Available weather sets:
--- * DesertWeatherSet
--- * EuropeanWeatherSet
--- * EvelanceWeatherSet
--- * HighlandsWeatherSet
--- * MediterranWeatherSet
--- * SwampWeatherSet
---
--- @param _SetName string Name of set
function UseWeatherSet(_SetName)
    WeatherMaker.Internal:UseSet(_SetName);
end

--- Make summer for some seconds. 
--- (Duration can not be lower than 20 seconds!)
--- @param _Duration integer Duration of weather element
function StartSummer(_Duration)
    _Duration = math.max(_Duration, 20);
    Logic.AddWeatherElement(1, _Duration, 0, 1, 5, 10);
end

--- Make rain for some seconds. 
--- (Duration can not be lower than 20 seconds!)
--- @param _Duration integer Duration of weather element
function StartRain(_Duration)
    _Duration = math.max(_Duration, 20);
    Logic.AddWeatherElement(2, _Duration, 0, 2, 5, 10);
end

--- Make winter for some seconds. 
--- (Duration can not be lower than 20 seconds!)
--- @param _Duration integer Duration of weather element
function StartWinter(_Duration)
    _Duration = math.max(_Duration, 20);
    Logic.AddWeatherElement(3, _Duration, 0, 3, 5, 10);
end

--- Adds sunshine to the weather cycle. 
--- (Duration can not be lower than 20 seconds!)
--- @param _Duration integer Duration of weather element
function AddPeriodicSummer(_Duration)
    _Duration = math.max(_Duration, 20);
    Logic.AddWeatherElement(1, _Duration, 1, 1, 5, 10);
end

--- Adds rain to the weather cycle. 
--- (Duration can not be lower than 20 seconds!)
--- @param _Duration integer Duration of weather element
function AddPeriodicRain(_Duration)
    _Duration = math.max(_Duration, 20);
    Logic.AddWeatherElement(2, _Duration, 1, 2, 5, 10);
end

--- Adds winter to the weather cycle. 
--- (Duration can not be lower than 20 seconds!)
--- @param _Duration integer Duration of weather element
function AddPeriodicWinter(_Duration)
    _Duration = math.max(_Duration, 20);
    Logic.AddWeatherElement(3, _Duration, 1, 3, 5, 10);
end

-- -------------------------------------------------------------------------- --
-- Internal

WeatherMaker.Internal = WeatherMaker.Internal or {
    UsedSet = EuropeanWeatherSet,
}

function WeatherMaker.Internal:Install()
    if not self.IsInstalled then
        self.IsInstalled = true;

        self.Orig_Mission_OnSaveGameLoaded = Mission_OnSaveGameLoaded;
        Mission_OnSaveGameLoaded = function()
            WeatherMaker.Internal.Orig_Mission_OnSaveGameLoaded();
            WeatherMaker.Internal:UpdateGfx();
        end
    end
end

function WeatherMaker.Internal:UseSet(_SetName)
    self:Install();
    assert(_G[_SetName] ~= nil);
    self.UsedSet = _G[_SetName];
    self:UpdateGfx();
end

function WeatherMaker.Internal:UpdateGfx()
    for i= 1, table.getn(self.UsedSet) do
        self:InitWeatherDisplay(i);
    end
end

function WeatherMaker.Internal:InitWeatherDisplay(_ID)
    local Data = self.UsedSet[_ID];
    Display.GfxSetSetSkyBox(_ID, unpack(Data.Sky));
	Display.GfxSetSetRainEffectStatus(_ID, unpack(Data.Rain));
	Display.GfxSetSetSnowStatus(_ID, unpack(Data.Ice));
	Display.GfxSetSetSnowEffectStatus(_ID, unpack(Data.Snow));
	Display.GfxSetSetFogParams(_ID, unpack(Data.Fog));
	Display.GfxSetSetLightParams(_ID, unpack(Data.Light));
    Display.SetRenderUseGfxSets(1);
end

