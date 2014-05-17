-- Project: CoThread
-- Release: 1.0 beta
-- Title  : Lua Socket Wrapper for Cooperative Scheduling
-- Author : Renato Maia <maia@inf.puc-rio.br>


local _G = require "_G"
local assert = _G.assert
local ipairs = _G.ipairs
local next = _G.next
local setmetatable = _G.setmetatable
local type = _G.type

local coroutine = require "coroutine"
local yield = coroutine.yield

local array = require "table"
local concat = array.concat

local socketcore = require "socket.core"
local selectsockets = socketcore.select
local createtcp = socketcore.tcp
local createudp = socketcore.udp

local table = require "loop.table"
local copy = table.copy
local memoize = table.memoize

local Wrapper = require "loop.object.Wrapper"                                   --[[VERBOSE]] local verbose = _G.require("cothread").verbose

local function trywait(self, socket, op)
	local timeout = self.timeout
	if timeout ~= 0 then
		local thread = yield("running")
		if timeout == nil then
			yield("unschedule", thread)
		else
			yield("schedule", thread, self.timeoutkind, timeout)
		end
		yield("addwait", socket, op, thread)
		return thread
	end
end

local CoSocket = {}
local function wrap(socket)
	if type(socket) == "userdata" then
		socket:settimeout(0)
		socket = copy(CoSocket, Wrapper{ __object = socket })
	end
	return socket
end


function CoSocket:settimeout(timeout, timestamp)                                --[[VERBOSE]] verbose:socket("setting timeout of ",self,timestamp and " to moment " or " for ",timeout)
	local oldtm, oldkd = self.timeout, self.timeoutkind
	if not timeout or timeout < 0 then
		self.timeout = nil
		self.timeoutkind = nil
	else
		self.timeout = timeout
		self.timeoutkind = timestamp and "defer" or "delay"
	end
	return 1, oldtm, (oldkd == "defer") or nil
end

function CoSocket:connect(...)                                                  --[[VERBOSE]] verbose:socket(true, "connecting to ",...)
	-- connect the socket if possible
	local socket = self.__object
	local result, errmsg = socket:connect(...)
	
	-- check if the job has not yet been completed
	if not result and errmsg == "timeout" then
		local thread = trywait(self, socket, "w")
		if thread ~= nil then                                                       --[[VERBOSE]] verbose:socket(true, "waiting for connection establishment")
			-- wait for a connection completion and finish establishment
			yield("yield")
			yield("unschedule", thread)
			-- try to connect again one last time before giving up
			result, errmsg = socket:connect(...)
			if not result and errmsg == "already connected" then
				result, errmsg = 1, nil -- connection was already established
			end                                                                       --[[VERBOSE]] verbose:socket(false, "waiting completed")
		end
	end                                                                           --[[VERBOSE]] verbose:socket(false, "connection ",result and "established" or "failed")
	return result, errmsg
end

function CoSocket:accept(...)                                                   --[[VERBOSE]] verbose:socket(true, "accepting a new connection")
	-- accept any connection request pending in the socket
	local socket = self.__object
	local result, errmsg = socket:accept(...)
	
	-- check if the job has not yet been completed
	if result then
		result = wrap(result)
	elseif errmsg == "timeout" then
		local thread = trywait(self, socket, "r")
		if thread ~= nil then                                                       --[[VERBOSE]] verbose:socket(true, "waiting for new connection request")
			-- wait for a connection request signal
			yield("yield")
			yield("unschedule", thread)
			-- accept any connection request pending in the socket
			result, errmsg = socket:accept(...)
			if result then result = wrap(result) end                                  --[[VERBOSE]] verbose:socket(false, "waiting completed")
		end
	end                                                                           --[[VERBOSE]] verbose:socket(false, "new connection ",result and "accepted" or "failed")
	return result, errmsg
end

function CoSocket:send(data, i, j)                                              --[[VERBOSE]] verbose:socket(true, "sending byte stream: ",verbose.viewer:tostring(data:sub(i or 1, j)))
	-- fill space already avaliable in the socket
	local socket = self.__object
	local result, errmsg, lastbyte, elapsed = socket:send(data, i, j)

	-- check if the job has not yet been completed
	if not result and errmsg == "timeout" then
		local thread = trywait(self, socket, "w")
		if thread ~= nil then                                                       --[[VERBOSE]] verbose:socket(true, "waiting for more space to write stream to be sent")
			-- wait for more space on the socket
			while yield("yield") == socket do -- otherwise it was a timeout (event==nil)
				-- fill any space free on the socket one last time
				local extra
				result, errmsg, lastbyte, extra = socket:send(data, lastbyte+1, j)
				if extra then elapsed = elapsed + extra end
				if result or errmsg ~= "timeout" then                                   --[[VERBOSE]] verbose:socket("stream was sent until byte ",lastbyte)
					break
				end
			end                                                                       --[[VERBOSE]] verbose:socket(false, "waiting completed")
			yield("unschedule", thread)
		end
	end                                                                           --[[VERBOSE]] verbose:socket(false, "stream sending ",result and "completed" or "failed")
	
	return result, errmsg, lastbyte, elapsed
