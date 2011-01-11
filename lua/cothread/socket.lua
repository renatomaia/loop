-- Project: CoThread
-- Release: 1.0 beta
-- Title  : Lua Socket Wrapper for Cooperative Scheduling
-- Author : Renato Maia <maia@inf.puc-rio.br>


local _G = require "_G"
local assert = _G.assert
local ipairs = _G.ipairs
local getmetatable = _G.getmetatable
local next = _G.next
local require = _G.require
local setmetatable = _G.setmetatable
local type = _G.type

local coroutine = require "coroutine"
local newthread = coroutine.create
local running = coroutine.running
local yield = coroutine.yield

local math = require "math"
local max = math.max
local huge = math.huge

local table = require "table"
local concat = table.concat

local tabop = require "loop.table"
local copy = tabop.copy
local memoize = tabop.memoize

local ArrayedSet = require "loop.collection.ArrayedSet"
local Wrapper = require "loop.object.Wrapper"
local EventGroup = require "cothread.EventGroup"

local TimeOutToken = {}

--------------------------------------------------------------------------------
-- Begin of Instantiation Code -------------------------------------------------
--------------------------------------------------------------------------------

local default = {}

local function new(sockets)
	if sockets == nil then sockets = {} end
	local socketcore = sockets.socketcore or require("socket.core")
	local cothread = sockets.cothread or require("cothread")
	cothread.now = socketcore.gettime
	copy(socketcore, sockets)

--------------------------------------------------------------------------------
-- Initialization Code ---------------------------------------------------------
--------------------------------------------------------------------------------

local now = cothread.now
local round = cothread.round
local schedule = cothread.schedule
local unschedule = cothread.unschedule
local wakeall = cothread.wakeall                                                --[[VERBOSE]] local verbose = cothread.verbose

local suspendprocess = socketcore.sleep
local selectsockets = socketcore.select
local createtcp = socketcore.tcp
local createudp = socketcore.udp

local function idle(timeout)                                                    --[[VERBOSE]] verbose:scheduler("process sleeping for ",timeout-now()," seconds")
	suspendprocess(timeout-now())                                                 --[[VERBOSE]] verbose:scheduler("sleeping ended")
end
cothread.idle = idle



local reading = ArrayedSet()
local writing = ArrayedSet()

local CoSocket = {}

local WrapperOf = memoize(function(socket)
	if socket then
		socket:settimeout(0)
		socket = copy(CoSocket, Wrapper{
			__object = socket,
			readevent = socket,
			writeevent = nil,
		})
		socket.writeevent = socket
	end
	return socket
end, "k")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local wasidle

local function watchsockets(timeout)
	if timeout == huge then
		timeout = nil
	elseif timeout then
		timeout = max(timeout - now(), 0)
	end                                                                           --[[VERBOSE]] verbose:socket(true, "waiting for network events for ",timeout," seconds")
	local recvok, sendok, errmsg = selectsockets(reading, writing, timeout)
	for _, socket in ipairs(recvok) do
		wakeall(socket)
	end
	for _, socket in ipairs(sendok) do
		wakeall(WrapperOf[socket])
	end                                                                           --[[VERBOSE]] verbose:socket(false, "done processing network events")
	wasidle = true
end

local watching
local function watchsocket(socket, opset)
	local result = opset:add(socket)
	if not watching then
		watching = true
		cothread.idle = watchsockets
	end
	return result == socket
end
local function forgetsocket(socket, opset)
	local result = opset:remove(socket)
	if watching and #reading == 0 and #writing == 0 then
		watching = nil
		cothread.idle = idle
	end
	return result == socket
end

local function roundcont(result, ...)
	if result == false and #reading > 0 or #writing > 0 then
		result = huge
	end
	return result, ...
end
function cothread.round(...)
	if not wasidle then watchsockets(0) end
	wasidle = nil
	return roundcont(round(...))
end


