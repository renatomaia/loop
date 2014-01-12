-- Project: LOOP - Lua Object-Oriented Programming
-- Title  : Base Component Model
-- Author : Renato Maia <maia@inf.puc-rio.br>


local _G = require "_G"
local next = _G.next
local pairs = _G.pairs
local pcall = _G.pcall
local rawget = _G.rawget
local rawset = _G.rawset
local select = _G.select
local type = _G.type

local oo = require "loop.cached"
local allmembers = oo.allmembers
local class = oo.class
local getclass = oo.getclass
local issubclassof = oo.issubclassof
local rawnew = oo.rawnew


local BaseTemplate = class()

function BaseTemplate:__call(...)
	return self:__build(self:__init(...))
end

function BaseTemplate:__init(...)
	local comp = self.__component or self[1]
	if comp then
		comp = comp(...)
		comp.__component = comp
	else
		comp = ... or {}
	end
	comp.__factory = self
	for port, class in pairs(self) do
		if type(port) == "string" and port:match("^%a[%w_]*$") then
			comp[port] = class(comp[port], comp)
		end
	end
	return comp
end

local function tryindex(segment) return segment.context end
function BaseTemplate:__setcontext(segment, context)
	local success, setcontext = pcall(tryindex, segment)
	if success and setcontext ~= nil then
		if type(setcontext) == "function"
			then setcontext(segment, context)
			else segment.context = context
		end
	end
end

function BaseTemplate:__build(segments)
	for port, class in allmembers(getclass(self)) do
		if port:match("^%a[%w_]*$") then
			class(segments, port, segments)
		end
	end
	segments.__self = segments
	for port in pairs(self) do
		if port == 1
			then self:__setcontext(segments.__component, segments)
			else self:__setcontext(segments[port], segments)
		end
	end
	return segments
end


local function factoryof(component)
	return component.__factory
end

local function templateof(object)
	return getclass(factoryof(object) or object)
end


local module = {
	BaseTemplate = BaseTemplate,
	factoryof = factoryof,
	templateof = templateof,
}


function module.Template(template, ...)
	if select("#", ...) > 0
		then return class(template, ...)
		else return class(template, BaseTemplate)
	end
end


local nextmember
local function portiterator(state, name)
	local port
	repeat
		name, port = nextmember(state, name)
		if name == nil then return end
	until name:find("^%a")
	return name, port
end
function module.ports(template)
	if not issubclassof(template, BaseTemplate) then
		template = templateof(template)
	end
	local state, var
	nextmember, state, var = allmembers(template)
	return portiterator, state, var
end

function module.segmentof(comp, port)
	return comp[port]
end


function module.addport(comp, name, port, class)
	if class then
		comp[name] = class(comp[name], comp)
	end
	port(comp, name, comp)
	comp.__factory:__setcontext(comp[name], comp)
end

function module.removeport(comp, name)
	comp[name] = nil
end


function module.Facet(segments, name)
	segments[name] = segments[name] or
	                 segments.__component[name] or
	                 segments.__component
	return false
end

function module.Receptacle()
	return false
end


local MultipleReceptacle = class{
	__all = pairs,
	__hasany = next,
	__get = rawget,
}

function MultipleReceptacle:__new(segments, name)
	local receptacle = rawnew(self, segments[name])
	segments[name] = receptacle
	return receptacle
end

function MultipleReceptacle:__newindex(key, value)
	if value == nil
		then self:__unbind(key)
		else self:__bind(value, key)
	end
end

function MultipleReceptacle:__unbind(key)
	local port = rawget(self, key)
	rawset(self, key, nil)
	return port
end


module.ListReceptacle = class({}, MultipleReceptacle)

function module.ListReceptacle:__bind(port)
	local index = #self + 1
	rawset(self, index, port)
	return index
end


module.HashReceptacle = class({}, MultipleReceptacle)

function module.HashReceptacle:__bind(port, key)
	rawset(self, key, port)
	return key
end


module.SetReceptacle = class({}, MultipleReceptacle)

function module.SetReceptacle:__bind(port)
	rawset(self, port, port)
	return port
end


return module
