-- Project: LOOP - Lua Object-Oriented Programming
-- Release: 3.0 beta
-- Title  : Utility Functions for Table Manipulation
-- Author : Renato Maia <maia@inf.puc-rio.br>

local _G = require "_G"
local next = _G.next
local rawset = _G.rawset
local setmetatable = _G.setmetatable

local table = {}

--------------------------------------------------------------------------------
-- Copies all elements stored in a table to another.
-- 
-- Each pair of key and value stored in table 'source' will be set to table
-- 'destiny'.
-- If no 'destiny' table is defined, a new empty table is used.
-- 
-- @param source Table containing elements to be copied.
-- @param destiny [optional] Table which elements must be copied into.
-- 
-- @return Table containing copied elements.
-- 
-- @usage copied = table.copy(results)
-- @usage table.copy(results, copied)

function table.copy(source, destiny)
	if destiny == nil then destiny = {} end
	for key, value in next, source do
		rawset(destiny, key, value)
	end
	return destiny
end

--------------------------------------------------------------------------------
-- Clears all contents of a table.
-- 
-- All pairs of key and value stored in table 'source' will be removed by
-- setting nil to each key used to store values in table 'source'.
-- 
-- @param tab Table which must be cleared.
-- 
-- @usage assert(next(table.clear(results)) == nil)

function table.clear(table)
	for key in next, table do
		rawset(table, key, nil)
	end
	return table
end

--------------------------------------------------------------------------------
-- Creates a memoize table that caches the results of a function.
-- 
-- Creates a table that caches the results of a function that accepts a single
-- argument and returns a single value.
-- 
-- @param func Function which returned values must be cached.
-- @param weak [optional] String that defines the weak mode of the memoize.
-- 
-- @return Memoize table created.
-- 
-- @usage SquareRootOf = table.memoize(math.sqrt)

function table.memoize(func, weak)
	return setmetatable({}, {
		__mode = weak,
		__index = function(self, input)
			local output = func(input)
			if output ~= nil then
				self[input] = output
			end
			return output
		end,
	})
end

return table
