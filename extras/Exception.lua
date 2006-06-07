--------------------------------------------------------------------------------
-- Project: LOOP Extra Utilities for Lua                                      --
-- Release: 1.0 alpha                                                         --
-- Title  : Data structure to hold information about exceptions in Lua        --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
-- Date   : 03/08/2005 16:35                                                  --
--------------------------------------------------------------------------------

local error = error
local type  = type

local table = require "table"
local debug = require "debug"
local oo    = require "loop.base"

module("loop.extras.Exception", oo.class)

function __init(class, object)
	if not object then
		object = { traceback = debug.traceback() }
	elseif object.traceback == nil then
		object.traceback = debug.traceback()
	end
	return oo.rawnew(class, object)
end

function __concat(op1, op2)
	if oo.instanceof(op1, _M) then
		op1 = op1:__tostring()
	elseif type(op1) ~= "string" then
		error("attempt to concatenate a "..type(op1).." value")
	end
	if oo.instanceof(op2, _M) then
		op2 = op2:__tostring()
	elseif type(op2) ~= "string" then
		error("attempt to concatenate a "..type(op2).." value")
	end
	return op1 .. op2
end

function __tostring(self)
	local message = { self[1] or _NAME," raised" }
	if self.message then
		message[#message + 1] = ": "
		message[#message + 1] = self.message
	end
	if self.traceback then
		message[#message + 1] = "\n"
		message[#message + 1] = self.traceback
	end
	return table.concat(message)
end