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

local type        = type
local oo          = require "loop.base"
local ObjectCache = require "loop.collection.ObjectCache"

module("loop.object.Wrapper", oo.class)

local methods = ObjectCache{
	retrieve = function(_, method)
		return function(self, ...)
			return method(self.__object, ...)
		end
	end,
}

function __index(self, key)
	local value = self.__object[key]
	if type(value) == "function"
		then return methods[value]
		else return value
	end
end
