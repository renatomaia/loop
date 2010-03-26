-- Project: LOOP Class Library
-- Title  : 
-- Author : Renato Maia <maia@inf.puc-rio.br>

local oo = require "loop"
local supers = oo.supers

local CyclicSets = require "loop.collection.CyclicSets"

module(...)

local function depthfirst(stack, prev)
	local class = stack[prev]
	while class do
		local superclass
		for _, super in supers(class) do
			if stack:add(super, prev) == super then
				superclass = super
			end
		end
		if not superclass then return class end
		class = superclass
	end
end

function topdown(class)
	local stack = CyclicSets()
	stack:add(class, false)
	return depthfirst, stack, false
end

function creator(class, ...)
	local obj = rawnew(class)
	for class in topdown(class) do
		local init = class.__init
		if init then init(obj, ...) end
	end
	return obj
end

function mutator(class, obj, ...)
	obj = rawnew(class, obj)
	for class in topdown(class) do
		local init = class.__init
		if init then init(obj, ...) end
	end
	return obj
end
