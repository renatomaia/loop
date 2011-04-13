local _G = require "_G"
local ipairs = _G.ipairs
local next = _G.next
local pairs = _G.pairs

local coroutine = require "coroutine"
local newcoroutine = coroutine.create
local yield = coroutine.yield

local math = require "math"
local max = math.max

local tabop = require "loop.table"
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
	_G.pcall(_G.setfenv, 2, _ENV) -- compatibility with Lua 5.1
	

--------------------------------------------------------------------------------
-- Initialization Code ---------------------------------------------------------
--------------------------------------------------------------------------------

	local function defaultidle(timeout)                                           -- [[VERBOSE]] verbose:scheduler("process sleeping for ",timeout-now()," seconds")
		suspendprocess(max(0, timeout-now()))                                               -- [[VERBOSE]] verbose:scheduler("sleeping ended")
	end
	idle = defaultidle
	now = gettime
	moduleop("now", now, "yieldable")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

	local reading = ArrayedSet()
	local writing = ArrayedSet()
	local threadof = {
		[reading] = {},
		[writing] = {},
	}
	local socketof = {
		[reading] = memoize(function() return {} end, "k"),
		[writing] = memoize(function() return {} end, "k"),
	}

	local function watchsockets(timeout)
		if timeout ~= nil then timeout = max(timeout-now(), 0) end                  -- [[VERBOSE]] verbose:socket(true, "processing network events")
		local recvok, sendok = selectsockets(reading, writing, timeout)
		local sock2thread = threadof[reading]
		local threads = {}
		for _, socket in ipairs(recvok) do
			threads[ sock2thread[socket] ] = socket
		end
		sock2thread = threadof[writing]
		for _, socket in ipairs(sendok) do
			threads[ sock2thread[socket] ] = socket
		end
		for thread, socket in pairs(threads) do
			yield("next", thread, socket)
		end                                                                         -- [[VERBOSE]] verbose:socket(false, "done processing network events")
	end


	local function resumewatcher()
		if #reading > 0 or #writing > 0 then
			schedule(watcher)
		end
	end
	watcher = newcoroutine(function()
		while true do
			if scheduled[watcher] == watcher then
				watchsockets()
			else
				watchsockets(0)
			end
			if #reading == 0 and #writing == 0 then
				yield("suspend")
			elseif scheduled[waker] ~= nil then
				onreschedule(waker, resumewatcher)
				yield("suspend", waker)
			else
				yield("yield")
			end
		end
	end)                                                                            -- [[VERBOSE]] verbose.viewer.labels[watcher] = "SocketWatcher"

	local function unscheduled(thread)
		for opset, socketof in pairs(socketof) do
			local threads = threadof[opset]
			local sockets = socketof[thread]
			for socket in pairs(sockets) do
				opset:remove(socket)
				threads[socket] = nil
				sockets[socket] = nil
			end
		end
	end
	
	local function watchsocket(thread, opset, socket)
		if opset:add(socket) == socket then
			threadof[opset][socket] = thread
			socketof[opset][thread][socket] = true                                    -- [[VERBOSE]] verbose:threads(thread," waiting for socket ",socket);verbose:state()
			onunschedule(thread, unscheduled)
			idle = watchsockets
			if scheduled[waker] == nil then
				schedule(watcher)
			else
				onreschedule(waker, resumewatcher)
			end
			return true
		end
	end
	
	local function forgetsocket(opset, socket)
		if opset:remove(socket) == socket then
			local threads = threadof[opset]
			local thread = threads[socket]
			threads[socket] = nil
			local sockets = socketof[opset][thread]
			sockets[socket] = nil
			if next(sockets) == nil then
				socketof[opset][thread] = nil
				onunschedule(thread, nil)
			end
			if #reading == 0 and #writing == 0 then
				unschedule(watcher)
				idle = defaultidle
			end
			return true
		end
	end
	
	yieldop("waitwrite", function(current, socket, timeout, timeoutkind)
		if timeout == nil then
			unschedule(current)
		else
			schedule(current, timeoutkind, timeout)
		end
		watchsocket(current, writing, socket)
	end)
	yieldop("forgetwrite", function(current, socket)
		unschedule(current)
		forgetsocket(writing, socket)
		return current
	end)
	yieldop("waitread", function(current, socket, timeout, timeoutkind)
		if timeout == nil then
			unschedule(current)
		else
			schedule(current, timeoutkind, timeout)
		end
		watchsocket(current, reading, socket)
	end)
	yieldop("forgetread", function(current, socket)
		unschedule(current)
		forgetsocket(reading, socket)
		return current
	end)
	yieldop("waitsockets", function(current, toread, towrite, timeout, timeoutkind)
		if timeout == nil then
			unschedule(current)
		else
			schedule(current, timeoutkind, timeout)
		end
		for socket in pairs(toread) do
			watchsocket(current, reading, socket)
		end
		for socket in pairs(towrite) do
			watchsocket(current, writing, socket)
		end
	end)
	yieldop("forgetsockets", function(current, toread, towrite)
		unschedule(current)
		for socket in pairs(toread) do
			forgetsocket(reading, socket)
		end
		for socket in pairs(towrite) do
			forgetsocket(writing, socket)
		end
		return current
	end)

	-- [[VERBOSE]] begin = now()
	-- [[VERBOSE]] verbose:setlevel(1, {"threads","socket"})
	-- [[VERBOSE]] local old = verbose.custom.state
	-- [[VERBOSE]] statelogger("Reading", function(self, missing, newline)
	-- [[VERBOSE]] 	local output = self.viewer.output
	-- [[VERBOSE]] 	local labels = self.viewer.labels
	-- [[VERBOSE]] 	for _, socket in ipairs(reading) do
	-- [[VERBOSE]] 		output:write(" ",labels[threadof[reading][socket]])
	-- [[VERBOSE]] 	end
	-- [[VERBOSE]] 	output:write(newline,"Writing:")
	-- [[VERBOSE]] 	for _, socket in ipairs(writing) do
	-- [[VERBOSE]] 		output:write(" ",labels[threadof[writing][socket]])
	-- [[VERBOSE]] 	end
	-- [[VERBOSE]] end)
	
end