function cothread.signalcanceled(signal)
	if reading[signal] then -- receive and accept
		forgetsocket(signal, reading)
	elseif writing[signal] then -- send and connect
		forgetsocket(signal, writing)
	elseif getmetatable(signal) == EventGroup then -- select
		for sig in signal:iterate() do
			signal:remove(sig)
		end
		signal:settimeout(nil)
	end
end

--------------------------------------------------------------------------------
-- Wrapped Socket Methods ------------------------------------------------------
--------------------------------------------------------------------------------

local Timer2Operation = {
	readtimer = "reading",
	writetimer = "writing",
}

function CoSocket:settimeout(timeout, timestamp)                                --[[VERBOSE]] verbose:socket("setting timeout of ",self,timestamp and " to moment " or " to ",timeout)
	self.timeoutkind = timestamp and "defer" or "delay"
	if not timeout or timeout < 0 then
		self.timeout = nil
	else
		self.timeout = timeout
		if timeout > 0 and self.readtimer == nil then
			for timer, op in pairs(Timer2Operation) do
				self[timer] = newthread(function()
					while true do
						local thread = self[op]
						unschedule(thread)
						yield("yield", thread, TimeOutToken)
					end
				end)
			end
		end
	end
end

function CoSocket:connect(...)                                                  --[[VERBOSE]] verbose:socket(true, "connecting to ",...)
	-- connect the socket if possible
	local socket = self.__object
	local result, errmsg = socket:connect(...)
	
	-- check if the job has not yet been completed
	local timeout = self.timeout
	if not result and errmsg == "timeout" and timeout ~= 0 then                   --[[VERBOSE]] verbose:socket(true, "waiting for connection establishment")
		watchsocket(socket, writing) -- register socket for network event watch
		
		-- start timer for counting the timeout
		local timer = timeout and self.writetimer
		if timer then schedule(timer, self.timeoutkind, timeout) end
		
		-- wait for a connection completion and finish establishment
		local _, token = yield("wait", self.writeevent)
		
		-- cancel timer if it was not triggered
		if token == TimeOutToken then unschedule(timer) end
		
		-- try to connect again one last time before giving up
		result, errmsg = socket:connect(...)
		if not result and errmsg == "already connected" then
			result, errmsg = 1, nil -- connection was already established
		end
		
		forgetsocket(socket, writing)                                               --[[VERBOSE]] verbose:socket(false, "waiting completed")
	end                                                                           --[[VERBOSE]] verbose:socket(false, "connection ",result and "established" or "failed")
	return result, errmsg
end

function CoSocket:accept(...)                                                   --[[VERBOSE]] verbose:socket(true, "accepting connection from ",...)
	-- accept any connection request pending in the socket
	local socket = self.__object
	local result, errmsg = socket:accept(...)
	
	-- check if the job has not yet been completed
	local timeout = self.timeout
	if result then
		result = WrapperOf[result]
	elseif errmsg == "timeout" and timeout ~= 0 then                              --[[VERBOSE]] verbose:socket(true, "waiting for new connection request")
		watchsocket(socket, reading) -- register socket for network event watch
		
		-- start timer for counting the timeout
		local timer = timeout and self.readtimer
		if timer then schedule(timer, self.timeoutkind, timeout) end
		
		-- wait for a connection request signal
		local _, token = yield("wait", self.readevent)
		
		-- cancel timer if it was not triggered
		if token == TimeOutToken then unschedule(timer) end
	
		-- accept any connection request pending in the socket
		result, errmsg = socket:accept(...)
		if result then result = WrapperOf[result] end
		
		forgetsocket(socket, reading)                                               --[[VERBOSE]] verbose:socket(false, "waiting completed")
	end                                                                           --[[VERBOSE]] verbose:socket(false, "new connection ",result and "accepted" or "failed")
	return result, errmsg
end

