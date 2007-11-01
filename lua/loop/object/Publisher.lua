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

local oo = require "loop.base"

module("loop.object.Publisher", oo.class)

local event

local function method(self, ...)
	local method = event
	for _, object in pairs(self) do
		object[method](object, ...)
	end
end

function __index(self, key)
	event = key
	return method
end

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
