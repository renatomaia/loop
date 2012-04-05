-- Project: LOOP - Lua Object-Oriented Programming
-- Title  : Component Model with Wrapping Container
-- Author : Renato Maia <maia@inf.puc-rio.br>


local _G = require "_G"
local error = _G.error
local pairs = _G.pairs
local rawget = _G.rawget
local select = _G.select
local type = _G.type

local table = require "loop.table"
local memoize = table.memoize

local oo = require "loop.cached"
local allmembers = oo.allmembers
local class = oo.class
local getclass = oo.getclass
local isinstanceof = oo.isinstanceof
local issubclassof = oo.issubclassof

local base = require "loop.component.base"
local base_factoryof = base.factoryof
local base_ports = base.ports


local MethodCache = memoize(function(method)
	return function(self, ...)
		return method(self.__container.__state.__component, ...)
	end
end, "k")


local ExternalState = class()

function ExternalState:__index(name)
	self = self.__container
	local state = self.__state
	local port, manager = state[name], self[name]
	if port and manager then
		return rawget(manager, "__external") or manager
	end
	local value = port or state.__component[name]
	if type(value) == "function" then
		return MethodCache[value]
	end
	return value
end

function ExternalState:__newindex(name, value)
	self = self.__container
	local state = self.__state
	local manager = self[name]
	if manager and manager.__bind then
		manager:__bind(value)
	elseif manager ~= nil then
		state[name] = value
	else
		state.__component[name] = value
	end
end


local BaseTemplate = class({}, base.BaseTemplate)

function BaseTemplate:__container(segments)
	local container = {
		__state    = segments,
		__internal = segments,
	}
	container.__external = ExternalState{ __container = container }
	return container
end

function BaseTemplate:__build(segments)
	local container = self:__container(segments)
	local state = container.__state
	local context = container.__internal
	for port, class in allmembers(getclass(self)) do
		if port:find("^%a[%w_]*$") then
			container[port] = class(state, port, context)
		end
	end
	state.__self = container.__external
	for port in pairs(self) do
		if port == 1
			then self:__setcontext(segments.__component, context)
			else self:__setcontext(segments[port], context)
		end
	end
	return container.__external
end


local function factoryof(component)
	local container = component.__container
	return base_factoryof(container and container.__state or component)
end

local function templateof(factory)
	if not isinstanceof(factory, BaseTemplate) then
		factory = factoryof(factory)
	end
	return getclass(factory)
end


local module = {
	MethodCache = MethodCache,
	BaseTemplate = BaseTemplate,
	factoryof = factoryof,
	templateof = templateof,
}


function module.Template(template, ...)
	return class(template, BaseTemplate, ...)
end


function module.ports(template)
	if not issubclassof(template, BaseTemplate) then
		template = templateof(template)
	end
	return base_ports(template)
end

function module.segmentof(comp, port)
	return comp.__container.__state[port]
end


function module.addport(comp, name, port, class)
	local container = comp.__container
	if container then
		local context = container.__internal
		local state = container.__state
		local factory = state.__factory
		if class then
			local comp = state.__component or state
			state[name] = class(comp[name], comp)
		end
		container[name] = port(state, name, context, factory)
		factory:__setcontext(state[name], context)
	else
		error("bad argument #1 to 'addport' (component expected, got "..type(comp)..")")
	end
end

function module.removeport(comp, name)
	local container = comp.__container
	if container then
		local state = container.__state
		container[name] = nil
		state[name] = nil
	else
		error("bad argument #1 to 'removeport' (component expected, got "..type(comp)..")")
	end
end

return module

--[[----------------------------------------------------------------------------
MyCompTemplate = comp.Template{
	[<portname>] = <PortClass>,
	[<portname>] = <PortClass>,
	[<portname>] = <PortClass>,
}

MyContainer = Container{
	__external = Handler{ <container> },
	__internal = {
		<componentimpl>,
		[<portname>] = <portimpl>,
		[<portname>] = <portimpl>,
		[<portname>] = <portimpl>,
	},
	[<portname>] = <portmanager>,
	[<portname>] = <portmanager>,
	[<portname>] = <portmanager>,
}

EMPTY       Internal Self      |   EMPTY       Internal Self   
Facet       nil      wrapper   |   Facet       nil      false
Receptacle  nil      wrapper   |   Receptacle  nil      false
Multiple    multiple wrapper   |   Multiple    multiple false
                               |                              
FILLED      Internal Self      |   FILLED      Internal Self   
Facet       port     wrapper   |   Facet       port     false
Receptacle  wrapper  wrapper   |   Receptacle  port     false
Multiple    multiple wrapper   |   Multiple    multiple false
----------------------------------------------------------------------------]]--
