-- Project: CoThread
-- Release: 1.0 beta
-- Title  : Improvement of Debug Traceback for Coroutines
-- Author : Renato Maia <maia@inf.puc-rio.br>


local _G = require "_G"
local select = _G.select
local setmetatable = _G.setmetatable

local coroutine = require "coroutine"
local resume = coroutine.resume
local running = coroutine.running

local debug = require "debug"
local stacktrace = debug.traceback



local previous = setmetatable({},{__mode="kv"})

local function endresume(co, ...)
	previous[co] = nil
	return ...
end

function coroutine.resume(co, ...)
	previous[co] = running()
	return endresume(co, resume(co, ...))
end



function coroutine.previous(co)
	return previous[co]
end



-- get original 'coroutine.running' in case 'coroutine.pcall' was loaded
-- this will prevent 'running' to return original thread that invoked a 'pcall'
-- instead of the actual running coroutine.
for i = 1, 1/0 do
	local name, value = debug.getupvalue(running, i)
	if name == "stdrunning" then
		running = value
		break
	elseif name == nil then
		break
	end
end
-- In Lua 5.1, it does not print the stack trace of the main thread, unless you
-- use the "fix" from: http://lua-users.org/lists/lua-l/2006-09/msg00751.html
function debug.traceback(...)
	local co, msg
	if select("#", ...) > 1 then
		co, msg = ...
	else
		co = running()
		if co == nil then return stacktrace(...) end
		msg = stacktrace(co, ...)
		co = previous[co]
	end
	while co ~= nil do
		msg = stacktrace(co, msg)
		co = previous[co]
	end
	return msg
end
