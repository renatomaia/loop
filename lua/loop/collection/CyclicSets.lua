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
-- Title  : Interchangeable Disjoint Cyclic Sets                              --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------

local global = require "_G"
local table  = require "loop.table"
local oo     = require "loop.base"

local next   = global.next
local rawget = global.rawget
local copy   = table.copy
local rawnew = oo.rawnew

module(..., oo.class)

-- []:contains(item)          : false --> []
-- [ ... ]:contains(item)     : false --> [ ... ]
-- [ item... ]:contains(item) : true --> [ item, succ... ]
function contains(self, item)
	return (self.next or self)[item] ~= nil
end

-- []:successor(item)                : nil --> []
-- [ ... ]:successor(item)           : nil --> [ ... ]
-- [ item ]:successor(item)          : item --> [ item ]
-- [ item, succ... ]:successor(item) : succ --> [ item, succ... ]
function successor(self, item)
	return (self.next or self)[item]
end

function forward(self, item)
	return rawget, (self.next or self), item
end

-- []:addto()                            : ERROR: table index is nil --> []
-- []:addto(place)                       : ERROR: table index is nil --> []
-- []:addto(nil, item)                   : item --> [ item ]
-- []:addto(place, item)                 : item --> [ place, item ]
-- [ ... ]:addto()                       : ERROR: table index is nil --> [ ... ]
-- [ ... ]:addto(place)                  : ERROR: table index is nil --> [ ... ]
-- [ ... ]:addto(nil, item)              : item --> [ item | ... ]
-- [ ... ]:addto(place, item)            : item --> [ place, item | ... ]
-- [ place... ]:addto(place, item)       : item --> [ place, item... ]
-- [ item... ]:addto(place, item)        : nil  --> [ item... ]
-- [ place, item... ]:addto(place, item) : nil  --> [ place, item... ]
function addto(self, place, item)
	local next = self.next or self
	if next[item] == nil then
		local succ
		if place == nil then
			place, succ = item, item
		else
			succ = next[place]
			if succ == nil then
				succ = place
			end
		end
		next[item]  = succ
		next[place] = item
		return item
	end
end

-- []:removefrom()                      : nil  --> []
-- []:removefrom(place)                 : nil  --> []
-- [ ... ]:removefrom()                 : nil  --> []
-- [ ... ]:removefrom(place)            : nil  --> [ ... ]
-- [ place, item... ]:removefrom(place) : item --> [ place... ]
function removefrom(self, place)
	local next = self.next or self
	local item = next[place]
	if item ~= nil then
		next[place] = next[item]
		next[item] = nil
		return item
	end
end

-- []:removeall()                     : ERROR: table index is nil --> []
-- []:removeall(item)                 : nil --> []
-- [ ... ]:removeall()                : ERROR: table index is nil --> [ ... ]
-- [ ... ]:removeall(item)            : nil --> [ ... ]
-- [ item... ]:removeall(item)        : nil --> []
-- [ item... | .... ]:removeall(item) : nil --> [ .... ]
function removeall(self, item)
	local next = self.next or self
	repeat
		item, next[item] = next[item], nil
	until item == nil
end

-- []:movetofrom()                                              : nil  --> []
-- []:movetofrom(nil, old)                                      : nil  --> []
-- []:movetofrom(new, old)                                      : nil  --> []
-- [ ... ]:movetofrom()                                         : nil  --> [ ... ]
-- [ ... ]:movetofrom(nil, old)                                 : nil  --> [ ... ]
-- [ ... ]:movetofrom(new, old)                                 : nil  --> [ ... ]
-- [ new... ]:movetofrom(new, old)                              : nil  --> [ new... ]
--
-- [ old, item... ]:movetofrom(nil, old)                        : item --> [ old... | item ]
-- [ old, item... ]:movetofrom(new, old)                        : item --> [ old... | new, item ]
-- [ old, item..new... ]:movetofrom(new, old)                   : item --> [ old..new, item... ]
-- [ old, item... | new.... ]:movetofrom(new, old)              : item --> [ old... | new, item.... ]
--
-- [ old, item..last... ]:movetofrom(nil, old, last)            : item --> [ old... | item..last ]
-- [ old, item..last... ]:movetofrom(new, old, last)            : item --> [ old... | new, item..last ]
-- [ old, item..last...new.... ]:movetofrom(new, old, last)     : item --> [ old...new, item..last.... ]
-- [ old, item..last... | new.... ]:movetofrom(new, old, last)  : item --> [ old... | new, item..last.... ]
--
-- [ old, item... ]:movetofrom(nil, old, last)                  : item --> INCONSISTENT STATE
-- [ old, item... ]:movetofrom(new, old, last)                  : item --> INCONSISTENT STATE
-- [ old, item..new... ]:movetofrom(new, old, last)             : item --> INCONSISTENT STATE
-- [ old, item... | new.... ]:movetofrom(new, old, last)        : item --> INCONSISTENT STATE
-- [ old, item | last... ]:movetofrom(nil, old, last)           : item --> INCONSISTENT STATE
-- [ old, item | last... ]:movetofrom(new, old, last)           : item --> INCONSISTENT STATE
-- [ old, item | last..new... ]:movetofrom(new, old, last)      : item --> INCONSISTENT STATE
-- [ old, item | last... | new.... ]:movetofrom(new, old, last) : item --> INCONSISTENT STATE
function movetofrom(self, newplace, oldplace, lastitem)
	local next = self.next or self
	local theitem = next[oldplace]
	if theitem ~= nil then
		if lastitem == nil then lastitem = theitem end
		local oldsucc = next[lastitem]
		local newsucc
		if newplace == nil then
			newplace, newsucc = lastitem, theitem
		else
			newsucc = next[newplace]
			if newsucc == nil then
				newsucc = newplace
			end
		end
		next[oldplace] = oldsucc
		next[lastitem] = newsucc
		next[newplace] = theitem
		return theitem
	end
end

function disjoint(self)
	local items = self.next or self
	local result = {}
	local missing = copy(items)
	local start = next(missing)
	while start ~= nil do
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

function __tostring(self, tostring, concat, delimiter)
	tostring = tostring or global.tostring
	concat = concat or global.table.concat
	local items = self.next or self
	local result = {}
	local missing = copy(items)
	local start = next(missing)
	result[#result+1] = "[ "
	while start ~= nil do
		local item = start
		repeat
			result[#result+1] = tostring(item)
			result[#result+1] = ", "
			missing[item] = nil
			item = items[item]
		until item == start
		result[#result] = " | "
		start = next(missing)
	end
	local last = #result
	result[last] = (last == 1) and "[]" or " ]"
	return concat(result)
end
