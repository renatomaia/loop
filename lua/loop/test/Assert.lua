
local error  = error
local ipairs = ipairs
local select = select
local type   = type
local unpack = unpack

local table = require "loop.table"
local oo    = require "loop.base"

local Viewer = require "loop.debug.Viewer"
local Exception = require "loop.object.Exception"

local checks = require "loop.test.checks"

module("loop.test.Assert", oo.class)

table.copy(checks, _M)

viewer = Viewer{ maxdepth = 2 }

local function format(viewer, pattern, ...)
	local result = {}
	for i = 1, select("#", ...) do
		result[#result+1] = viewer:tostring((select(i, ...)))
	end
	return pattern:format(unpack(result))
end

function results(self, success, message, ...)
	if not success then
		local viewer = self.viewer
		if type(message) == "string" then
			self:fail(format(viewer, message, ...), 2)
		elseif type(message) == "table" then
			result = {}
			for _, msg in ipairs(message) do
				result[result+1] = format(viewer, unpack(msg, 1, msg.n))
			end
			self:fail(table.concat(result, "\n\t"), 2)
		end
		self:fail(message, 2)
	end
	return success, message, ...
end

function assert(self, value, ...)
	if type(...) ~= "string" then
		self:results(both(...)(value))
	elseif not value then
		local message, level = ...
		self:fail(message, (level or 1) + 1)
	end
	return value, ...
end

AssertionFailure = "Assertion Failure"

function fail(self, message, level)
	error(Exception{AssertionFailure, message = message}, (level or 1) + 1)
end

function isfailure(self, error)
	return oo.instanceof(error, Exception) and error[1] == self.AssertionFailure
end