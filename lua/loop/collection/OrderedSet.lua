-- Project: LOOP Class Library
-- Release: 2.3 beta
-- Title  : Ordered Set Optimized for Insertions and Removals
-- Author : Renato Maia <maia@inf.puc-rio.br>
-- Notes  :
--   Can be used as a module that provides functions instead of methods.
--   Instance of this class should not store the name of methods as values.
--   To avoid the previous issue, use this class as a module on a simple table.
--   It cannot store itself, because this place is reserved.
--   Each element is stored as a key mapping to its successor.


local _G = require "_G"
local tostring = _G.tostring

local table = require "table"
local concat = table.concat

local oo = require "loop.base"
local rawnew   = oo.rawnew

local CyclicSets = require "loop.collection.CyclicSets"
local addto = CyclicSets.add
local removeat = CyclicSets.removefrom

module(..., oo.class)

contains = CyclicSets.contains
sequence = CyclicSets.forward

function empty(self)
	return self[self] == nil
end

function first(self)
	return self[ self[self] ]
end

function last(self)
	return self[self]
end

function successor(self, item)
	local last = self[self]
	if item ~= last then
		if item == nil then item = last end
		return self[item]
	end
end

function insert(self, item, place)
	local last = self[self]
	if place == nil then place = last end
	if self:contains(place) and addto(self, item, place) == item then
		if place == last then self[self] = item end
		return item
	end
end

function removefrom(self, place)
	local last = self[self]
	if place ~= last then
		if place == nil then place = last end
		local item = removeat(self, place)
		if item ~= nil then
			if item == last then self[self] = place end
			return item
		end
	end
end

function pushfront(self, item)
	local last = self[self]
	if addto(self, item, last) == item then
		if last == nil then self[self] = item end
		return item
	end
end

function popfront(self)
	local last = self[self]
	if self[last] == last then
		self[self] = nil
	end
	return removefrom(self, last)
end

function pushback(self, item)
	local last = self[self]
	if addto(self, last, item) == item then
		self[self] = item
		return item
	end
end

function __tostring(self)
	local result = { "[ " }
	for item in self:sequence() do
		result[#result+1] = tostring(item)
		result[#result+1] = ", "
	end
	local last = #result
	result[last] = (last == 1) and "[]" or " ]"
	return concat(result)
end

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
