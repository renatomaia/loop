-- Project: LOOP Class Library
-- Title  : Dynamic Wrapper for Method Invocation
-- Author : Renato Maia <maia@inf.puc-rio.br>

local _G = require "_G"
local type = _G.type

local tabop = require "loop.table"
local memoize = tabop.memoize

local oo = require "loop.base"
local class = oo.class

module(..., class)

local methods = memoize(function(method)
	return function(self, ...)
		return method(self.__object, ...)
	end
end)

function __index(self, key)
	local value = self.__object[key]
	if type(value) == "function"
		then return methods[value]
		else return value
	end
end
