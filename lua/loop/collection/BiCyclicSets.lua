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

-- []:predecessor(item)               : nil --> []
-- [ ? ]:predecessor(item)            : nil --> [ ? ]
-- [ item ]:predecessor(item)         : item --> [ item ]
-- [ pred, item ? ]:predecessor(item) : pred --> [ pred, item ? ]
function predecessor(self, item)
	return self.back[item]
end

function backward(self, item)
	return rawget, self.back, item
end

function addto(self, place, item)
	if self[item] == nil then
		local succ
		if place == nil then
			place, succ = item, item
		else
			succ = self[place]
			if succ == nil then
				succ = place
			end
		end
		local back = self.back
		self[item] , back[succ] = succ, item
		self[place], back[item] = item, place
		return item
	end
end

function removefrom(self, place)
	local item = self[place]
	if item ~= nil then
		local back = self.back
		local succ = self[item]
		self[place], back[succ] = succ, place
		self[item] , back[item] = nil, nil
		return item
	end
end

function removeall(self, item)
	local back = self.back
	repeat
		item, self[item], back[item] = self[item], nil, nil
	until item == nil
end

function movetofrom(self, newplace, oldplace, lastitem)
	local theitem = self[oldplace]
	if theitem ~= nil then
		if lastitem == nil then lastitem = theitem end
		local oldsucc = self[lastitem]
		local newsucc
		if newplace == nil or newplace == theitem then
			newplace, newsucc = lastitem, theitem
		else
			newsucc = self[newplace]
			if newsucc == nil then
				newsucc = newplace
			end
		end
		local back = self.back
		self[oldplace], back[oldsucc] = oldsucc, oldplace
		self[lastitem], back[newsucc] = newsucc, lastitem
		self[newplace], back[theitem] = theitem, newplace
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
	back, self.back = self.back, nil
	local result = CyclicSets.disjoint(self)
	if back then self.back = back end
	return result
end

function __tostring(self, ...)
	local back
	back, self.back = self.back, nil
	local result = CyclicSets.__tostring(self, ...)
	if back then self.back = back end
	return result
end
