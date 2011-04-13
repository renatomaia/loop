-- Project: CoThread
-- Release: 1.0 beta
-- Title  : Cooperative Threads Scheduler based on Coroutines
-- Author : Renato Maia <maia@inf.puc-rio.br>

local _G = require "_G"
local error = _G.error
local traceback = _G.debug
              and _G.debug.traceback -- only if available
               or function(thread, err) return err end

local coroutine = require "coroutine.replace"
local resume = coroutine.resume
local replace = coroutine.replace
local running = coroutine.running
local status = coroutine.status

local main

local function resumed(thread, success, ...)
	main = nil
	if not success then error(traceback(thread, ...), 3) end
	return ...
end

return {
	create = coroutine.create,
	running = running,
	status = function(thread)
		local status = status(thread)
		if thread == main and status == "normal" then
			return "suspended"
		end
		return status
	end,
	resume = function(thread, ...)
		if main == nil then
			main = running()
			return resumed(thread, resume(thread, ...))
		end
		if main == thread then
			thread = nil
		elseif thread == nil then
			error("bad argument #1 (coroutine expected)", 2)
		end
		return replace(thread, ...)
	end,
}
