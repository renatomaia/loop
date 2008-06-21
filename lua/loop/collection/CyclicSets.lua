local I = require("loop.debug.Inspector")()
local print = print
local io = io
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
-- Title  : Interchangeble Cyclic Sets Combined in a Single Table             --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------
-- Notes:                                                                     --
--   Storage of strings equal to the name of one method prevents its usage.   --
--------------------------------------------------------------------------------

require "_G"
local table = require "loop.table"
local oo    = require "loop.base"

local ipairs   = ipairs
local next     = next
local pairs    = pairs
local tostring = tostring
local unpack   = unpack
local rawget   = rawget
local concat   = table.concat
local copy     = table.copy
local rawnew   = oo.rawnew

--------------------------------------------------------------------------------
-- key constants ---------------------------------------------------------------
--------------------------------------------------------------------------------

module(..., oo.class)

function __init(self, object)
	self = rawnew(self, object)
	self.next     = self.next or {}
	self.previous = self.previous or {}
	return self
end

function contains(self, item)
	return self.next[item] ~= nil
end

function after(self, item)
	return self.next[item]
end

function before(self, item)
	return self.previous[item]
end

function forward(self, item)
	return rawget, self.next, item
end

function backward(self, item)
	return rawget, self.previous, item
end

function add(self, item)
	local next = self.next
	if next[item] == nil then
		local previous = self.previous
		next[item] = item
		previous[item] = item
		return item
	end
end

function remove(self, item)
	local next = self.next
	local after = next[item]
	if after ~= nil then
		local previous = self.previous
		local before = previous[item]
		next[before] = after
		next[item] = nil
		previous[after] = before
		previous[item] = nil
		return item
	end
end

function addto(self, position, item)
	local next = self.next
	local previous = self.previous
	local place = previous[position]
	if place ~= nil and next[item] == nil then
		next[item] = position
		next[place] = item
		previous[item] = place
		previous[position] = item
		return item
	end
end

function moveto(self, position, item, last)
	if last == nil then last = item end
	local next = self.next
	local previous = self.previous
	local place  = previous[position]
	local before = previous[item]
	local after  = next[last]
	if place ~= nil and before ~= nil and after ~= nil then
		-- TODO: remove [item;last] from previous place
		next[before] = after
		previous[after] = before
		-- TODO: reinsert [item;last] in position
		next[last] = position
		next[place] = item
		previous[item] = place
		previous[position] = last
		
		return item
	end
end

function disjoint(self)
	local items = self.next
	local result = {}
	local missing = {}
	for item in pairs(items) do
		missing[item] = true
	end
	local start = next(missing)
	while start do
		result[#result+1] = start
		local item = start
		repeat
			missing[item] = nil
			item = items[item]
		until item == start
		start = next(missing)
	end
	return result
end

function __tostring(self)
	local items = self.next
	local result = {}
	local missing = {}
	for item in pairs(items) do
		missing[item] = true
	end
	local start = next(missing)
	while start do
		result[#result+1] = "[ "
		local item = start
		repeat
			result[#result+1] = tostring(item)
			result[#result+1] = " "
			missing[item] = nil
			item = items[item]
		until item == start
		result[#result+1] = "]"
		start = next(missing)
	end
	return concat(result)
end
