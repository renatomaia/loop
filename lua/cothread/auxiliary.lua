-- Project: CoThread
-- Release: 1.0 beta
-- Title  : Workarounds for Limitations of Coroutines in Lua 5.1
-- Author : Renato Maia <maia@inf.puc-rio.br>


local _G = require "_G"
local stdpcall = _G.pcall

local coroutine = require "coroutine"
local newcoroutine = coroutine.create
local resume = coroutine.resume
local stdrunning = coroutine.running
local yield = coroutine.yield
local status = coroutine.status

local CyclicSets = require "loop.collection.CyclicSets"



function coroutine.create(func)
	local success, result = stdpcall(newcoroutine, func)
	if not success then
		result = newcoroutine(function(...) return func(...) end)
	end
	return result
end



-- 'pcallthreads' contains all chains of nested pcall threads as disjoint cyclic
-- sets. The ordering is from the outter call to the inner call. Since the
-- ordering is cyclic, the current thread (inner call) is succeeded by the
-- original thread that called the first pcall in the chain (outter call), thus
-- it is fast to find which thread an yield in the running coroutine will be
-- propagated to due to a nested pcall chain.
local pcallthreads = CyclicSets()

function coroutine.running()
	local current = stdrunning()
	return pcallthreads[current] -- current is a pcall thread
	    or current               -- current is not a pcall thread
end



local function results(call, success, ...)
	if status(call) == "suspended" then
		return results(call, resume(call, yield(...)))
	end
	local current = stdrunning()
	if current then
		pcallthreads:removefrom(current)
		if pcallthreads[current] == current then
			pcallthreads[current] = nil
		end
	end
	return success, ...
end

local create = coroutine.create
function _G.pcall(func, ...)
	local current = stdrunning()
	if not current then return stdpcall(func, ...) end
	local call = create(func)
	pcallthreads:add(call, current)
	return results(call, resume(call, ...))
end



local function catch(handler, call, success, ...)
	if not success then
		return false, handler(call, ...)
	end
	return true, ...
end

function _G.xpcall(func, handler, ...)
	local call = create(func)
	local current = stdrunning()
	if current then pcallthreads:add(call, current) end
	return catch(handler, call, results(call, resume(call, ...)))
end
