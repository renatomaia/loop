-- Project: LOOP Class Library
-- Release: 2.3 beta
-- Title  : Sorted Map Implemented with Skip Lists
-- Author : Renato Maia <maia@inf.puc-rio.br>
-- Notes  :
--   Can be used as a module that provides functions instead of methods.


local global = _G -- only if available
local math = require "math"
local random = math.random

local oo = require "loop.base"
local class = oo.class

module(..., class)

-- default definitions ---------------------------------------------------------

levelprob = .5
before = function(key, other) return key < other end

-- internal operations ---------------------------------------------------------

function newlevel(self)
	local level = 1
	local prob = self.levelprob
	local max  = self.levelmax or (#self + 1)
	while level < max and random() < prob do
		level = level + 1
	end
	return level
end

function getnode(self)
	local pool = self.nodepool
	if pool then
		local node = pool.freenodes
		if node then
			pool.freenodes = node[1]
			return node
		end
	end
	return {}
end

function freenode(self, node, last)
	local pool = self.nodepool
	if pool then
		if last == nil then last = node end
		last[1] = pool.freenodes
		pool.freenodes = node
	end
end

-- operations on list nodes ----------------------------------------------------

function nextnode(self, node)
	if node == nil then node = self end
	return node[1]
end

function popnode(self)
	local node = self[1]
	for level = 1, #self do
		if self[level] ~= node then break end
		self[level] = node[level]
	end
	return node
end

function findnode(self, key, path)
	local before = self.before or before
	local prev, node = self
	for level = #self, 1, -1 do
		node = prev
		repeat
			prev, node = node, node[level]
		until not node or not before(node.key, key)
		if path then path[level] = prev end
	end
	return node, prev
end

-- operations on paths to node -------------------------------------------------

function addto(self, path, node)
	local newlevel = self:newlevel()
	if newlevel > #self then
		for level = #self+1, newlevel do
			path[level] = self
		end
	end
	for level = newlevel+1, #path do path[level] = nil end
	for level = newlevel, 1, -1 do
		prev = path[level]
		node[level] = prev[level]
		prev[level] = node
	end
end

function removefrom(self, path, node)
	for level = 1, #self do
		local prev = path[level]
		if prev[level] ~= node then break end
		prev[level] = node[level]
	end
end

function cropto(self, path)
	if path[1] ~= self then
		for level = 1, #self do
			self[level] = path[level][level]
		end
		return true
	end
end

-- sorted map operations -------------------------------------------------------

function empty(self)
	return (self[1] ~= nil)
end

function head(self)
	local node = self[1]
	if node then return node.value, node.key end
end

function next(self, key, orGreater)
	local node = self:findnode(key)
	if node and (orGreater or node.key == key) then
		node = self:nextnode(node)
		if node then
			return node.value, node.key
		end
	end
end

local function iterator(holder)
	node = holder[1][1]
	if node then
		holder[1] = node
		return node.key, node.value
	end
end
function pairs(self)
	return iterator, {self}
end

function get(self, key, orGreater)
	local node = self:findnode(key)
	if node and (orGreater or node.key == key) then
		return node.value, node.key
	end
end

function put(self, key, value, orGreater, onlyAdd)
	local new = self:getnode()
	local found = self:findnode(key, new)
	if found and (orGreater or found.key == key) then
		self:freenode(new)
		if not onlyAdd then
			found.value = value
			return value, found.key
		end
	else
		new.key = key
		new.value = value
		self:addto(new, new)
		return value, key
	end
end

function remove(self, key, orGreater)
	local path = {}
	local node = self:findnode(key, path)
	if node and (orGreater or node.key == key) then
		self:removefrom(node, path)
		self:freenode(node)
		return node.value, node.key
	end
end

function pop(self)
	local node = self:popnode()
	if node then
		self:freenode(node)
		return node.value, node.key
	end
end

function cropuntil(self, key, orGreater)
	local path = {}
	local node = self:findnode(key, path)
	if orGreater or (node and node.key == key) then
		local first = self[1]
		if self:cropto(path) then
			self:freenode(first, path[1])
		end
		if node then
			return node.value, node.key
		end
	end
end

-- meta operations -------------------------------------------------------------

function __tostring(self, tostring, concat)
	tostring = tostring or global.tostring
	concat = concat or global.table.concat
	local result = { "{ " }
	local node = self[1]
	while node ~= nil do
		result[#result+1] = "["
		result[#result+1] = tostring(node.key)
		result[#result+1] = "]="
		result[#result+1] = tostring(node.value)
		result[#result+1] = ", "
		node = node[1]
	end
	local last = #result
	result[last] = (last == 1) and "{}" or " }"
	return concat(result)
end

-- prints debugging information about the structure
-- of the skip list, in the following form:
-- | | | [3] = <value>
-- +-+-+-[6] = <value>
--   | | [7] = <value>
--   | +-[9] = <value>
--   | | [12] = <value>
--   | | [19] = <value>
--   | | [21] = <value>
--   +-+-[25] = <value>
--       [26] = <value>
function debug(self, tostring, output)
	tostring = tostring or global.tostring
	output = output or global.io.stderr
	local current = {global.unpack(self)}
	while #current > 0 do
		local node = current[1]
		for level = #self, 2, -1 do
			if level > #current then
				output:write "  "
			elseif node == current[level] then
				output:write "+-"
				current[level] = node[level]
			else
				output:write "| "
			end
		end
		current[1] = node[1]
		output:write "["
		output:write(tostring(node.key))
		output:write "] = "
		output:write(tostring(node.value))
		output:write ",\n"
	end
end
