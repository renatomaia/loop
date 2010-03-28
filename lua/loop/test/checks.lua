
local rawequal = rawequal
local select   = select
local type     = type

local string = require "string"

local Matcher = require "loop.debug.Matcher"

module "loop.test.checks"

local NotEquals = ": %s was not equal to %s"
function equals(expected, message)
	if not message then message = "expected equals values" end
	return function(actual)
		if actual ~= expected then
			return false, message..NotEquals, actual, expected
		end
		return true
	end
end

local Equals = ": was equal to %s"
function different(expected, message)
	if not message then message = "expected different values" end
	return function(actual)
		if actual == expected then
			return false, message..Equals, expected
		end
		return true
	end
end

local WasNot = ": %s was not %s"
function is(expected, message)
	if not message then message = "expected same values" end
	return function(actual)
		if not rawequal(actual, expected)then
			return false, message..WasNot, actual, expected
		end
		return true
	end
end

local WasSame = ": was same of %s"
function isnot(expected, message)
	if not message then message = "not expected same values" end
	return function(actual)
		if rawequal(actual, expected)then
			return false, message..WasSame, expected
		end
		return true
	end
end

local TypeWasNot = ": type of %s was not %s"
function typeis(expected, message)
	if not message then message = "expected same type" end
	return function(actual)
		if type(actual) ~= expected then
			return false, message..TypeWasNot, actual, expected
		end
		return true
	end
end

local TypeWas = ": type of %s was %s"
function typeisnot(expected, message)
	if not message then message = "expected different type" end
	return function(actual)
		if type(actual) == expected then
			return false, message..TypeWas, actual, expected
		end
		return true
	end
end

local DidNotMatch = ": %s did not match %s"
function match(expected, message)
	if not message then message = "pattern expected" end
	return function(actual)
		if not string.match(actual, expected) then
			return false, message..DidNotMatch, actual, expected
		end
		return true
	end
end

local DidMatch = ": %s did match %s"
function notmatch(expected, message)
	if not message then message = "pattern not expected" end
	return function(actual)
		if string.match(actual, expected) then
			return false, message..DidMatch, actual, expected
		end
		return true
	end
end

local NotSimilar = ": %s was not similar to %s (%s)"
function similar(expected, message, criteria)
	if not message then message = "expected similar values" end
	criteria = criteria or {}
	if criteria.isomorphic == nil then 
		criteria.isomorphic = false
	end
	if criteria.metatable == nil then 
		criteria.metatable = false
	elseif criteria.metatable == true then 
		criteria.metatable = nil
	end
	return function(actual)
		local success, errmsg = Matcher(criteria):match(expected, actual)
		if not success then
			return false, message..NotSimilar, actual, expected, errmsg
		end
		return true
	end
end

local IsSimilar = ": %s was similar to %s (%s)"
function notsimilar(expected, message, criteria)
	if not message then message = "expected not similar values" end
	criteria = criteria or {}
	if criteria.isomorphic == nil then 
		criteria.isomorphic = false
	end
	if criteria.metatable == nil then 
		criteria.metatable = false
	end
	return function(actual)
		local success, errmsg = Matcher(criteria):match(expected, actual)
		if success then
			return false, message..IsSimilar, actual, expected, errmsg
		end
		return true
	end
end

--------------------------------------------------------------------------------

local function joincheck(conds, index, value, ...)
	if (...) and conds[index] then
		return joincheck(conds, index+1, value, conds[index](value))
	end
	return ...
end

function both(...)
	local conds = {...}
	return function(value)
		return joincheck(conds, 1, value, true)
	end
end

--------------------------------------------------------------------------------

local function altcheck(conds, index, value, errors, ...)
	if not (...) then
		errors[#errors+1] = { n = select("#", ...) - 1, select(2, ...) }
		if conds[index] then
			return altcheck(conds, index+1, value, errors, conds[index](value))
		end
		return false, errors
	end
	return ...
end

function either(...)
	local conds = {...}
	return function(value)
		return altcheck(conds, 1, value, {}, false, "multiple check failed:")
	end
end
