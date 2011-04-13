-- Project: CoThread
-- Release: 1.0 beta
-- Title  : Cooperative Threads Scheduler based on Coroutines
-- Author : Renato Maia <maia@inf.puc-rio.br>

local coroutine = require "coroutine"
local resume = coroutine.resume
local yield = coroutine.yield
local status = coroutine.status

local function resumed(thread, success, result, ...)
	if not success or status(thread) == "dead" then
		return success, result, ... --> 'thread' terminated
	elseif result == nil then
		return success, ... --> 'thread' yielded
	end
	return resumed(result, resume(result, ...)) --> 'thread' replaced by 'result'
end

return {
	create = coroutine.create,
	running = coroutine.running,
	status = status,
	replace = yield,
	resume = function(thread, ...)
		return resumed(thread, resume(thread, ...)) --> 'thread' resumed
	end,
	yield = function(...)
		return yield(nil, ...)
	end,
}
