local _G = require "_G"
local pairs = _G.pairs
local getmetatable = _G.getmetatable
local setmetatable = _G.setmetatable
local tostring = _G.tostring

local string = require "string"
local find = string.find

local tabop = require "loop.table"
local copy = tabop.copy

local t = {1,2,3,a="a",b="b",c="c"}
local f = function() end
local c = coroutine.create(f)
local u = io.stdout

local _ENV = require "loop.test.checks"
if like == nil then setfenv(1, _ENV) end

for op in pairs{[is]=true,[equal]=true,[like]=true} do
	assert(nil, op(nil))
	assert(false, op(false))
	assert(true, op(true))
	assert(123, op(123))
	assert("123", op("123"))
	assert(t, op(t))
	assert(f, op(f))
	assert(c, op(c))
	assert(u, op(u))
end

assert(nil, type("nil"))
assert(false, type("boolean"))
assert(true, type("boolean"))
assert(123, type("number"))
assert("123", type("string"))
assert(t, type("table"))
assert(f, type("function"))
assert(c, type("thread"))
assert(u, type("userdata"))

local wildcard1 = setmetatable({}, {__eq=function() return true end})
local wildcard2 = setmetatable({}, getmetatable(wildcard1))
assert(wildcard1, equal(wildcard2))
assert(wildcard2, equal(wildcard1))
assert(wildcard1, NOT(is(wildcard2)))
assert(wildcard2, NOT(is(wildcard1)))

local t_like = like(t)
assert(copy(t), t_like)
assert(setmetatable({},{__index=t}), t_like)

do
	local f = {}
	for i = 1, 2 do
		local t = copy(t)
		f[i] = function() return t,f,c,u end
	end
	assert(f[1], like(f[2]))
end

local isfalse = OR(is(nil), is(false))
assert(nil, isfalse)
assert(false, isfalse)

local istrue = NOT(isfalse)
assert(true, istrue)
assert(123, istrue)
assert("123", istrue)
assert(t, istrue)
assert(f, istrue)
assert(c, istrue)
assert(u, istrue)

local istrue = AND(NOT(is(nil)), NOT(is(false)))
assert(true, istrue)
assert(123, istrue)
assert("123", istrue)
assert(t, istrue)
assert(f, istrue)
assert(c, istrue)
assert(u, istrue)

local lasterr
function error(except)
	lasterr = except
end
local function asserterror(message, pattern)
	local cond = match(message, "wrong exception", 1, not pattern)
	local ok, ex = cond(tostring(lasterr))
	lasterr = nil
	if not ok then _G.error(ex) end
end

assert("one", is("other"))
asserterror('Exception: expected same values ("one" was not "other")')
assert("other", NOT(is("other")))
asserterror('Exception: not expected same values (value was "other")')
assert(1, equal(0))
asserterror('Exception: expected equal values (1 was not equal to 0)')
assert(0, NOT(equal(0)))
asserterror('Exception: not expected equal values (0 was equal to 0)')
assert(1, like(0))
asserterror('Exception: expected values alike (mismatch at "value: not matched", 1 was not like 0)')
assert(0, NOT(like(0)))
asserterror('Exception: not expected values alike (0 was like 0)')

do
	local f = {}
	for i = 1, 2 do
		local t = copy(t, {i=i})
		f[i] = function() return t,f,c,u end
	end
	assert(f[1], like(f[2]))
	asserterror('^Exception: expected values alike %(mismatch at "value%.t%.i: not matched", function: 0x[a-f0-9]+ was not like function: 0x[a-f0-9]+%)', true)
end

assert("123", type("number"))
asserterror('Exception: expected value of type (type of "123" was "string", not "number")')
assert(123, NOT(type("number")))
asserterror('Exception: not expected value of type (type of 123 was "number")')

assert("no number", match("%d+"))
asserterror('Exception: expected string pattern match ("no number" did not match "%d+")')
assert("number 123!", NOT(match("%d+")))
asserterror('Exception: not expected string pattern match ("number 123!" matched "%d+" at position 8..10)')
