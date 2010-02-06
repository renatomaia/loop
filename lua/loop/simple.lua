--------------------------------------------------------------------------------
-- Project: LOOP - Lua Object-Oriented Programming                            --
-- Title  : Simple Inheritance Class Model                                    --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------

local _G = require "_G"
local pairs = _G.pairs
local setmetatable = _G.setmetatable
local rawget = _G.rawget

local table = require "loop.table"
local memoize = table.memoize

local base = require "loop.base"
local base_class = base.class
local base_isclass = base.isclass

local proto = require "loop.proto"
local clone = proto.clone

module "loop.simple"

clone(base, _M)

local DerivedMeta = memoize(function(super)
	return { __index = super, __call = new }
end, "k")

function class(class, super)
	if super == nil
		then return base_class(class)
		else return setmetatable(initclass(class), DerivedMeta[super])
	end
end

function isclass(class)
	local metaclass = classof(class)
	if metaclass ~= nil then
		return metaclass == rawget(DerivedClassMeta, metaclass.__index) or
		       base_isclass(class)
	end
end

function superclass(class)
	local metaclass = classof(class)
	if metaclass ~= nil then
		local super = metaclass.__index
		if metaclass == rawget(DerivedMeta, super) then
			return super
		end
	end
end

function subclassof(class, super)
	while class ~= nil do
		if class == super then return true end
		class = superclass(class)
	end
	return false
end

function instanceof(object, class)
	return subclassof(classof(object), class)
end
