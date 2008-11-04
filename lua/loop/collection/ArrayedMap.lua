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
-- Title  : Map of Objects that Keeps an Array of Key Values                  --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------

local global = require "_G"
local table  = require "table"
local oo     = require "loop.base"

local ipairs = global.ipairs
local rawget = global.rawget
local insert = table.insert

module(..., oo.class)

keys = ipairs
keyat = rawget

function value(self, key, value)
	local map = self.map or self
	if value == nil
		then return map[key]
		else map[key] = value
	end
end

function add(self, key, value)
	local map = self.map or self
	self[#self + 1] = key
	map[key] = value
end

function addat(self, index, key, value)
	local map = self.map or self
	insert(self, index, key)
	map[key] = value
end

function removeat(self, index)
	local map = self.map or self
	local key = self[index]
	if key ~= nil then
		local size = #self
		if index ~= size then
			self[index] = self[size]
		end
		self[size] = nil
		map[key] = nil
		return key
	end
end

function valueat(self, index, value)
	local map = self.map or self
	if value == nil
		then return map[ self[index] ]
		else map[ self[index] ] = value
	end
end

function __tostring(self, tostring, concat)
	local map = self.map or self
	tostring = tostring or global.tostring
	concat = concat or global.table.concat
	local result = { "{ " }
	for _, key in global.ipairs(self) do
		result[#result+1] = "["
		result[#result+1] = tostring(key)
		result[#result+1] = "]="
		result[#result+1] = tostring(map[key])
		result[#result+1] = ", "
	end
	local last = #result
	result[last] = (last == 1) and "{}" or " }"
	return concat(result)
end
