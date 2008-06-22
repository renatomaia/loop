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
-- Title  : Interchangeable Disjoint Bidirectional Cyclic Sets                --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------

local global     = require "_G"
local oo         = require "loop.simple"
local CyclicSets = require "loop.collection.CyclicSets"

local rawget = global.rawget
local rawnew = oo.rawnew

module(...)

oo.class(_M, CyclicSets)

function __init(self, object)
	self = rawnew(self, object)
	self.back = self.back or {}
	return self
end

function antecessor(self, item)
	return self.back[item]
end

function backward(self, item)
	return rawget, self.back, item
end

-- []:add(item)                   : item --> [item]
-- []:add(place, item)            : item --> [place, item]
-- [place]:add(place, item)       : item --> [place, item]
-- [item]:add(place, item)        : nil  --> [item]
-- [place, item]:add(place, item) : nil  --> [place, item]
function add(self, place, item)
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
		local back = self.back
		next[item] , back[succ] = succ, item
		next[place], back[item] = item, place
		return item
	end
end

-- []:remove(place)            : nil  --> []
-- [item]:remove(place)        : nil  --> [item]
-- [place, item]:remove(place) : item --> [place]
function removefrom(self, place)
	local next = self.next or self
	local item = next[place]
	if item ~= nil then
		local back = self.back
		local succ = next[item]
		next[place], back[succ] = succ, place
		next[item] , back[item] = nil, nil
		return item
	end
end

-- []:moveto(new, old)                           : nil  --> []
-- [new]:moveto(new, old)                        : nil  --> [new]
-- [old, item]:moveto(new, old)                  : item --> [old|new, item]
-- [old, item|new]:moveto(new, old)              : item --> [old|new, item]
-- [old, item...last|new]:moveto(new, old, last) : item --> [old|new, item...last]
-- [old, item|new]:moveto(new, old, last)        : item --> INCONSISTENT STATE
-- [old, item|last...]:moveto(new, old, last)    : item --> INCONSISTENT STATE
function movetofrom(self, newplace, oldplace, lastitem)
	local next = self.next or self
	local theitem = next[oldplace]
	if lastitem == nil then lastitem = theitem end
	if theitem ~= nil then
		local back = self.back
		local oldsucc = next[lastitem]
		local newsucc = next[newplace]
		next[oldplace], back[oldsucc] = oldsucc, oldplace
		next[lastitem], back[newsucc] = newsucc, lastitem
		next[newplace], back[theitem] = theitem, newplace
		return theitem
	end
end

function remove(self, item)
	return self:removefrom(self.back[item])
end

function moveto(self, place, item, last)
	return self:movetofrom(place, self.back[item], last)
end

function disjoint(self)
	local back
	if self.next == nil then back, self.back = self.back, nil end
	local result = CyclicSets.disjoint(self)
	if back then self.back = back end
	return result
end

function __tostring(self, ...)
	local back
	if self.next == nil then back, self.back = self.back, nil end
	local result = CyclicSets.__tostring(self, ...)
	if back then self.back = back end
	return result
end
