
local error  = error
local ipairs = ipairs
local select = select
local type   = type

local table = require "table"
local table.unpack = table.unpack or _G.unpack

local tabop = require "loop.table"
local oo    = require "loop.base"

local Viewer = require "loop.debug.Viewer"
local Exception = require "loop.object.Exception"

local checks = require "loop.test.checks"

local module = oo.class()

tabop.copy(checks, module)

module.viewer = Viewer{ maxdepth = 2 }

local function format(viewer, pattern, ...)
	local result = {}
	for i = 1, select("#", ...) do
		result[#result+1] = viewer:tostring((select(i, ...)))
	end
	return pattern:format(table.unpack(result))
end

function module.results(self, success, message, ...)
	if not success then
		local viewer = self.viewer
		if type(message) == "string" then
			self:fail(format(viewer, message, ...), 2)
		elseif type(message) == "table" then
			result = {}
			for _, msg in ipairs(message) do
				result[#result+1] = format(viewer, table.unpack(msg, 1, msg.n))
			end
			self:fail(table.concat(result, "\n\t"), 2)
		end
		self:fail(message, 2)
	end
	return success, message, ...
end

function module.assert(self, value, ...)
	if type(...) ~= "string" then
		self:results(both(...)(value))
	elseif not value then
		local message, level = ...
		self:fail(message, (level or 1) + 1)
	end
	return value, ...
end

module.AssertionFailure = "[Assertion Failure] $message"

function module.fail(self, message, level)
	error(Exception{self.AssertionFailure, message = message}, (level or 1) + 1)
end

function module.isfailure(self, error)
	return oo.isinstanceof(error, Exception) and error[1] == self.AssertionFailure
end

return module
