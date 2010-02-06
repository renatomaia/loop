--------------------------------------------------------------------------------
-- Project: LOOP - Lua Object-Oriented Programming                            --
-- Title  : Multiple Inheritance Class Model                                  --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------

local _G = require "_G"
local ipairs = _G.ipairs
local select = _G.select
local setmetatable = _G.setmetatable
local type = _G.type

local table = require "table"
local unpack = table.unpack

local proto = require "loop.proto"
local clone = proto.clone

local simple = require "loop.simple"
local simple_class = simple.class
local simple_isclass = simple.isclass

module "loop.multiple2"

clone(simple, _M)

function class(class, ...)
	if select("#", ...) > 1 then
		local meta = { __call = new, ... }
		local iterator, state, init = ipairs(meta)
		function meta:__index(field)
			for _, super in iterator, state, init do
				local value = super[field]
				if value ~= nil then return value end
			end
		end
		return setmetatable(initclass(class), meta)
	else
		return simple_class(class, ...)
	end
end

function isclass(class)
	local metaclass = classof(class)
	if metaclass then
		return metaclass.__call == new and type(metaclass.__index) == "function" or
		       simple_isclass(class)
	end
end

function superclass(class)
	local metaclass = classof(class)
	if metaclass then
		if (metaclass.__call == new) and (type(metaclass.__index) == "function")
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
	local metaclass = classof(class)
	if metaclass then
		local indexer = metaclass.__index
		if (metaclass.__call == new) and (type(indexer) == "function")
			then return ipairs(metaclass)
			else return isingle, indexer
		end
	end
	return isingle
end

function subclassof(class, super)
	if class == super then return true end
	for _, superclass in supers(class) do
		if subclassof(superclass, super) then return true end
	end
	return false
end

function instanceof(object, class)
	return subclassof(classof(object), class)
end
