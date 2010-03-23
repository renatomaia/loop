-- Project: CoThread
-- Release: 1.0 beta
-- Title  : Lua Socket Wrapper for Cooperative Scheduling
-- Author : Renato Maia <maia@inf.puc-rio.br>


local _G = require "_G"
local assert = _G.assert
local ipairs = _G.ipairs
local newproxy = _G.newproxy
local next = _G.next
local require = _G.require
local select = _G.select
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

module(...)

local TimeOutToken = newproxy()

--------------------------------------------------------------------------------
-- Begin of Instantiation Code -------------------------------------------------
--------------------------------------------------------------------------------

local default = _M
function new(attribs)
	local socketcore = attribs.socketcore or require("socket.core")
	local scheduler = attribs.scheduler or require("cothread")
	scheduler.now = socketcore.gettime
	copy(socketcore, attribs)
	_G.setfenv(1, attribs) -- Lua 5.2: in attribs do

--------------------------------------------------------------------------------
-- Initialization Code ---------------------------------------------------------
--------------------------------------------------------------------------------

local now = scheduler.now
local round = scheduler.round
local schedule = scheduler.schedule
local unschedule = scheduler.unschedule
local wakeall = scheduler.wakeall                                               --[[VERBOSE]] local verbose = scheduler.verbose

local sleep = socketcore.sleep
local selectsockets = socketcore.select
local createtcp = socketcore.tcp
local createudp = socketcore.udp

local function idle(timeout)                                                    --[[VERBOSE]] verbose:scheduler("process sleeping for ",timeout-now()," seconds")
	sleep(timeout-now())                                                          --[[VERBOSE]] verbose:scheduler("sleeping ended")
end



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
end)

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
	opset:add(socket)
	if not watching then
		watching = true
		scheduler.idle = watchsockets
	end
end
local function forgetsocket(socket, opset)
	opset:remove(socket)
	if watching and #reading == 0 and #writing == 0 then
		watching = nil
		scheduler.idle = idle
	end
end

local function roundcont(result, ...)
	if result == false and #reading > 0 or #writing > 0 then
		result = huge
	end
	return result, ...
end
function scheduler.round(...)
	if not wasidle then watchsockets(0) end
	wasidle = nil
	return roundcont(round(...))
end


function scheduler.signalcanceled(socket)
	if reading[socket] then
		forgetsocket(socket, reading)
	elseif writing[socket] then
		forgetsocket(socket, writing)
	end
end

--------------------------------------------------------------------------------
-- Wrapped Socket Methods ------------------------------------------------------
--------------------------------------------------------------------------------

local Timer2Operation = {
	readtimer = "reading",
	writetimer = "writing",
}

function CoSocket:settimeout(timeout)                                           --[[VERBOSE]] verbose:socket("setting timeout of ",self," to ",timeout," seconds")
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

function CoSocket:connect(...)
	if self.writing then return nil, "already in use" end
	
	-- connect the socket if possible
	local socket = self.__object
	local result, errmsg = socket:connect(...)
	
	-- check if the job has not yet been completed
	local timeout = self.timeout
	if not result and errmsg == "timeout" and timeout ~= 0 then                   --[[VERBOSE]] verbose:socket(true, "waiting for connection establishment")
		watchsocket(socket, writing) -- register socket for network event watch
		self.writing = running()     -- set this socket is being written
		
		-- start timer for counting the timeout
		local timer = timeout and self.writetimer
		if timer then schedule(timer, "delay", timeout) end
		
		-- wait for a connection completion and finish establishment
		local _, token = yield("wait", self.writeevent)
		if token == TimeOutToken then
			timer = nil
		else -- connection was established
			result, errmsg = 1, nil
		end
		
		-- cancel timer if it was not triggered
		if timer then unschedule(timer) end
		
		self.writing = nil
		forgetsocket(socket, writing)                                               --[[VERBOSE]] verbose:socket(false)
	end                                                                           --[[VERBOSE]] verbose:socket("connection ",result and "established" or "failed")
	return result, errmsg
end

