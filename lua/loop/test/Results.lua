
local _G = require "_G"
local select = _G.select
local xpcall = _G.xpcall

local table = require "table"
local concat = table.concat

local debug = require "debug"
local traceback = debug.traceback

local oo = require "loop.simple"
local class = oo.class

local Assert = require "loop.test.Assert"

module "loop.test.Results"

class(_M, Assert)

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
	return self:process(label, name, xpcall(func, traceback, ...))
end
