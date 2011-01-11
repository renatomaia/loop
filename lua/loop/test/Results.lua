
local _G = require "_G"
local select = _G.select
local unpack = _G.unpack
local xpcall = _G.xpcall

local table = require "table"
local concat = table.concat

local debug = require "debug"
local traceback = debug.traceback

local oo = require "loop.simple"
local class = oo.class

local checks = require "loop.test.checks"

module "loop.test.Results"

class(_M)

is = checks.is
equals = checks.equal
similar = checks.like
match = checks.match
typeis = checks.type

function isnot(...)
	return checks.NOT(is(...))
end

local checks_assert = checks.assert
function assert(self, value, ...)
	if _G.type(...) ~= "string" then
		checks_assert(value, ...)
	elseif not value then
		local message, level = ...
		error(message, (level or 1) + 1)
	end
	return value, ...
end

function process(self, label, name, success, ...)
	if self.reporter then
		self.reporter:ended(name, success, ...)
	end
	if label ~= nil then self[#self] = nil end
	return success, ...
end

function test(self, label, func, ...)
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
