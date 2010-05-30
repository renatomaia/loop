-- Project: LOOP Class Library
-- Release: 2.3 beta
-- Title  : Tuple Mappper
-- Author : Renato Maia <maia@inf.puc-rio.br>


local _G = require "_G"
local pairs = _G.pairs
local select = _G.select
local unpack = _G.unpack

local coroutine = require "coroutine"
local yield = coroutine.yield
local wrap = coroutine.wrap

local oo = require "loop.base"
local class = oo.class
local rawnew = oo.rawnew

module(..., class)

WeakKeys = class{__mode="k"}



-- from a TupleKey to TupleValues (weak mode == "k")
ParentOf = WeakKeys()
ValueOf = WeakKeys()

-- from TupleValues to a TupleKey (weak mode == "kv")
local TupleKey = class{__mode = "kv"}
function TupleKey:__index(keyval)
	local key = TupleKey()
	ParentOf[key] = self
	ValueOf[key] = keyval
	self[keyval] = key
	return key
end

-- main TupleKey that represents the empty tuple
tuple = TupleKey()

-- find a TupleKey given its TupleValues
function findkey(...)
	local key = tuple
	for i = 1, select("#", ...) do
		key = key[select(i, ...)]
	end
	return key
end

-- get the TupleValues of a TupleKey
function unpackkey(key)
	local values = {}
	local i = 0
	while key ~= tuple do
		i = i-1
		key, values[i] = ParentOf[key], ValueOf[key]
	end
	return unpack(values, i, -1)
end



function __new(class, self)
	self = rawnew(class, self)
	if self.map == nil then self.map = {} end
	return self
end

function set(self, value, ...)
	self.map[findkey(...)] = value
end

function get(self, ...)
	return self.map[findkey(...)]
end

function entries(self)
	return wrap(function()
		for key, value in pairs(self.map) do
			yield(value, unpackkey(key))
		end
	end)
end



--local Viewer = _G.require "loop.debug.Viewer"
function nointernalstate(self)
--Viewer:print("ParentOf", ParentOf)
--Viewer:print("ValueOf ", ValueOf)
--Viewer:print("tuple   ", tuple)
--Viewer:print("map     ", self.map)
--if _G.rawget(self, "trap") then
--	Viewer:print("trap  ", self.trap)
--end
	return (_G.next(ParentOf) == nil)
	   and (_G.next(ValueOf) == nil)
	   and (_G.next(tuple) == nil)
	   and (_G.next(self.map) == nil)
	   and (not _G.rawget(self, "trap") or (_G.next(self.trap) == nil))
end
