local _G = require "_G"
local pcall = _G.pcall
local tostring = _G.tostring
local xpcall = _G.xpcall

local package = require "package"
local debug = package.loaded.debug
local traceback = debug and debug.traceback

local oo = require "loop.cached"
local class = oo.class


local function settable(table, key, value)
	table[key] = value
end

local function errorhandler(message)
	if traceback ~= nil and message ~= "FAILED" then
		message = traceback(tostring(message), 2)
	end
	return message
end

local function process(self, index, success, ...)
	local reporter = self.reporter
	if reporter ~= nil then
		reporter:ended(self, success, ...)
	end
	if index ~= nil then self[index] = nil end
	return success, ...
end


local Runner = class()

function Runner:__call(label, func, ...)
	local index
	if label ~= nil then
		index = #self+1
		local path = self.path
		if path ~= nil then
			local expected = path[index]
			if index <= #path and label ~= expected and label ~= expected..".setup" and label ~= expected..".teardown" and label ~= "setup" and label ~= "teardown" then
				return true
			end
		end
		self[index] = label
	end
	local reporter = self.reporter
	if reporter ~= nil then
		reporter:started(self)
	end
	pcall(settable, func, "runner", self)
	return process(self, index, xpcall(func, errorhandler, ...))
end

return Runner
