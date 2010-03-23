-- Project: LOOP Class Library
-- Title  : Data Structure for Exception/Error Information
-- Author : Renato Maia <maia@inf.puc-rio.br>

local _G = require "_G"
local error = _G.error
local type = _G.type
local traceback = _G.debug and _G.debug.traceback

local table = require "table"
local concat = table.concat

local oo = require "loop.base"
local class = oo.class

module(..., class)

function __new(class, object)
	if traceback then
		if not object then
			object = { traceback = traceback() }
		elseif object.traceback == nil then
			object.traceback = traceback()
		end
	end
	return oo.rawnew(class, object)
end

function __concat(op1, op2)
	if type(op1) == "table" and type(op1.__tostring) == "function" then
		op1 = op1:__tostring()
	end
	if type(op2) == "table" and type(op2.__tostring) == "function" then
		op2 = op2:__tostring()
	end
	return op1..op2
end

function __tostring(self)
	local message = { self[1] or self._NAME or "Exception"," raised" }
	if self.message then
		message[#message + 1] = ": "
		message[#message + 1] = self.message
	end
	if self.traceback then
		message[#message + 1] = "\n"
		message[#message + 1] = self.traceback
	end
	return concat(message)
end
