--------------------------------------------------------------------------------
---------------------- ##       #####    #####   ######  -----------------------
---------------------- ##      ##   ##  ##   ##  ##   ## -----------------------
---------------------- ##      ##   ##  ##   ##  ######  -----------------------
---------------------- ##      ##   ##  ##   ##  ##      -----------------------
---------------------- ######   #####    #####   ##      -----------------------
----------------------                                   -----------------------
----------------------- Lua Object-Oriented Programming ------------------------
--------------------------------------------------------------------------------
-- Project: LOOP - Lua Object-Oriented Programming                            --
-- Release: 2.3 beta                                                          --
-- Title  : Static Class Model witout Support for Introspection               --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------
-- Exported API:                                                              --
--   class(class)                                                             --
--   new(class, ...)                                                          --
--   share(object [, level])                                                  --
--   this([level])                                                            --
--------------------------------------------------------------------------------

local _G = require "_G"

local getfenv = _G.getfenv
local setfenv = _G.setfenv
local type = _G.type

module "loop.static"
--------------------------------------------------------------------------------
function class(class)
	class = class or function() end
	return function(object, ...)
		setfenv(class, object or {})
		class(object, ...)
		object = getfenv(class)
		setfenv(class, _G)
		return object
	end
end
--------------------------------------------------------------------------------
function new(class, ...)
	return class(...)
end
--------------------------------------------------------------------------------
function share(obj, level)
	if type(obj) == "table" then
		setfenv((level or 1) + 1, obj)
	end
end
--------------------------------------------------------------------------------
function this(level)
	return getfenv((level or 1) + 1)
end
