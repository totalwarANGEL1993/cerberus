--[[
Library/Cerberus_0_Core/API

Copyright (C) 2022 totalwarANGEL - All Rights Reserved.

This file is part of Cerberus. Cerberus is created by totalwarANGEL.
You may use and modify this file unter the terms of the MIT licence.
(See https://en.wikipedia.org/wiki/MIT_License)
]]

---
-- Implements the base functionality of the library.
--
-- @set sort=true
-- @within Description
--

---
--
--
function API.CreateScriptEvent(_Name)
    return Cerberus:CreateScriptEvent(_Name);
end

---
--
--
function API.SendScriptEvent(_ID, ...)
    return Cerberus:DispatchScriptEvent(_ID, arg);
end

