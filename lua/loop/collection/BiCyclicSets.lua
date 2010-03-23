-- Project: LOOP Class Library
-- Release: 2.3 beta
-- Title  : Interchangeable Disjoint Bidirectional Cyclic Sets
-- Author : Renato Maia <maia@inf.puc-rio.br>
-- Notes  :
--   Can be used as a module that provides functions instead of methods.
--   Instance of this class should not store the name of methods as values.
--   To avoid the previous issue, use this class as a module on a simple table.
--   Each element is stored as a key mapping to its successor.
--   An extra table stores each element as a key mapping to its predecessor.


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

local reverseof = memoize(function() return {} end, "k")

function reverse(self)
	return reverseof[self]
end

-- []:predecessor(item)               : nil --> []
-- [ ? ]:predecessor(item)            : nil --> [ ? ]
-- [ item ]:predecessor(item)         : item --> [ item ]
-- [ pred, item ? ]:predecessor(item) : pred --> [ pred, item ? ]
function predecessor(self, item)
	return reverseof[self][item]
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
		local back = reverseof[self]
		self[item] , back[succ] = succ, item
		self[place], back[item] = item, place
		return item
	end
end

function removefrom(self, place)
	local item = self[place]
	if item ~= nil then
		local back = reverseof[self]
		local succ = self[item]
		self[place], back[succ] = succ, place
		self[item] , back[item] = nil, nil
		return item
	end
end

function removeset(self, item)
	local back = reverseof[self]
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
			local back = reverseof[self]
			self[oldplace], back[oldsucc] = oldsucc, oldplace
			self[lastitem], back[newsucc] = newsucc, lastitem
			self[newplace], back[theitem] = theitem, newplace
			return theitem
		end
	end
end

function remove(self, item)
	return self:removefrom(reverseof[self][item])
end

function move(self, item, place, last)
	local oldplace = reverseof[self][item]
	if oldplace ~= nil then
		return self:movefrom(oldplace, place, last)
	end
end

__tostring = CyclicSets.__tostring