function CoSocket:accept(...)
	if self.reading then return nil, "already in use" end

	-- accept any connection request pending in the socket
	local socket = self.__object
	local result, errmsg = socket:accept(...)
	
	-- check if the job has not yet been completed
	local timeout = self.timeout
	if result then
		result = WrapperOf[result]
	elseif errmsg == "timeout" and timeout ~= 0 then                              --[[VERBOSE]] verbose:socket(true, "waiting for new connection request")
		watchsocket(socket, reading) -- register socket for network event watch
		self.reading = running()     -- set this socket is being read
		
		-- start timer for counting the timeout
		local timer = timeout and self.readtimer
		if timer then yield("schedule", timer, "delay", timeout) end
		
		local done
		repeat
			-- wait for a connection request signal
			local _, token = yield("wait", self.readevent)
			if token == TimeOutToken then done = "timeout" end
		
			-- accept any connection request pending in the socket
			result, errmsg = socket:accept(...)
			if result then
				done = "success"
				result = WrapperOf[result]
			elseif errmsg ~= "timeout" then
				done = "failure"
			end
		until done
		
		-- cancel timer if it was not triggered
		if timer and done ~= "timeout" then unschedule(timer) end
		
		self.reading = nil
		forgetsocket(socket, reading)                                               --[[VERBOSE]] verbose:socket(false)
	end                                                                           --[[VERBOSE]] verbose:socket("new connection ",result and "accepted" or "failed")
	return result, errmsg
end

function CoSocket:send(data, i, j)
	if self.writing then return nil, "already in use" end
	
	-- fill space already avaliable in the socket
	local socket = self.__object
	local result, errmsg, lastbyte = socket:send(data, i, j)

	-- check if the job has not yet been completed
	local timeout = self.timeout
	if not result and errmsg == "timeout" and timeout ~= 0 then                   --[[VERBOSE]] verbose:socket(true, "waiting for more space to write stream to be sent")
		watchsocket(socket, writing) -- register socket for network event watch
		self.writing = running()     -- set this socket is being written
		
		-- start timer for counting the timeout
		local timer = timeout and self.writetimer
		if timer then yield("schedule", timer, "delay", timeout) end
		
		local done
		repeat
			-- wait for more space on the socket
			local _, token = yield("wait", self.writeevent)
			if token == TimeOutToken then done = "timeout" end
			-- fill any space free on the socket
			result, errmsg, lastbyte = socket:send(data, lastbyte+1, j)
			if result then
				done = "success"
			elseif errmsg ~= "timeout" then
				done = "failure"                                                        --[[VERBOSE]] else verbose:socket("stream was sent until byte ",lastbyte)
			end
		until done
		
		-- cancel timer if it was not triggered
		if timer and done ~= "timeout" then unschedule(timer) end
		
		self.writing = nil
		forgetsocket(socket, writing)                                               --[[VERBOSE]] verbose:socket(false)
	end                                                                           --[[VERBOSE]] verbose:socket("stream sending ",result and "completed" or "failed")
	
	return result, errmsg, lastbyte
end

