-- Project: LOOP - Lua Object-Oriented Programming
-- Release: 3.0 beta
-- Title  : Multiple Inheritance Class Model
-- Author : Renato Maia <maia@inf.puc-rio.br>

local _G = require "_G"
local ipairs = _G.ipairs
local select = _G.select
local setmetatable = _G.setmetatable

local table = require "table"
local unpack = table.unpack

local loop_table = require "loop.table"
local copy = loop_table.copy

local proto = require "loop.proto"
local clone = proto.clone

local simple = require "loop.simple"
local simple_class = simple.class
local simple_isclass = simple.isclass
local simple_getsuper = simple.getsuper

module "loop.multiple"

clone(simple, _M)

local function inherit(self, field)
	self = getclass(self)
	for _, super in ipairs(self) do
		local value = super[field]
		if value ~= nil then return value end
	end
end

local MetaClassMeta

function class(class, ...)
	if select("#", ...) > 1 then
		local metaclass = { __call = new, __index = inherit, ... }
		setmetatable(metaclass, MetaClassMeta)
		return setmetatable(initclass(class), metaclass)
	else
		return simple_class(class, ...)
	end
end

function isclass(class)
	local metaclass = getclass(class)
	if metaclass then
		return metaclass.__index == inherit or
		       simple_isclass(class)
	end
end

function getsuper(class)
	local metaclass = getclass(class)
	if metaclass then
		local indexer = metaclass.__index
		if (indexer == inherit)
			then return unpack(metaclass)
			else return metaclass.__index
		end
	end
end

local function isingle(single, index)
	if single and not index then
		return 1, single
	end
end
function supers(class)
	local metaclass = getclass(class)
	if metaclass then
		local indexer = metaclass.__index
		if indexer == inherit
			then return ipairs(metaclass)
			else return isingle, simple_getsuper(class)
		end
	end
	return isingle
end

function issubclassof(class, super)
	if class == super then return true end
	for _, base in supers(class) do
		if issubclassof(base, super) then
			return true
		end
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
		supers = supers,
	},
}
