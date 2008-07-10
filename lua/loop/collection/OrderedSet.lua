--------------------------------------------------------------------------------
---------------------- ##       #####    #####   ######  -----------------------
---------------------- ##      ##   ##  ##   ##  ##   ## -----------------------
---------------------- ##      ##   ##  ##   ##  ######  -----------------------
---------------------- ##      ##   ##  ##   ##  ##      -----------------------
---------------------- ######   #####    #####   ##      -----------------------
----------------------                                   -----------------------
----------------------- Lua Object-Oriented Programming ------------------------
--------------------------------------------------------------------------------
-- Project: LOOP Class Library                                                --
-- Release: 2.3 beta                                                          --
-- Title  : Ordered Set Optimized for Insertions and Removals                 --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------

local oo         = require "loop.base"
local CyclicSets = require "loop.collection.CyclicSets"

local rawnew   = oo.rawnew
local addto    = CyclicSets.addto
local getsucc  = CyclicSets.successor
local removeat = CyclicSets.removefrom

local INIT = newproxy()
local LAST = newproxy()

module(..., oo.class)

contains = CyclicSets.contains

function __init(self, object)
	self = rawnew(self, object)
	addto(self, nil, INIT)
	self[LAST] = INIT
	return self
end

function empty(self)
	local next = self.next or self
	return next[INIT] == INIT
end

function first(self)
	local next = self.next or self
	local item = next[INIT]
	if item ~= INIT then return item end
end

function last(self)
	local next = self.next or self
	local item = next[LAST]
	if item ~= INIT then return item end
end

function successor(self, item)
	item = getsucc(self, item)
	if item ~= INIT then return item end
end

local function iterator(next, prev)
	local item = next[prev]
	if item ~= INIT then return item, prev end
end
function sequence(self, from)
	if from == nil then from = INIT end
	return iterator, (self.next or self), from
end

function insert(self, item, place)
	local next = self.next or self
	local last = next[LAST]
	if place == nil then place = last end
	if self:contains(place) and addto(self, place, item) == item then
		if place == last then next[LAST] = item end
		return item
	end
end

function removefrom(self, place)
	local next = self.next or self
	local last = next[LAST]
	if place ~= last then
		local item = removeat(self, place)
		if item ~= nil then
			if item == last then next[LAST] = place end
			return item
		end
	end
end

function previous(self, item, from)
	if self:contains(item) then
		for found, previous in self:sequence(from) do
			if found == item then return previous end
		end
	end
end

function remove(self, item, ...)
	return self:removefrom(self:previous(item, ...))
end

function pushfront(self, item)
	return self:insert(item, INIT)
end

function popfront(self)
	return self:removefrom(INIT)
end

pushback = insert

--------------------------------------------------------------------------------

-- set aliases
add = pushback

-- stack aliases
push = pushfront
pop = popfront
top = first

-- queue aliases
enqueue = pushback
dequeue = popfront
head = first
tail = last

firstkey = INIT

--------------------------------------------------------------------------------

function __tostring(self, tostring, concat)
	local next = self.next or self
	tostring = tostring or global.tostring
	concat = concat or global.table.concat
	local result = { "[ " }
	for item in self:sequence() do
		result[#result+1] = tostring(item)
		result[#result+1] = ", "
	end
	local last = #result
	result[last] = (last == 1) and "[]" or " ]"
	return concat(result)
end
