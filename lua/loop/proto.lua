--------------------------------------------------------------------------------
-- Project: LOOP - Lua Object-Oriented Programming                            --
-- Title  : Simple Inheritance Class Model                                    --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------

local table = require "loop.table"
local memoize = table.memoize

local base = require "loop.base"
local class = base.class
local classof = base.classof
local instanceof = base.instanceof

module "loop.proto"

local CloneOf = memoize(function(proto) return class{__index = proto} end, "k")

function clone(proto, clone)
	return CloneOf[proto](clone)
end

function prototypeof(clone)
	local class = classof(clone)
	if class ~= nil then
		return class.__index
	end
end

function cloneof(clone, proto)
	return instanceof(clone, CloneOf[proto])
end
