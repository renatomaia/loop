-- Project: LOOP Class Library
-- Title  : Dynamic Wrapper for Group Manipulation
-- Author : Renato Maia <maia@inf.puc-rio.br>

local _G = require "_G"
local pairs = _G.pairs

local table = require "loop.table"
local memoize = table.memoize

local oo = require "loop.base"
local class = oo.class


local Publisher = class{
	__index = memoize(function(method)
		return function(self, ...)
			for _, object in pairs(self) do
				object[method](object, ...)
			end
		end
	end, "k"),
}

function Publisher:__newindex(key, value)
	for _, object in pairs(self) do
		object[key] = value
	end
end

function Publisher:__call(...)
	for _, object in pairs(self) do
		object(...)
	end
end

return Publisher
