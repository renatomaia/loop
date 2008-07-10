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
-- Title  : Unordered Array Optimized for Containment Check                   --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------
-- Notes:                                                                     --
--   Can only store non-numeric values.                                       --
--   Storage of strings equal to the name of one method prevents its usage.   --
--------------------------------------------------------------------------------

local global = require "_G"
local oo     = require "loop.base"

module(..., oo.class)

valueat = global.rawget

function indexof(self, value)
	local set = self.set or self
	return set[value]
end

function contains(self, value)
	return indexof(self) ~= nil
end

function add(self, value)
	local set = self.set or self
	if set[value] == nil then
		self[#self+1] = value
		set[value] = #self
		return value
	end
end

function remove(self, value)
	local set = self.set or self
	local index = set[value]
	if index ~= nil then
		local size = #self
		if index ~= size then
			local last = self[size]
			self[index] = last
			set[last]   = index
		end
		self[size] = nil
		set[value] = nil
		return value
	end
end

function removeat(self, index)
	return remove(self, self[index])
end

function __tostring(self, tostring, concat)
	tostring = tostring or global.tostring
	concat = concat or global.table.concat
	local result = { "{ " }
	for _, value in global.ipairs(self) do
		result[#result+1] = tostring(value)
		result[#result+1] = ", "
	end
	local last = #result
	result[last] = (last == 1) and "{}" or " }"
	return concat(result)
end
