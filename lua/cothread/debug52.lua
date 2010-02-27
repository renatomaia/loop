-- Project: CoThread
-- Release: 1.0 beta
-- Title  : Improvement of Debug Traceback for Coroutines
-- Author : Renato Maia <maia@inf.puc-rio.br>


local coroutine = require "coroutine"
local resume = coroutine.resume
local running = coroutine.running
local status = coroutine.status

local debug = require "debug"
local getinfo = debug.getinfo
local getlocal = debug.getlocal
local stacktrace = debug.traceback
local mainthread = debug.getregistry()[1]



function debug.getnextthread(thread)
	if thread == nil then return mainthread end
	if status(thread) == "normal" then
		return select(2, getlocal(thread, 0, 1))
	end
end

function debug.traceback(co, msg, level)
	if msg == nil then co, msg, level = running(), co, msg end
	if status(co) == "normal" or status(co) == "running" then
		local chain = {}
		local thread
		while thread ~= co do
			thread = debug.getnextthread(thread)
			chain[#chain+1] = thread
		end
		for i = #chain, 1, -1 do
			msg = stacktrace(chain[i], msg)
		end
	else
		msg = stacktrace(co, msg, level)
	end
	return msg
end
