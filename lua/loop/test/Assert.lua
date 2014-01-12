local _G = require "_G"
local error = _G.error
local ipairs = _G.ipairs
local select = _G.select
local type  = _G.type

local array = require "table"
local unpack = array.unpack
local concat = array.concat

local table = require "loop.table"
local copy = table.copy

local oo = require "loop.base"
local class = oo.class
local isinstanceof = oo.isinstanceof

local Viewer = require "loop.debug.Viewer"
local Exception = require "loop.object.Exception"

local checks = require "loop.test.checks"
local both = checks.both


local function format(viewer, pattern, ...)
	local result = {}
	for i = 1, select("#", ...) do
		result[#result+1] = viewer:tostring((select(i, ...)))
	end
	return pattern:format(unpack(result))
end

local AssertionFailure = "[Assertion Failure] $message"


local Assert = class(copy(checks, { viewer = Viewer{ maxdepth = 2 } }))

function Assert:results(success, message, ...)
	if not success then
		local viewer = self.viewer
		if type(message) == "string" then
			self:fail(format(viewer, message, ...), 2)
		elseif type(message) == "table" then
			local result = {}
			for _, msg in ipairs(message) do
				result[#result+1] = format(viewer, unpack(msg, 1, msg.n))
			end
			self:fail(concat(result, "\n\t"), 2)
		end
		self:fail(message, 2)
	end
	return success, message, ...
end

function Assert:assert(value, ...)
	if type(...) ~= "string" then
		self:results(both(...)(value))
	elseif not value then
		local message, level = ...
		self:fail(message, (level or 1) + 1)
	end
	return value, ...
end

function Assert:fail(message, level)
	error(Exception{AssertionFailure, message = message}, (level or 1) + 1)
end

function Assert:isfailure(error)
	return isinstanceof(error, Exception) and error[1] == self.AssertionFailure
end

return Assert
