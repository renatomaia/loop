local _G = require "_G"
local type = _G.type
local setmetatable = _G.setmetatable

local coroutine = require "coroutine"
local resume = coroutine.resume
local running = coroutine.running

local debug     = require "debug"
local stacktrace   = debug.traceback

--------------------------------------------------------------------------------
local Previous = setmetatable({},{__mode="kv"})

local function endresume(co, ...)
	Previous[co] = nil
	return ...
end

function coroutine.resume(co, ...)
	Previous[co] = running()
	return endresume(co, resume(co, ...))
end
--------------------------------------------------------------------------------
function coroutine.previous(co)
	return Previous[co]
end
--------------------------------------------------------------------------------
-- In Lua 5.1, it does not print the stack trace of the main thread,
-- unless you use the "fix" from:
-- http://lua-users.org/lists/lua-l/2006-09/msg00751.html
function debug.traceback(co, msg)
	if type(co) ~= "thread" then
		co, msg = running(), co
	end
	repeat
		msg = stacktrace(co, msg)
		co = coroutine.previous(co)
	until co == nil
	return msg
end
