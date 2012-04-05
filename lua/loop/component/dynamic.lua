-- Project: LOOP - Lua Object-Oriented Programming
-- Title  : Component Model with Dynamically Adaptable Containers
-- Author : Renato Maia <maia@inf.puc-rio.br>


local _G = require "_G"
local next = _G.next
local rawget = _G.rawget
local select = _G.select
local type = _G.type

local oo = require "loop.cached"
local class = oo.class
local getclass = oo.getclass
local getsuper = oo.getsuper
local isclass = oo.isclass
local isinstanceof = oo.isinstanceof

local base = require "loop.component.contained"
local base_addport = base.addport
local base_BaseTemplate = base.BaseTemplate
local base_ports = base.ports
local base_removeport = base.removeport
local MethodCache = base.MethodCache


local WeakTable = class{ __mode = "k" }


local DynamicPort = class()

function DynamicPort:__call(state, name, ...)
	if self.class then
		state[name] = self.class(state[name], state.__component)
	end
	return self.port(state, name, ...)
end

function DynamicPort:__tostring()
	return self.name
end


local InternalState = class()

function InternalState:__index(name)
	self = self.__container
	local state = self.__state
	local port, manager = state[name], self[name]
	if manager == nil then
		local factory = state.__factory
		local class = factory[name]
		if getclass(class) == DynamicPort then
			local context = self.__internal
			self[class] = class(state, class, context)
			port, manager = state[class], self[class]
			factory:__setcontext(port, context)
		end
	end
	return port, manager
end

function InternalState:__newindex(name, value)
	self = self.__container
	local state = self.__state
	local manager = self[name]
	if manager == nil then
		local factory = state.__factory
		local class = factory[name]
		if getclass(class) == DynamicPort then
			local context = self.__internal
			self[class] = class(state, class, context)
			manager = self[class]
			factory:__setcontext(state[class], context)
		end
	end
	if manager and manager.__bind then
		manager:__bind(value)
	elseif manager ~= nil then
		state[name] = value
	else
		state.__component[name] = value
	end
end


local ExternalState = class({}, InternalState)

function ExternalState:__index(name)
	local port, manager = getsuper(ExternalState).__index(self, name)
	if port and manager then
		return rawget(manager, "__external") or manager
	else
		local value = port or self.__container.__state.__component[name]
		if type(value) == "function" then
			return MethodCache[value]
		end
		return value
	end
end


local BaseTemplate = class({}, base_BaseTemplate)

function BaseTemplate:__container(comp)
	local container = WeakTable(base_BaseTemplate.__container(self, comp))
	container.__state = WeakTable(container.__state)
	container.__internal = InternalState{ __container = container }
	container.__external = ExternalState{ __container = container }
	return container
end


local module = {
	BaseTemplate = BaseTemplate,
	factoryof = base.factoryof,
	templateof = base.templateof,
}


function module.Template(template, ...)
	return class(template, BaseTemplate, ...)
end


local function portiterator(container, name)
	local factory = container.__state.__factory
	local port = factory[name]
	if getclass(port) == DynamicPort then
		name = port
	end
	repeat
		name = next(container, name)
		if name == nil then
			return nil
		elseif getclass(name) == DynamicPort then
			return name.name, name.port
		end
	until name:find("^%a[%w_]*$")
	return name, getclass(factory)[name]
end

function module.ports(component)
	local container = component.__container
	if container
		then return portiterator, container
		else return base_ports(component)
	end
end

function module.segmentof(comp, name)
	local state = comp.container.__state
	local port = state.__factory[name]
	if getclass(port) == DynamicPort then
		name = port
	end
	return state[port]
end


function module.addport(scope, name, port, class)
	if isclass(scope) or isinstanceof(scope, BaseTemplate) then
		scope[name] = DynamicPort{
			name = name,
			port = port,
			class = class,
		}
	else
		base_addport(scope, name, port, class)
	end
end

function module.removeport(scope, name)
	if isclass(scope) or isinstanceof(scope, BaseTemplate) then
		scope[name] = nil
	else
		base_removeport(scope, name)
	end
end


return module

--[[----------------------------------------------------------------------------
MyCompTemplate = comp.Template{
	[<portname>] = <PortClass>,
	[<portname>] = <PortClass>,
	[<portname>] = <PortClass>,
}

MyContainer = WeakKeyTable{
	__external = Handler{ <container> },
	__internal = Context{ <container> },
	__state = WeakKeyTable{
		<componentimpl>,
		[<portname>] = <portimpl>,
		[<portname>] = <portimpl>,
		[<dynaport>] = <portimpl>,
	},
	__factory = {
		[<portname>] = <portclass>,
		[<portname>] = <portclass>,
		[<portname>] = <dynaport>,
	},
	[<portname>] = <portmanager>,
	[<portname>] = <portmanager>,
	[<dynaport>] = <portmanager>,
}

EMPTY       Internal Self      |   EMPTY       Internal Self   
Facet       nil      wrapper   |   Facet       nil      nil
Receptacle  nil      wrapper   |   Receptacle  nil      nil
Multiple    multiple wrapper   |   Multiple    multiple nil
                               |                              
FILLED      Internal Self      |   FILLED      Internal Self   
Facet       port     wrapper   |   Facet       port     nil
Receptacle  wrapper  wrapper   |   Receptacle  port     nil
Multiple    multiple wrapper   |   Multiple    multiple nil
----------------------------------------------------------------------------]]--
