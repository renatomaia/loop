-- Project: LOOP Class Library
-- Release: 3.0
-- Title  : Stream that Serializes and Restores Values from Files
-- Author : Renato Maia <maia@inf.puc-rio.br>


local _G = require "_G"
local assert = _G.assert
local loadstring = _G.loadstring or _G.load
local pcall = _G.pcall
local select = _G.select
local setfenv = _G.setfenv
local setmetatable = _G.setmetatable

local array = require "table"
local concat = array.concat

local debug = _G.debug -- only if available
local setupvalue = debug and debug.setupvalue
local upvaluejoin = debug and debug.upvaluejoin

local oo = require "loop.simple"
local class = oo.class

local Serializer = require "loop.serial.Serializer"



local Stream = class({
	loadstring = loadstring,
	setfenv = setfenv,
	setmetatable = setmetatable,
	setupvalue = setupvalue,
	upvaluejoin = upvaluejoin,
}, Serializer)

function Stream:put(...)
	self:write("local _ENV = ...\n")
	local values = {...}
	for i=1, select("#", ...) do
		values[i] = self:serialize(values[i])
	end
	self:write("return ",concat(values, ", "),"\n")
end

function Stream:get()
	local loader = assert(loadstring(self:read()))
	local env = self.environment or self
	pcall(setfenv, loader, env) -- Lua 5.1 compatibility
	return loader(env)
end

return Stream
