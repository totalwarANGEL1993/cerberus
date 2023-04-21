Lib.Register("module/weather/EuropeanWeatherSet");

EuropeanWeatherSet = {
    -- Sunshine
    [1] = {
        Fog   = {0.0, 1.0, 1, 152, 172, 182, 10000, 30000},
        Light = {0.0, 1.0, 40, -15, -50, 120, 110, 110, 205, 204, 180},
        Sky   = {0.0, 1.0, "YSkyBox02"},
        Rain  = {0.0, 1.0, 0},
        Snow  = {0.0, 0.8, 0},
        Ice   = {0, 1.0, 0},
    },
    -- Rain
    [2] = {
        Fog   = {0.0, 1.0, 1, 102, 132, 142, 6000, 16000},
        Light = {0.0, 1.0, 40, -15, -50, 120, 110, 110, 205, 204, 180},
        Sky   = {0.0, 1.0, "YSkyBox04"},
        Rain  = {0.0, 1.0, 1},
        Snow  = {0.0, 0.8, 0},
        Ice   = {0, 1.0, 0},
    },
    -- Winter with Snow
    [3] = {
        Fog   = {0.0, 1.0, 1, 152, 172, 182, 6000, 20000},
        Light = {0.0, 1.0, 40, -15, -75, 116, 144, 164, 255, 234, 202},
        Sky   = {0.0, 1.0, "YSkyBox01"},
        Rain  = {0.0, 1.0, 0},
        Snow  = {0.0, 0.8, 1},
        Ice   = {0, 1.0, 1},
    },
    -- Rain and Snow
    [4] = {
        Fog   = {0.0, 1.0, 1, 102, 132, 142, 6000, 20000},
        Light = {0.0, 1.0, 40, -15, -50, 120, 110, 110, 205, 204, 180},
        Sky   = {0.0, 1.0, "YSkyBox04"},
        Rain  = {0.0, 1.0, 1},
        Snow  = {0.0, 0.8, 1},
        Ice   = {0, 1.0, 0},
    },
    -- Fog
    [5] = {
        Fog   = {0.0, 1.0, 1, 102, 132, 142, 4000, 14000},
        Light = {0.0, 1.0, 40, -15, -50, 120, 110, 110, 205, 204, 180},
        Sky   = {0.0, 1.0, "YSkyBox02"},
        Rain  = {0.0, 1.0, 0},
        Snow  = {0.0, 0.8, 0},
        Ice   = {0, 1.0, 0},
    },
    -- Heavy Rain
    [6] = {
        Fog   = {0.0, 1.0, 1, 102, 132, 142, 4000, 14000},
        Light = {0.0, 1.0, 40, -15, -50, 120, 110, 110, 185, 184, 160},
        Sky   = {0.0, 1.0, "YSkyBox04"},
        Rain  = {0.0, 1.0, 1},
        Snow  = {0.0, 0.8, 0},
        Ice   = {0, 1.0, 0},
    },
    -- Winter without Snow
    [7] = {
        Fog   = {0.0, 1.0, 1, 152, 172, 182, 6000, 20000},
        Light = {0.0, 1.0, 40, -15, -75, 116, 144, 164, 255, 234, 202},
        Sky   = {0.0, 1.0, "YSkyBox01"},
        Rain  = {0.0, 1.0, 0},
        Snow  = {0.0, 0.8, 0},
        Ice   = {0, 1.0, 1},
    },
    -- Lightning
    [8] = {
        Fog   = {0.0, 1.0, 1, 255, 255, 255, 10000, 30000},
        Light = {0.0, 1.0, 40, -15, -50, 255, 255, 255, 225, 225, 225},
        Sky   = {0.0, 1.0, "YSkyBox04"},
        Rain  = {0.0, 1.0, 1},
        Snow  = {0.0, 0.8, 0},
        Ice   = {0, 1.0, 0},
    },
}
