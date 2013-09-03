-- Project: LOOP Class Library
-- Title  : Dynamic Wrapper for Group Manipulation
-- Author : Renato Maia <maia@inf.puc-rio.br>

local _G = require "_G"
local pairs = _G.pairs

local tabop = require "loop.table"
local memoize = tabop.memoize

local oo = require "loop.base"

return oo.class{
	__index = memoize(function(method)
		return function(self, ...)
			for _, object in pairs(self) do
				object[method](object, ...)
			end
		end
	end, "k"),
	__newindex = function(self, key, value)
		for _, object in pairs(self) do
			object[key] = value
		end
	end,
	__call = function (self, ...)
		for _, object in pairs(self) do
			object(...)
		end
	end,
}
