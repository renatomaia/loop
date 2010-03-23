-- Project: LOOP - Lua Object-Oriented Programming
-- Release: 3.0 beta
-- Title  : Dymamic Prototyping Model
-- Author : Renato Maia <maia@inf.puc-rio.br>

local table = require "loop.table"
local memoize = table.memoize

local base = require "loop.base"
local class = base.class
local getclass = base.getclass
local isinstanceof = base.isinstanceof

module "loop.proto"

local CloneOf = memoize(function(proto) return class{__index = proto} end, "k")

function clone(proto, clone)
	return CloneOf[proto](clone)
end

function getproto(clone)
	local class = getclass(clone)
	if class ~= nil then
		return class.__index
	end
end

function iscloneof(clone, proto)
	return isinstanceof(clone, CloneOf[proto])
end
