-- Project: LOOP - Lua Object-Oriented Programming
-- Release: 3.0 beta
-- Title  : Utility Functions for Table Manipulation
-- Author : Renato Maia <maia@inf.puc-rio.br>

local _G = require "_G"
local next = _G.next
local rawset = _G.rawset
local setmetatable = _G.setmetatable

module "loop.table"

--------------------------------------------------------------------------------
-- Copies all elements stored in a table into another.
-- 
-- Each pair of key and value stored in table 'source' will be set into table
-- 'destiny'.
-- If no 'destiny' table is defined, a new empty table is used.
-- 
-- @param source Table containing elements to be copied.
-- @param destiny [optional] Table which elements must be copied into.
-- 
-- @return Table containing copied elements.
-- 
-- @usage copied = loop.table.copy(results)
-- @usage loop.table.copy(results, newcopy)

function copy(source, destiny)
	if source then
		if not destiny then destiny = {} end
		local field, value = next(source)
		while field ~= nil do
			rawset(destiny, field, value)
			field, value = next(source, field)
		end
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
-- @usage return loop.table.clear(results)

function clear(table)
	local field = next(table)
	while field ~= nil do
		rawset(table, field, nil)
		field = next(table, field)
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
-- @param weak [optional] String used to define the weak mode of the created table.
-- 
-- @return Memoize table created.
-- 
-- @usage SquareRootOf = loop.table.memoize(math.sqrt)

function memoize(func, weak)
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
