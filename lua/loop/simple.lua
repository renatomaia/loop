-- Project: LOOP - Lua Object-Oriented Programming
-- Release: 3.0 beta
-- Title  : Simple Inheritance Class Model
-- Author : Renato Maia <maia@inf.puc-rio.br>

local _G = require "_G"
local getmetatable = _G.getmetatable
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

local MetaClassMeta
local DerivedMeta = memoize(function(super)
	return setmetatable({ __index = super, __call = new }, MetaClassMeta)
end, "k")

function class(class, super)
	if super == nil
		then return base_class(class)
		else return setmetatable(initclass(class), DerivedMeta[super])
	end
end

function isclass(class)
	local metaclass = getmetatable(class)
	if metaclass ~= nil then
		local super = metaclass.__index
		if metaclass == rawget(DerivedMeta, super) then
			return true
		end
		return base_isclass(class)
	end
end

function getsuper(class)
	local metaclass = getmetatable(class)
	if metaclass ~= nil then
		local super = metaclass.__index
		if metaclass == rawget(DerivedMeta, super) then
			return super
		end
	end
end

function issubclassof(class, super)
	while class ~= nil do
		if class == super then return true end
		class = getsuper(class)
	end
	return false
end

function isinstanceof(object, class)
	return issubclassof(getclass(object), class)
end

MetaClassMeta = {
	__index = {
		new = new,
		rawnew = rawnew,
		getmember = getmember,
		members = members,
		getsuper = getsuper,
	},
}
