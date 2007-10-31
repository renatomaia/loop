
local luapcall = pcall
local select   = select

local table = require "table"

local oo = require "loop.simple"

local Assert = require "loop.test.Assert"

module "loop.test.Results"

oo.class(_M, Assert)

pcall = luapcall

function process(self, label, name, success, ...)
	if self.reporter then
		self.reporter:ended(name, success, ...)
	end
	if label ~= nil then self[#self] = nil end
	return success
end

function test(self, label, func, ...)
	self[#self+1] = label
	local name = table.concat(self, ".")
	if self.reporter then
		self.reporter:started(name)
	end
	return self:process(label, name, self.pcall(func, ...))
end
