--------------------------------------------------------------------------------
-- Project: LOOP - Lua Object-Oriented Programming                            --
-- Title  : Scoped Class Model Debugging Utilities                            --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------

local debug = require "debug"
local getupvalue = debug.getupvalue

function methodfunction(method)
	local name, value = getupvalue(method, 5)
	assert(name == "method", "Oops! Got the wrong upvalue in 'methodfunction'")
	return value
end

function methodclass(method)
	local name, value = getupvalue(method, 3)
	assert(name == "class", "Oops! Got the wrong upvalue in 'methodclass'")
	return value.proxy
end

