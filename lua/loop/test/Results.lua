local _G = require "_G"
local xpcall = _G.xpcall

local array = require "table"
local concat = array.concat

local package = require "package"
local debug = package.loaded.debug
local traceback = debug and debug.traceback or function (msg) return msg end

local oo = require "loop.cached"
local class = oo.class


local function process(self, index, name, success, ...)
	local reporter = self.reporter
	if reporter ~= nil then
		reporter:ended(name, success, ...)
	end
	if index ~= nil then self[index] = nil end
	return success, ...
end


local Runner = class()

function Runner:__call(label, func, ...)
	local index
	if label ~= nil then
		index = #self+1
		self[index] = label
	end
	local name = concat(self, ".")
	local reporter = self.reporter
	if reporter ~= nil then
		reporter:started(name)
	end
	return process(self, index, name, xpcall(func, traceback, ...))
end

return Runner
