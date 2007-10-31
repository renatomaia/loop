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
-- Title  : Class of Dynamic Wrapper Objects for Method Invocation            --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------

local type = type
local oo   = require "loop.base"

module("loop.object.Wrapper", oo.class)

local value, object

local function method(self, ...)
	return value(object, ...)
end

function __index(self, key)
	object = self.__object
	value = object[key]
	if type(value) == "function"
		then return method
		else return value
	end
end