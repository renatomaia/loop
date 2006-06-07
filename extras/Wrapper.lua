--------------------------------------------------------------------------------
-- Project: LOOP Extra Utilities for Lua                                      --
-- Version: 1.0 alpha                                                         --
-- Title  : Class of Dynamic Wrapper Objects for Method Invokation            --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
-- Date   : 03/08/2005 16:35                                                  --
--------------------------------------------------------------------------------

local type = type
local oo   = require "loop.base"

module("loop.extras.Wrapper", oo.class)

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