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
-- Title  : Array Optimized for Insertion/Removal that Doesn't Garantee Order --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------

local global = _G -- only if available
local oo     = require "loop.base"

module(..., oo.class)

function add(self, value)
	self[#self + 1] = value
end

function remove(self, index)
	local size = #self
	if index == size then
		self[size] = nil
	elseif (index > 0) and (index < size) then
		self[index], self[size] = self[size], nil
	end
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
