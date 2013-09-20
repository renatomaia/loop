
local _G = require "_G"
local error = _G.error
local select = _G.select
local xpcall = _G.xpcall

local table = require "table"
local concat = table.concat
local unpack = table.unpack or _G.unpack

local debug = require "debug"
local traceback = debug.traceback

local oo = require "loop.simple"
local checks = require "loop.test.checks"

local module = oo.class()

module.is = checks.is
module.equals = checks.equal
module.similar = checks.like
module.match = checks.match
module.typeis = checks.type

function module.isnot(...)
	return checks.NOT(module.is(...))
end

local checks_assert = checks.assert
function module.assert(self, value, ...)
	if _G.type(...) ~= "string" then
		checks_assert(value, ...)
	elseif not value then
		local message, level = ...
		error(message, (level or 1) + 1)
	end
	return value, ...
end

function module.process(self, label, name, success, ...)
	if self.reporter then
		self.reporter:ended(name, success, ...)
	end
	if label ~= nil then self[#self] = nil end
	return success, ...
end

function module.test(self, label, func, ...)
	self[#self+1] = label
	local name = concat(self, ".")
	if self.reporter then
		self.reporter:started(name)
	end
	local count = select("#", ...)
	local arg = {...}
	return self:process(label, name, xpcall(function()
		return func(unpack(arg, 1, count))
	end, traceback))
end

return module

