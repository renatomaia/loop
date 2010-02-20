local _G = require "_G"
local stdpcall = _G.pcall

local coroutine = require "coroutine"
local stdcoro = coroutine.create
local resume = coroutine.resume
local yield = coroutine.yield
local status = coroutine.status

module(...)
--------------------------------------------------------------------------------
function create(func)
	local success, result = stdpcall(stdcoro, func)
	if not success then
		result = stdcoro(function(...) return func(...) end)
	end
	return result
end
--------------------------------------------------------------------------------
local function results(call, ...)
	if status(call) == "suspended" then
		return results(call, resume(call, yield(...)))
	end
	return ...
end

function pcall(func, ...)
	local call = create(func)
	return results(call, resume(call, ...))
end
--------------------------------------------------------------------------------
local function catch(handler, call, success, ...)
	if not success then
		return false, handler(call, ...)
	end
	return true, ...
end

function xpcall(func, handler, ...)
	local call = create(func)
	return catch(handler, call, results(call, resume(call, ...)))
end
