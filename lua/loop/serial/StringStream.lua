-- Project: LOOP Class Library
-- Release: 3.0
-- Title  : Stream that Serializes and Restores Values from Strings
-- Author : Renato Maia <maia@inf.puc-rio.br>

local _G = require "_G"
local select = _G.select

local array = require "table"
local concat = array.concat

local oo = require "loop.simple"
local class = oo.class

local Stream = require "loop.serial.Stream"
local put = Stream.put



local StringStream = class({
	pos = 1,
	count = 0,
	__tostring = concat
}, Stream)

function StringStream:write(...)
	local count = self.count
	local size = select("#", ...)
	for i=1, size do
		self[count+i] = select(i, ...)
	end
	self.count = count+size
end

function StringStream:put(...)
	put(self, ...)
	self:write("\0")
end

function StringStream:read()
	local code = self.data or self:__tostring()
	local pos = self.pos
	local zero = code:find("%z", pos)
	if zero == nil then error("incomplete stream") end
	self.pos = zero+1
	return code:sub(pos, zero-1)
end

return StringStream
