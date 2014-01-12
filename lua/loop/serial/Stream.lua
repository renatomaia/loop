-- Project: LOOP Class Library
-- Release: 3.0
-- Title  : Stream that Serializes and Restores Values from Files
-- Author : Renato Maia <maia@inf.puc-rio.br>


local _G = require "_G"
local assert = _G.assert
local load = _G.load
local pcall = _G.pcall
local select = _G.select

local array = require "table"
local concat = array.concat

local package = require "package"
local debug = package.loaded.debug -- only if available

local oo = require "loop.simple"
local class = oo.class

local Serializer = require "loop.serial.Serializer"


local Stream = class({
	load = load,
	require = _G.require,
	setmetatable = _G.setmetatable,
	setupvalue = debug and debug.setupvalue,
	upvaluejoin = debug and debug.upvaluejoin,
}, Serializer)

if _G._VERSION=="Lua 5.1" then Stream.setfenv = _G.setfenv end

function Stream:put(...)
	local values = {...}
	for i=1, select("#", ...) do
		values[i] = self:serialize(values[i])
	end
	self:write("return ",concat(values, ", "),"\n")
end

function Stream:get()
	local env = self.environment or self
	return assert(load(self:read(), "serialization", "t", env))()
end

return Stream
