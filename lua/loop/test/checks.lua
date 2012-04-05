local _G = require "_G"
local ipairs = _G.ipairs
local rawequal = _G.rawequal
local select = _G.select
local type = _G.type

local string = require "string"
local find = string.find

local table = require "table"
local concat = table.concat
local unpack = table.unpack or _G.unpack

local tabop = require "loop.table"
local copy = tabop.copy

local oo = require "loop.base"
local class = oo.class

local Matcher = require "loop.debug.Matcher"
local Viewer = require "loop.debug.Viewer"
local Exception = require "loop.object.Exception"

local checks = {
	is = {
		op = rawequal,
		title = "same values",
		[true] = "value was $expected",
		[false] = "$actual was not $expected",
	},
	equal = {
		op = function(actual, expected) return actual==expected end,
		title = "equal values",
		[true] = "$actual was equal to $expected",
		[false] = "$actual was not equal to $expected",
	},
	like = {
		op = function(actual, expected, criteria)
			criteria = copy(criteria, {})
			if criteria.isomorphic == nil then 
				criteria.isomorphic = false
			end
			if criteria.metatable == nil then 
				criteria.metatable = false
			elseif criteria.metatable == true then 
				criteria.metatable = nil
			end
			return Matcher(criteria):match(expected, actual)
		end,
		title = "values alike",
		[true] = "$actual was like $expected",
		[false] = "mismatch at $mismatch, $actual was not like $expected",
		results = {"mismatch"},
	},
	type = {
		op = function(value, expected)
			local actual = type(value)
			return actual==expected, actual
		end,
		title = "value of type",
		[true] = "type of $actual was $expected",
		[false] = "type of $actual was $actualtype, not $expected",
		results = {"actualtype"},
	},
	match = {
		op = function(...)
			local start, finish = find(...)
			return start~=nil, start, finish
		end,
		title = "string pattern match",
		[true] = "$actual matched $expected at position $start..$finish",
		[false] = "$actual did not match $expected",
		results = {"start", "finish"},
	},
}

local function doresult(info, title, actual, expected, expres, actres, ...)
	if actres ~= expres then
		if title == nil then
			title = "expected "..info.title
			if not expres then title = "not "..title end
		end
		local except = Exception{
			"$title ("..info[actres]..")",
			title = title,
			actual = checks.viewer:tostring(actual),
			expected = checks.viewer:tostring(expected),
		}
		local results = info.results
		if results ~= nil then
			for i, name in ipairs(results) do
				except[name] = checks.viewer:tostring((select(i, ...)))
			end
		end
		return false, except
	end
	return true
end

local empty = {}

for name, info in pairs(checks) do
	checks[name] = function(expected, title, ...)
		local params = select("#", ...)
		if params == 0
			then params = empty
			else params = {n=params, ...}
		end
		return function(actual, invert)
			return doresult(info, title, actual, expected, not invert,
				info.op(actual, expected, unpack(params, 1, params.n)))
		end
	end
end


local MultipleEx = class{
	__concat = Exception.__concat,
}
function MultipleEx:__tostring()
	local result = {}
	for index = 1, #self do
		result[index] = tostring(self[index])
	end
	return concat(result, "\n\t")
end

local function checkand(conds, index, success, except, ...)
	if success and conds[index] then
		success, except = conds[index](...)
		return checkand(conds, index+1, success, except, ...)
	end
	return success, except
end

local function checkor(conds, index, errors, success, except, ...)
	if not success then
		errors[#errors+1] = except
		if conds[index] then
			success, except = conds[index](...)
			return checkor(conds, index+1, errors, success, except, ...)
		end
		return false, errors
	end
	return true
end


function checks.NOT(cond)
	return function(value) return cond(value, "negated") end
end

function checks.AND(...)
	local conds = {...}
	return function(value, invert)
		if invert then
			return checkor(conds, 1, MultipleEx(), false, "many failures:", value, invert)
		end
		return checkand(conds, 1, true, nil, value)
	end
end

function checks.OR(...)
	local conds = {...}
	return function(value, invert)
		if invert then
			return checkand(conds, 1, true, nil, value, invert)
		end
		return checkor(conds, 1, MultipleEx(), false, "many failures:", value)
	end
end


checks.viewer = Viewer
checks.error = _G.error

function checks.fail(message)
	checks.error(Exception{message}, 2)
end

local AND = checks.AND
function checks.assert(value, cond, ...)
	if select("#", ...) > 0 then cond = AND(cond, ...) end
	local success, except = cond(value)
	if not success then checks.error(except) end
	return success, except
end

return checks
