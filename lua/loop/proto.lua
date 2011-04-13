-- Project: LOOP - Lua Object-Oriented Programming
-- Release: 3.0 beta
-- Title  : Dymamic Prototyping Model
-- Author : Renato Maia <maia@inf.puc-rio.br>

local _G = require "_G"
local getmetatable = _G.getmetatable
local rawget = _G.rawget
local setmetatable = _G.setmetatable

local table = require "loop.table"
local memoize = table.memoize

local CloneOf = memoize(function(proto) return {__index = proto} end, "k")

return {
	clone = function(proto, clone)
		return setmetatable(clone, CloneOf[proto])
	end,
	getproto = function(clone)
		local meta = getmetatable(clone)
		if meta ~= nil then
			local proto = meta.__index
			if meta == rawget(CloneOf, proto) then
				return proto
			end
		end
	end,
	iscloneof = function(clone, proto)
		return getmetatable(clone) == rawget(CloneOf, proto)
	end,
}