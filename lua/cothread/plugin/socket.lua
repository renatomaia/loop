local _G = require "_G"
local ipairs = _G.ipairs
local next = _G.next
local pairs = _G.pairs
local require = _G.require

local coroutine = require "coroutine"
local newcoroutine = coroutine.create
local yield = coroutine.yield

local math = require "math"
local inf = math.huge
local max = math.max

local tabop = require "loop.table"
local copy = tabop.copy
local memoize = tabop.memoize

local ArrayedSet = require "loop.collection.ArrayedSet"

local socketcore = require "socket.core"
local suspendprocess = socketcore.sleep
local selectsockets = socketcore.select
local gettime = socketcore.gettime

--------------------------------------------------------------------------------
-- Begin of Instantiation Code -------------------------------------------------
--------------------------------------------------------------------------------

return function(_ENV, cothread)
	if _G._VERSION=="Lua 5.1" then _G.setfenv(1,_ENV) end -- Lua 5.1 compatibility
	plugin(require "cothread.plugin.sleep")

--------------------------------------------------------------------------------
-- Initialization Code ---------------------------------------------------------
--------------------------------------------------------------------------------

	local function defaultidle(timeout)                                           --[[VERBOSE]] verbose:scheduler("process sleeping for ",timeout-now()," seconds")
		suspendprocess(max(0, timeout-now()))                                       --[[VERBOSE]] verbose:scheduler("sleeping ended")
	end
	idle = defaultidle
	moduleop("now", gettime, "yieldable")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

	local function newtable() return {} end
	local reading = ArrayedSet()
	local writing = ArrayedSet()
	local event2opset = {
		r = reading,
		w = writing,
	}
	local threadof = {
		[reading] = memoize(newtable, "k"),
		[writing] = memoize(newtable, "k"),
	}
	local socketof = {
		[reading] = memoize(newtable, "k"),
		[writing] = memoize(newtable, "k"),
	}

	local function watchsockets(timeout)
		if #reading == 0 and #writing == 0 then return end
		if timeout == inf then timeout = nil end
		if timeout ~= nil then timeout = max(timeout-now(), 0) end                  --[[VERBOSE]] verbose:scheduler("processing network events")
		local recvok, sendok = selectsockets(reading, writing, timeout)
		local sock2thread = threadof[reading]
		for _, socket in ipairs(recvok) do
			for thread in pairs(copy(sock2thread[socket])) do
				yield("yield", thread, socket, "r")
			end
		end
		sock2thread = threadof[writing]
		for _, socket in ipairs(sendok) do
			for thread in pairs(copy(sock2thread[socket])) do
				yield("yield", thread, socket, "w")
			end
		end
	end
	
	watcher = {"fake thread"}                                                     -- [[VERBOSE]] verbose.viewer.labels[watcher] = "SocketWatcher"
	
	local function checkwatching()
		if #reading == 0 and #writing == 0 then
			unschedule(watcher)
			idle = defaultidle
		end
	end
	
	local function unscheduled(thread)
		for opset, socketsof in pairs(socketof) do
			local threadsof = threadof[opset]
			local sockets = socketsof[thread]
			socketsof[thread] = nil
			for socket in pairs(sockets) do
				threadsof[socket][thread] = nil
				opset:remove(socket)
			end
		end
		checkwatching()                                                             --[[VERBOSE]] verbose:threads(thread," unscheduled and it not waiting sockets anymore");verbose:state()
	end
	
	moduleop("addwait", function(socket, event, thread)
		local opset = event2opset[event]
		if opset ~= nil then
			threadof[opset][socket][thread] = true
			socketof[opset][thread][socket] = true
			opset:add(socket)
			onunschedule(thread, unscheduled)
			idle = watchsockets
			schedule(watcher, "defer", inf)                                           --[[VERBOSE]] verbose:threads(thread," waiting for socket ",socket);verbose:state()
			return true
		end
	end, "yieldable")
	
	moduleop("removewait", function(socket, event, thread)
		local opset = event2opset[event]
		if opset ~= nil then
			local threads = threadof[opset][socket]
			threads[thread] = nil
			if next(threads) == nil then
				opset:remove(socket)
			end
			local sockets = socketof[opset][thread]
			sockets[socket] = nil
			if next(sockets) == nil then
				onunschedule(thread, nil)
			end
			checkwatching()                                                           --[[VERBOSE]] verbose:threads(thread," not waiting for socket ",socket," anymore");verbose:state()
		end
	end, "yieldable")
	
	moduleop("iswaiting", function(thread)
		for event, opset in pairs(event2opset) do
			if next(socketof[opset][thread]) ~= nil then
				return true
			end
		end
		return false
	end, "yieldable")

	moduleop("getwaitof", function(thread)
		local result = {}
		for event, opset in pairs(event2opset) do
			result[event] = socketof[opset][thread]
		end
		return result
	end, "yieldable")

	--[[VERBOSE]] begin = now()
	--[[VERBOSE]] verbose:setlevel(1, {"threads","socket"})
	--[[VERBOSE]] local old = verbose.custom.state
	--[[VERBOSE]] statelogger("Reading", function(self, missing, newline)
	--[[VERBOSE]] 	local output = self.viewer.output
	--[[VERBOSE]] 	local labels = self.viewer.labels
	--[[VERBOSE]] 	for _, socket in ipairs(reading) do
	--[[VERBOSE]] 		output:write(newline,"  [",labels[socket],"] =")
	--[[VERBOSE]] 		for thread in pairs(threadof[reading][socket]) do
	--[[VERBOSE]] 			output:write(" ",labels[thread])
	--[[VERBOSE]] 		end
	--[[VERBOSE]] 	end
	--[[VERBOSE]] 	output:write(newline,"Writing:")
	--[[VERBOSE]] 	for _, socket in ipairs(writing) do
	--[[VERBOSE]] 		output:write(newline,"  [",labels[socket],"]=")
	--[[VERBOSE]] 		for thread in pairs(threadof[writing][socket]) do
	--[[VERBOSE]] 			output:write(" ",labels[thread])
	--[[VERBOSE]] 		end
	--[[VERBOSE]] 	end
	--[[VERBOSE]] end)
	
end
