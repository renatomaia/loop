-- Project: LOOP Class Library
-- Title  : Dynamic Wrapper for Group Manipulation
-- Author : Renato Maia <maia@inf.puc-rio.br>

local _G = require "_G"
local pairs = _G.pairs

local tabop = require "loop.table"
local memoize = tabop.memoize

local oo = require "loop.base"
local class = oo.class

module(..., class)

__index = memoize(function(method)
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
