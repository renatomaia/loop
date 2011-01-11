-- Project: Lua Tuple
-- Release: 1.0 alpha
-- Title  : Collectable Internalized Tokens that Represent a Tuple of Values
-- Author : Renato Maia <maia@inf.puc-rio.br>


local _G = require "_G"
local getmetatable = _G.getmetatable
local next = _G.next
local newproxy = _G.newproxy
local pairs = _G.pairs
local select = _G.select
local setmetatable = _G.setmetatable
local tostring = _G.tostring
local type = _G.type

local table = require "table"
local concat = table.concat
local unpacktab = table.unpack or _G.unpack



local function memoize(func, weak)
	return setmetatable({}, {
		__mode = weak,
		__index = function(self, input)
			local output = func(input)
			self[input] = output
			return output
		end,
	})
end

local WeakKeys = {__mode="k"}
local WeakValues = {__mode="v"}
local WeakTable = {__mode="kv"}



-- from a tuple to values (weak mode == "kv")
local ParentOf = setmetatable({}, WeakTable)
local ValueOf = setmetatable({}, WeakTable)
local SizeOf = setmetatable({}, WeakKeys)

local function unpack(tuple)
	local values = {}
	local size = SizeOf[tuple]
	for i = size, 1, -1 do
		tuple, values[i] = ParentOf[tuple], ValueOf[tuple]
	end
	return unpacktab(values, 1, size)
end

local function size(tuple)
	return SizeOf[tuple]
end



local index -- main tuple that represents the empty tuple
local UseTrapOf -- trap to be collected when a tuple is not used (see below)
local UseMarkOf = setmetatable({}, WeakKeys) -- mark that tuple uses its parent
local UseTrapCnt -- number of available/freed usetraps (see 'clearpools')
local UseTrapPool -- list of available/freed usetraps (see 'clearpools')

-- free all resources of a tuple if it is not used anymore
local function freetuple(tuple)
	while next(tuple) == nil do -- no [value]=subtuple nor [map]=usetrap
		local usetrap = UseTrapOf[tuple]
		if usetrap then
			UseTrapOf[tuple] = nil
			UseTrapCnt = UseTrapCnt+1
			UseTrapPool[UseTrapCnt] = usetrap
		end
		local value = ValueOf[tuple]
		ValueOf[tuple] = nil
		if tuple ~= index then SizeOf[tuple] = nil end
		UseMarkOf[tuple] = nil
		tuple, ParentOf[tuple] = ParentOf[tuple], nil
		if tuple == nil then break end
		if value ~= nil then tuple[value] = nil end
	end
end

local function unused(trap)
	local tuple = getmetatable(trap).tuple
	if tuple ~= nil then -- the tuple was not collected yet
		freetuple(tuple)
	end
end

-- traps that are collected when the tuple is not used anymore
UseTrapOf = memoize(function(tuple)
	local trap
	if UseTrapCnt == 0 then
		trap = newproxy(true)
		local meta = getmetatable(trap)
		setmetatable(meta, WeakValues) -- let value of field 'tuple' to be collected
		meta.tuple = tuple
		meta.__gc = unused -- won't be collected because it is a local function
	else
		trap = UseTrapPool[UseTrapCnt]
		UseTrapPool[UseTrapCnt] = nil
		UseTrapCnt = UseTrapCnt-1
		getmetatable(trap).tuple = tuple
	end
	return trap
end, "kv")



-- from values to a tuple (weak mode == "k")
local Tuple = {__mode="k", __len=size}

function Tuple:__index(value)
	local tuple = setmetatable({}, Tuple)
	ParentOf[tuple] = self
	ValueOf[tuple] = value
	SizeOf[tuple] = SizeOf[self]+1
	UseMarkOf[tuple] = UseTrapOf[self] -- avoid collection of parent's usetrap
	self[value] = tuple
	return tuple
end

function Tuple:__call(i)
	if i == nil then return unpack(self) end
	local size = SizeOf[self]
	if i == "#" then return size end
	if i > 0 then i = i-size-1 end
	if i < 0 then
		for _ = 1, -i-1 do
			self = ParentOf[self]
		end
		return ValueOf[self]
	end
