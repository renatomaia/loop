--------------------------------------------------------------------------------
-- Project: LOOP Class Library                                                --
-- Release: 2.3 beta                                                          --
-- Title  : Interchangeable Disjoint Bidirectional Cyclic Sets                --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------

local _G = require "_G"
local rawget = _G.rawget

local table = require "loop.table"
local memoize = table.memoize

local oo = require "loop.simple"
local class = oo.class
local rawnew = oo.rawnew

local CyclicSets = require "loop.collection.CyclicSets"

module(...)

class(_M, CyclicSets)

local invertedof = memoize(function() return {} end, "k")

function inverted(self)
	return invertedof[self]
end

-- []:predecessor(item)               : nil --> []
-- [ ? ]:predecessor(item)            : nil --> [ ? ]
-- [ item ]:predecessor(item)         : item --> [ item ]
-- [ pred, item ? ]:predecessor(item) : pred --> [ pred, item ? ]
function predecessor(self, item)
	return invertedof[self][item]
end

function backward(self, place)
	return self.predecessor, self, place
end

function add(self, item, place)
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
		local back = invertedof[self]
		self[item] , back[succ] = succ, item
		self[place], back[item] = item, place
		return item
	end
end

function removefrom(self, place)
	local item = self[place]
	if item ~= nil then
		local back = invertedof[self]
		local succ = self[item]
		self[place], back[succ] = succ, place
		self[item] , back[item] = nil, nil
		return item
	end
end

function removeset(self, item)
	local back = invertedof[self]
	repeat
		item, self[item], back[item] = self[item], nil, nil
	until item == nil
end

function movefrom(self, oldplace, newplace, lastitem)
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
		if newplace ~= oldplace then
			local back = invertedof[self]
			self[oldplace], back[oldsucc] = oldsucc, oldplace
			self[lastitem], back[newsucc] = newsucc, lastitem
			self[newplace], back[theitem] = theitem, newplace
			return theitem
		end
	end
end

function remove(self, item)
	return self:removefrom(invertedof[self][item])
end

function move(self, item, place, last)
	local oldplace = invertedof[self][item]
	if oldplace ~= nil then
		return self:movefrom(oldplace, place, last)
	end
end
