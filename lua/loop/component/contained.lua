-- Project: LOOP - Lua Object-Oriented Programming
-- Title  : Component Model with Full Containment Support
-- Author : Renato Maia <maia@inf.puc-rio.br>


local _G = require "_G"
local pairs = _G.pairs
local select = _G.select
local type = _G.type

local oo = require "loop.cached"
local class = oo.class

local base = require "loop.component.wrapped"


local BaseTemplate = class({}, base.BaseTemplate)

function BaseTemplate:__init(...)
	local state = { __factory = self }
	local comp = self.__component or self[1]
	if comp then
		comp = comp(...)
		state.__component = comp
	else
		comp = ... or {}
	end
	for port, class in pairs(self) do
		if type(port) == "string" and port:match("^%a[%w_]*$") then
			state[port] = class(comp and comp[port], comp)
		end
	end
	return state
end


local module = {
	MethodCache = base.MethodCache, -- used by 'dynamic' component model
	BaseTemplate = BaseTemplate,
	
	factoryof  = base.factoryof,
	templateof = base.templateof,
	ports      = base.ports,
	segmentof  = base.segmentof,
	
	addport    = base.addport,
	removeport = base.removeport,
}


function module.Template(template, ...)
	return class(template, BaseTemplate, ...)
end

return module