end

function Tuple:__tostring()
	local values = {}
	for i = SizeOf[self], 1, -1 do
		self, values[i] = ParentOf[self], tostring(ValueOf[self])
	end
	return "<"..concat(values, ", ")..">"
end

-- main tuple that represents the empty tuple
index = setmetatable({}, Tuple)
SizeOf[index] = 0

-- find a tuple given its values
local function create(...)
	local tuple = index
	for i = 1, select("#", ...) do
		tuple = tuple[select(i, ...)]
	end
	return tuple
end



local EntryTrapCnt -- number of available/freed entrytraps
local EntryTrapPool -- list of available/freed entrytraps

-- called when the *weak value* of a map entry is collected
local function entrytrap(self)
	self = self.__index
	self.__gc = nil -- metafields should not interfere in the interation below
	self.__index = nil
	self.__newindex = nil
	for tuple, map in pairs(self) do
		tuple[map] = nil -- tuple not used in this map, usetrap may become garbage
	end
end

local function newentrytrap()
	local trap
	if EntryTrapCnt == 0 then
		trap = newproxy(true)
		local meta = getmetatable(trap)
		setmetatable(meta, WeakKeys) -- allow that trapped tuple be collected
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

local function freeentry(trapof, map, tuple, value)
	local trap = trapof[value]
	trap[tuple] = nil -- remove tuple from list of entries to be removed by trap
	for tuple, val in pairs(trap.__index) do
		if val == map then return end -- used for other entries with same 'value'
	end -- free trap to be reused later
	trapof[value] = nil
	EntryTrapCnt = EntryTrapCnt+1
	EntryTrapPool[EntryTrapCnt] = trap
end



local Collectable = {
	["function"] = true,
	table = true,
	thread = true,
	userdata = true,
}

local EntryTrapsOf = memoize(function(map)
	local meta = getmetatable(map)
	if meta then
		local mode = meta.__mode
		if mode and mode:find("v", 1, true) then
			return memoize(newentrytrap, "k") -- use entry GC traps
		end
	end
	return false
end, "k")

local function setkey(map, tuple, value)
	local trap = EntryTrapsOf[map]
	if trap then
		local old = map[tuple]
		if old ~= nil and Collectable[type(old)] then
			freeentry(trap, map, tuple, old)
		end
	end
	map[tuple] = value
	if value == nil then
		tuple[map] = nil -- allow collection of usetrap if tuple not used anymore
	else
		tuple[map] = UseTrapOf[tuple] -- avoid collection of usetrap of tuple
		if trap and Collectable[type(value)] then
			trap[value][tuple] = map -- setup an EntryTrap for this entry (tuple)
		end
	end
end

local function getkey(map, tuple)
	local value = map[tuple]
	if value == nil then freetuple(tuple) end
	return value
end



local function clearpools()
	UseTrapCnt = 0
	UseTrapPool = {}
	EntryTrapCnt = 0
	EntryTrapPool = {}
end

clearpools()



return {
	index = index,
	create = create,
	unpack = unpack,
	size = size,
	
	setkey = setkey,
	getkey = getkey,
	freetuple = freetuple,
	clearpools = clearpools,
	
	emptystate = function()
		return (_G.next(ParentOf) == nil)
		   and (_G.next(ValueOf) == nil)
		   and (_G.next(SizeOf) == index and _G.next(SizeOf, index) == nil)
		   and (_G.next(UseTrapOf) == nil)
		   and (_G.next(UseMarkOf) == nil)
		   and (_G.next(index) == nil)
		
		or (function()
			local Viewer = _G.require "loop.debug.Viewer"
			Viewer:print("ParentOf ", ParentOf)
			Viewer:print("ValueOf  ", ValueOf)
			Viewer:print("SizeOf   ", SizeOf)
			Viewer:print("UseTrapOf", UseTrapOf)
			Viewer:print("UseMarkOf", UseMarkOf)
			Viewer:print("index    ", index)
		end)()
	end,
}