function CoSocket:send(data, i, j)                                              --[[VERBOSE]] verbose:socket(true, "sending byte stream")
	-- fill space already avaliable in the socket
	local socket = self.__object
	local result, errmsg, lastbyte = socket:send(data, i, j)

	-- check if the job has not yet been completed
	local timeout = self.timeout
	if not result and errmsg == "timeout" and timeout ~= 0 then                   --[[VERBOSE]] verbose:socket(true, "waiting for more space to write stream to be sent")
		watchsocket(socket, writing) -- register socket for network event watch
		
		-- start timer for counting the timeout
		local timer = timeout and self.writetimer
		if timer then schedule(timer, self.timeoutkind, timeout) end
		
		repeat
			local done
			-- wait for more space on the socket
			local _, token = yield("wait", self.writeevent)
			-- cancel timer if it was not triggered
			if token == TimeOutToken then
				unschedule(timer)
				done = true
			end
			-- fill any space free on the socket one last time
			result, errmsg, lastbyte = socket:send(data, lastbyte+1, j)
			if result then
				done = true
			elseif errmsg ~= "timeout" then
				done = true                                                             --[[VERBOSE]] else verbose:socket("stream was sent until byte ",lastbyte)
			end
		until done
		
		forgetsocket(socket, writing)                                               --[[VERBOSE]] verbose:socket(false)
	end                                                                           --[[VERBOSE]] verbose:socket(false, "stream sending ",result and "completed" or "failed")
	
	return result, errmsg, lastbyte
end

