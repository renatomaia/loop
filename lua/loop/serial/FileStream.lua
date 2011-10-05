-- Project: LOOP Class Library
-- Release: 3.0
-- Title  : Stream that Serializes and Restores Values from Files
-- Author : Renato Maia <maia@inf.puc-rio.br>

local _G = require "_G"
local assert = _G.assert

local array = require "table"
local concat = array.concat

local oo = require "loop.simple"
local class = oo.class

local Stream = require "loop.serial.Stream"
local put = Stream.put



local FileStream = class({}, Stream)

function FileStream:write(...)
	assert(self.file:write(...))
end

function FileStream:put(...)
	put(self, ...)
	self:write("\0\n")
end

function FileStream:read()
	local lines = {}
	for line in self.file:lines() do
		lines[#lines+1] = line
		if line:find("return") == 1 then return concat(lines) end
	end
	error("incomplete stream")
end

return FileStream