end

function CoSocket:receive(pattern, ...)                                         --[[VERBOSE]] verbose:socket(true, "receiving byte stream")
	-- get data already avaliable in the socket
	local socket = self.__object
	local result, errmsg, partial, elapsed = socket:receive(pattern, ...)
	
	-- check if the job has not yet been completed
	if not result and errmsg == "timeout" then
		local thread = trywait(self, socket, "r")
		if thread ~= nil then                                                       --[[VERBOSE]] verbose:socket(true, "waiting for new data to be read")
			-- initialize data read buffer with data already read
			local buffer = { partial }
			
			-- register socket for network event watch
			while yield("yield") == socket do -- otherwise it was a timeout (event==nil)
				-- reduce the number of required bytes
				if type(pattern) == "number" then
					pattern = pattern - #partial                                          --[[VERBOSE]] verbose:socket("got more ",#partial," bytes, waiting for more ",pattern)
				end
				-- read any data left on the socket one last time
				local extra
				result, errmsg, partial, extra = socket:receive(pattern)
				if extra then elapsed = elapsed + extra end
				if result then
					buffer[#buffer+1] = result
					break
				else
					buffer[#buffer+1] = partial
					if errmsg ~= "timeout" then
						break
					end
				end
			end
		
			-- concat buffered data
			if result then
				result = concat(buffer)
			else
				partial = concat(buffer)
			end                                                                       --[[VERBOSE]] verbose:socket(false, "waiting completed")
		
			yield("unschedule", thread)
		end
	end                                                                           --[[VERBOSE]] verbose:socket(false, "data reading ",result and "completed: "..verbose.viewer:tostring(result) or "failed: ".._G.tostring(errmsg))
	
	return result, errmsg, partial, elapsed
end

function CoSocket:close()                                                       --[[VERBOSE]] verbose:socket(true, "closing socket")
	local socket = self.__object
	local result, errmsg = socket:close()
	yield("notifyclose", socket)                                                  --[[VERBOSE]] verbose:socket(false)
	return result, errmsg
end

--------------------------------------------------------------------------------
-- Wrapped Lua Socket API ------------------------------------------------------
--------------------------------------------------------------------------------

local sockets = setmetatable({
	cosocket = wrap,
	trywait = trywait,
}, {__index = socketcore})

function sockets.select(recvt, sendt, timeout, timekind)                        --[[VERBOSE]] verbose:socket(true, "selecting sockets ready")
	-- collect sockets and check for concurrent use
	local wrapperOf = {}
	local recv, send
	if recvt and #recvt > 0 then
		recv = {}
		for index, wrapper in ipairs(recvt) do
			local socket = wrapper.__object
			wrapperOf[socket] = wrapper
			recv[index] = socket
		end
	end
	if sendt and #sendt > 0 then
		send = {}
		for index, wrapper in ipairs(sendt) do
			local socket = wrapper.__object
			wrapperOf[socket] = wrapper
			send[index] = socket
		end
	end
	
	-- if no socket is given then return
	if recv == nil and send == nil then
		return {}, {}, "timeout"
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
		-- block until some socket event is signal or timeout
		local thread = yield("running")
		if timeout == nil then
			yield("unschedule", thread)
		else
			yield("schedule", thread, timekind, timeout)
		end
		for _, socket in ipairs(recv) do
			yield("addwait", socket, "r", thread)
		end
		for _, socket in ipairs(send) do
			yield("addwait", socket, "w", thread)
		end
		yield("yield")
		yield("unschedule", thread)
		
		-- collect all ready sockets
		readok, writeok, errmsg = selectsockets(recv, send, 0)                      --[[VERBOSE]] verbose:socket(false, "waiting completed")
	end
	
	-- replace sockets for the corresponding cosocket wrapper
	for index, socket in ipairs(readok) do
		local wrapper = wrapperOf[socket]
		readok[index] = wrapper
		readok[wrapper] = true
		readok[socket] = nil
	end
	for index, socket in ipairs(writeok) do
		local wrapper = wrapperOf[socket]
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
	return wrap(createtcp())
end

function sockets.udp()
	return wrap(createudp())
end

return sockets