function CoSocket:receive(pattern)                                              --[[VERBOSE]] verbose:socket(true, "receiving byte stream")
	-- get data already avaliable in the socket
	local socket = self.__object
	local result, errmsg, partial = socket:receive(pattern)
	
	-- check if the job has not yet been completed
	local timeout = self.timeout
	if not result and errmsg == "timeout" and timeout ~= 0 then                   --[[VERBOSE]] verbose:socket(true, "waiting for new data to be read")
		watchsocket(socket, reading) -- register socket for network event watch
		
		-- start timer for counting the timeout
		local timer = timeout and self.readtimer
		if timer then schedule(timer, self.timeoutkind, timeout) end
		
		-- initialize data read buffer with data already read
		local buffer = { partial }
		
		repeat
			local done
			-- reduce the number of required bytes
			if type(pattern) == "number" then
				pattern = pattern - #partial                                            --[[VERBOSE]] verbose:socket("got more ",#partial," bytes, waiting for more ",pattern)
			end
			-- wait for more data on the socket
			local _, token = yield("wait", self.readevent)
			-- cancel timer if it was not triggered
			if token == TimeOutToken then
				unschedule(timer)
				done = true
			end
 			-- read any data left on the socket one last time
			result, errmsg, partial = socket:receive(pattern)
			if result then
				buffer[#buffer+1] = result
				done = true
			else
				buffer[#buffer+1] = partial
				if errmsg ~= "timeout" then done = true end
			end
		until done
		
		-- concat buffered data
		if result then
			result = concat(buffer)
		else
			partial = concat(buffer)
		end
		
		forgetsocket(socket, reading)                                               --[[VERBOSE]] verbose:socket(false, "waiting completed")
	end                                                                           --[[VERBOSE]] verbose:socket(false, "data reading ",result and "completed" or "failed")
	
	return result, errmsg, partial
end

--------------------------------------------------------------------------------
-- Wrapped Lua Socket API ------------------------------------------------------
--------------------------------------------------------------------------------

function sockets.select(recvt, sendt, timeout, timestamp)                               --[[VERBOSE]] verbose:socket(true, "selecting sockets ready")
	-- collect sockets and check for concurrent use
	local recv, send
	if recvt and #recvt > 0 then
		recv = {}
		for index, wrapper in ipairs(recvt) do
			recv[index] = wrapper.__object
		end
	end
	if sendt and #sendt > 0 then
		send = {}
		for index, wrapper in ipairs(sendt) do
			send[index] = wrapper.__object
		end
	end
	
	-- if no socket is given then return
	if recv == nil and send == nil then
		return {}, {}
	end
	
	-- collect any ready socket
	local readok, writeok, errmsg = selectsockets(recv, send, 0)
	
	-- check if job has completed
	if
		timeout ~= 0 and
		errmsg == "timeout" and
		next(readok) == nil and
		next(writeok) == nil
	then                                                                          --[[VERBOSE]] verbose:socket(true, "waiting for sockets to become ready")
		-- collect and register events of all sockets
		local thread = running()
		local event = EventGroup()
		if recv then
			for index, wrapper in ipairs(recvt) do
				watchsocket(wrapper.__object, reading)
				event:add(wrapper.readevent)
			end
		end
		if send then
			for index, wrapper in ipairs(sendt) do
				watchsocket(wrapper.__object, writing)
				event:add(wrapper.writeevent)
			end
		end
		
		-- setup timeout if necessary
		if timeout and timeout > 0 then
			if not timestamp then timeout = now()+timeout end
			event:settimeout(timeout)
		end
		
		-- block until some socket event is signal or timeout
		event:wait()
		
		-- clear timeout if necessary
		if timeout and timeout > 0 then
			event:settimeout(nil)
		end
		
		-- unregister and unlock sockets
		if recv then
			for index, wrapper in ipairs(recvt) do
				forgetsocket(wrapper.__object, reading)
				event:remove(wrapper.readevent)
			end
		end
		if send then
			for index, wrapper in ipairs(sendt) do
				forgetsocket(wrapper.__object, writing)
				event:remove(wrapper.writeevent)
			end
		end
		
		-- collect all ready sockets
		readok, writeok, errmsg = selectsockets(recv, send, 0)                      --[[VERBOSE]] verbose:socket(false, "waiting completed")
	end
	
	-- replace sockets for the corresponding cosocket wrapper
	for index, socket in ipairs(readok) do
		local wrapper = WrapperOf[socket]
		readok[index] = wrapper
		readok[wrapper] = true
		readok[socket] = nil
	end
	for index, socket in ipairs(writeok) do
		local wrapper = WrapperOf[socket]
		writeok[index] = wrapper
		writeok[wrapper] = true
		writeok[socket] = nil
	end                                                                           --[[VERBOSE]] verbose:socket(false, "returning sockets ready")
	
	return readok, writeok, errmsg
end

function sockets.sleep(timeout)
	assert(timeout, "bad argument #1 to `sleep' (number expected)")
	yield("delay", timeout)
end

function sockets.tcp()
	local result, errmsg = createtcp()
	if result then return WrapperOf[result] end
	return result, errmsg
end

function sockets.udp()
	local result, errmsg = createudp()
	if result then return WrapperOf[result] end
	return result, errmsg
end

function sockets.cosocket(socket)
	if type(socket) == "userdata" then
		socket = WrapperOf[socket]
	end
	return socket
end

function sockets.waitevent(timeout)
	return watchsockets(now()+timeout)
end

--[[VERBOSE]] verbose:setlevel(1, {"threads","socket"})
--[[VERBOSE]] local old = verbose.custom.state
--[[VERBOSE]] function verbose.custom:state(...)
--[[VERBOSE]] 	old(self, ...)
--[[VERBOSE]] 	local viewer = self.viewer
--[[VERBOSE]] 	local output = self.viewer.output
--[[VERBOSE]] 	local labels = self.viewer.labels
--[[VERBOSE]] 	if self.flags.state then
--[[VERBOSE]] 		local newline = "\n"..viewer.prefix
--[[VERBOSE]] 		output:write(newline,"Reading:")
--[[VERBOSE]] 		for _, socket in ipairs(reading) do
--[[VERBOSE]] 			output:write(" ",labels[socket])
--[[VERBOSE]] 		end
--[[VERBOSE]] 		output:write(newline,"Writing:")
--[[VERBOSE]] 		for _, socket in ipairs(writing) do
--[[VERBOSE]] 			output:write(" ",labels[socket])
--[[VERBOSE]] 		end
--[[VERBOSE]] 	end
--[[VERBOSE]] end

--------------------------------------------------------------------------------
-- End of Instantiation Code ---------------------------------------------------
--------------------------------------------------------------------------------

	return sockets
end

return setmetatable(new(), { __call = function(_, ...) return new(...) end })