function CoSocket:receive(pattern)
	if self.reading then return nil, "already in use" end
	
	-- get data already avaliable in the socket
	local socket = self.__object
	local result, errmsg, partial = socket:receive(pattern)
	
	-- check if the job has not yet been completed
	local timeout = self.timeout
	if not result and errmsg == "timeout" and timeout ~= 0 then                   --[[VERBOSE]] verbose:socket(true, "waiting for new data to be read")
		watchsocket(socket, reading) -- register socket for network event watch
		self.reading = running()     -- set this socket is being read
		
		-- start timer for counting the timeout
		local timer = timeout and self.writetimer
		if timer then yield("schedule", timer, "delay", timeout) end
		
		-- initialize data read buffer with data already read
		local buffer = { partial }
		
		local done
		repeat
			-- reduce the number of required bytes
			if type(pattern) == "number" then
				pattern = pattern - #partial                                            --[[VERBOSE]] verbose:socket("got more ",#partial," bytes, waiting for more ",pattern)
			end
			-- wait for more data on the socket
			local _, token = yield("wait", self.readevent)
			if token == TimeOutToken then done = "timeout" end
			-- read any data left on the socket
			result, errmsg, partial = socket:receive(pattern)
			if result then
				buffer[#buffer+1] = result
				done = "success"
			else
				buffer[#buffer+1] = partial
				if errmsg ~= "timeout" then done = "failure" end
			end
		until done
		
		-- concat buffered data
		if result then
			result = concat(buffer)
		else
			partial = concat(buffer)
		end
		
		-- cancel timer if it was not triggered
		if timer and done ~= "timeout" then unschedule(timer) end
		
		self.reading = nil
		forgetsocket(socket, reading)                                               --[[VERBOSE]] verbose:socket(false)
	end                                                                           --[[VERBOSE]] verbose:socket("data reading ",result and "completed" or "failed")
	
	return result, errmsg, partial
end

--------------------------------------------------------------------------------
-- Wrapped Lua Socket API ------------------------------------------------------
--------------------------------------------------------------------------------

function select(recvt, sendt, timeout)
	-- collect sockets and check for concurrent use
	local recv, send
	if recvt and #recvt > 0 then
		recv = {}
		for index, wrapper in ipairs(recvt) do
			if wrapper.reading then return nil, nil, "already in use" end
			recv[index] = wrapper.__object
		end
	end
	if sendt and #sendt > 0 then
		send = {}
		for index, wrapper in ipairs(sendt) do
			if wrapper.writing then return nil, nil, "already in use" end
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
	then
		-- register, lock and collect events of all sockets
		local event = {}
		if recv then
			for index, wrapper in ipairs(recvt) do
				watchsocket(wrapper.__object, reading)
				wrapper.reading = true
				event[#event+1] = wrapper.readevent
			end
		end
		if send then
			for index, wrapper in ipairs(sendt) do
				watchsocket(wrapper.__object, writing)
				wrapper.writing = true
				event[#event+1] = wrapper.writeevent
			end
		end
		
		-- block until some socket event is signal or timeout
		event.timeout = timeout
		EventGroup(event):wait()
		
		-- unregister and unlock sockets
		if recv then
			for index, wrapper in ipairs(recvt) do
				forgetsocket(wrapper.__object, reading)
				wrapper.reading = nil
			end
		end
		if send then
			for index, wrapper in ipairs(sendt) do
				forgetsocket(wrapper.__object, writing)
				wrapper.writing = nil
			end
		end
		
		-- collect all ready sockets
		readok, writeok, errmsg = selectsockets(recv, send, 0)
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
	end
	
	return readok, writeok, errmsg
end

function sleep(timeout)
	assert(timeout, "bad argument #1 to `sleep' (number expected)")
	yield("delay", timeout)
end

function tcp()
	local result, errmsg = createtcp()
	if result then return WrapperOf[result] end
	return result, errmsg
end

function udp()
	local result, errmsg = createudp()
	if result then return WrapperOf[result] end
	return result, errmsg
end

function cosocket(socket)
	if type(socket) == "userdata" then
		socket = WrapperOf[socket]
	end
	return socket
end

function waitevent(timeout)
	return watchsockets(now()+timeout)
end

--[[VERBOSE]] local old = verbose.custom.threads
--[[VERBOSE]] function verbose.custom:threads(...)
--[[VERBOSE]] 	old(self, ...)
--[[VERBOSE]] 	local viewer = self.viewer
--[[VERBOSE]] 	local output = self.viewer.output
--[[VERBOSE]] 	local labels = self.viewer.labels
--[[VERBOSE]] 	if self.flags.state then
--[[VERBOSE]] 		local newline = "\n"..viewer.prefix..viewer.indentation
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
-- End of Instantiation Code -------------------------------------------------
--------------------------------------------------------------------------------

	_G.setfenv(1, default) -- Lua 5.2: end
	return attribs
end
setmetatable(new(_M), { __call = function(_, attribs) return new(attribs) end })
