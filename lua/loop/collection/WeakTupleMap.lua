-- Project: LOOP Class Library
-- Release: 2.3 beta
-- Title  : Tuple Mappper
-- Author : Renato Maia <maia@inf.puc-rio.br>


local _G = require "_G"
local getmetatable = _G.getmetatable
local next = _G.next
local newproxy = _G.newproxy
local pairs = _G.pairs
local select = _G.select
local type = _G.type
local unpack = _G.unpack

local coroutine = require "coroutine"
local yield = coroutine.yield
local wrap = coroutine.wrap

local tabop = require "loop.table"
local memoize = tabop.memoize

local oo = require "loop.base"
local class = oo.class
local rawnew = oo.rawnew

module(..., class)

local WeakKeys = class{__mode="k"}
local WeakValues = class{__mode="v"}
local WeakTable = class{__mode="kv"}



-- from a TupleKey to TupleValues (weak mode == "kv")
local ParentOf = WeakTable()
local ValueOf = WeakTable()
local UsageOf = WeakKeys() -- mark that a TupleKey uses its parent



local UseTrapCnt -- number of available/freed usetraps
local UseTrapPool -- list of available/freed usetraps

-- traps that are collected when the TupleKey is not used anymore
local unusedkey
local UseTrapOf = memoize(function(key)
	local trap
	if UseTrapCnt == 0 then
		trap = newproxy(true)
		local meta = getmetatable(trap)
		WeakValues(meta) -- allow that value of field 'key' (TupleKey) be collected
		meta.__gc = unusedkey -- won't be collected because it is a local function
		meta.key = key
	else
		trap = UseTrapPool[UseTrapCnt]
		UseTrapPool[UseTrapCnt] = nil
		UseTrapCnt = UseTrapCnt-1
		getmetatable(trap).key = key
	end
	return trap
end, "kv") -- allow TupleKey and the trap to be collected is they are not used

-- free all resources of a TupleKey not used anymore
function unusedkey(self)
	local key = getmetatable(self).key
	if key ~= nil then -- is the TupleKey was not collected yet
		while next(key) == nil do -- no [keyval]=subTupleKey nor [map]=UseTrap
			local usetrap = UseTrapOf[key]
			if usetrap ~= self then
				UseTrapOf[key] = nil
				UseTrapCnt = UseTrapCnt+1
				UseTrapPool[UseTrapCnt] = usetrap
			end
			local keyval = ValueOf[key]
			key, ParentOf[key],ValueOf[key],UsageOf[key] = ParentOf[key], nil,nil,nil
			if key == nil then break end
			if keyval ~= nil then key[keyval] = nil end
		end
	end
end



-- from TupleValues to a TupleKey (weak mode == "k")
local TupleKey = class{__mode="k"}
function TupleKey:__index(keyval)
	local key = TupleKey()
	ParentOf[key] = self
	ValueOf[key] = keyval
	UsageOf[key] = UseTrapOf[self] -- avoid collection of parent's UseTrap
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
	local keyval
	local i = 0
	while key ~= tuple do
		i = i-1
		key, keyval = ParentOf[key], ValueOf[key]
		if key == nil or keyval == nil then return end -- TupleValues collected
		values[i] = keyval
	end
	return unpack(values, i, -1)
end



local EntryTrapCnt -- number of available/freed entrytraps
local EntryTrapPool -- list of available/freed entrytraps

-- called when the *weak value* of a map entry is collected
local function entrytrap(self)
	self = self.__index
	self.__gc = nil -- should not interfere in the interation below
	self.__index = nil -- should not interfere in the interation below
	self.__newindex = nil -- should not interfere in the interation below
	for key, map in pairs(self) do
		key[map] = nil -- TupleKey not used in this map, UseTrap may become garbage
	end
end

local function newentrytrap()
	local trap
	if EntryTrapCnt == 0 then
		trap = newproxy(true)
		local meta = getmetatable(trap)
		WeakKeys(meta) -- allow that trapped 'tuple keys' be collected
		meta.__gc = entrytrap
		meta.__index = meta -- easy/fast access to table
		meta.__newindex = meta -- easy/fast access to table
	else
		trap = EntryTrapPool[EntryTrapCnt]
		EntryTrapPool[EntryTrapCnt] = nil
		EntryTrapCnt = EntryTrapCnt-1
	end
	return trap
end

local function freeentry(trapof, map, key, value)
	local trap = trapof[value]
	trap[key] = nil -- remove TupleKey from list of entries to be removed by trap
	for key, val in pairs(trap.__index) do
		if val == map then return end -- used for other entries with same 'value'
	end -- free trap to be reused later
	trapof[value] = nil
	EntryTrapCnt = EntryTrapCnt+1
	EntryTrapPool[EntryTrapCnt] = trap
end



function __new(self, ...)
	self = rawnew(self, ...)
	local map = self.map
	if map == nil then
		self.map = WeakKeys()
	else
		local meta = getmetatable(map)
		if meta then
			local mode = meta.__mode
			if mode and mode:find("v", 1, true) then
				self.trap = memoize(newentrytrap, "k") -- use entry GC traps
			end
		end
	end
	return self
end

local Collectable = {
	["function"] = true,
	table = true,
	thread = true,
	userdata = true,
}
function setkey(self, key, value)
	local map = self.map
	local trap = self.trap
	if trap then
		local old = map[key]
		if old ~= nil and Collectable[type(old)] then
			freeentry(trap, self, key, old)
		end
	end
	map[key] = value
	if value == nil then
		key[self] = nil -- allow collection of UseTrap if TupleKey not used anymore
	else
		key[self] = UseTrapOf[key] -- avoid collection of UseTrap of TupleKey
		if trap and Collectable[type(value)] then
			trap[value][key] = self -- setup an EntryTrap for this entry (TupleKey)
		end
	end
end

function set(self, value, ...)
	self:setkey(findkey(...), value)
end

function get(self, ...)
	return self.map[findkey(...)]
end

-- iterate for all entries which TupleValues were not collected
local function yieldentry(value, ...)
	if ... ~= nil then yield(value, ...) end -- TupleValues not collected yet
end
function entries(self)
	return wrap(function()
		for key, value in pairs(self.map) do
			yieldentry(value, unpackkey(key))
		end
	end)
end



function clearpools()
	UseTrapCnt = 0
	UseTrapPool = {}
	EntryTrapCnt = 0
	EntryTrapPool = {}
end

clearpools()

--local Viewer = _G.require "loop.debug.Viewer"
function nointernalstate(self)
--Viewer:print("ParentOf", ParentOf)
--Viewer:print("ValueOf ", ValueOf)
--Viewer:print("UsageOf ", UsageOf)
--Viewer:print("tuple   ", tuple)
--Viewer:print("map     ", self.map)
--if _G.rawget(self, "trap") then
--	Viewer:print("trap  ", self.trap)
--end
	return (_G.next(ParentOf) == nil)
	   and (_G.next(ValueOf) == nil)
	   and (_G.next(UsageOf) == nil)
	   and (_G.next(tuple) == nil)
	   and (_G.next(self.map) == nil)
	   and (not _G.rawget(self, "trap") or (_G.next(self.trap) == nil))
end
