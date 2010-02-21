--------------------------------------------------------------------------------
---------------------- ##       #####    #####   ######  -----------------------
---------------------- ##      ##   ##  ##   ##  ##   ## -----------------------
---------------------- ##      ##   ##  ##   ##  ######  -----------------------
---------------------- ##      ##   ##  ##   ##  ##      -----------------------
---------------------- ######   #####    #####   ##      -----------------------
----------------------                                   -----------------------
----------------------- Lua Object-Oriented Programming ------------------------
--------------------------------------------------------------------------------
-- Project: LOOP Class Library                                                --
-- Release: 2.3 beta                                                          --
-- Title  : Class that Implement Group Invocation                             --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------

local pairs = pairs

local tabop = require "loop.table"
local oo    = require "loop.base"

module("loop.object.Publisher", oo.class)

__index = tabop.memoize(function(method)
	return function(self, ...)
		for _, object in pairs(self) do
			object[method](object, ...)
		end
	end
end, "k")

function __newindex(self, key, value)
	for _, object in pairs(self) do
		object[key] = value
	end
end

function __call(self, ...)
	for _, object in pairs(self) do
		object(...)
	end
end
