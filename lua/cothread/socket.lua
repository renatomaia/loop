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

local table = require "table"
local concat = table.concat

local socketcore = require "socket.core"
local selectsockets = socketcore.select
local createtcp = socketcore.tcp
local createudp = socketcore.udp

local tabop = require "loop.table"
local copy = tabop.copy
local memoize = tabop.memoize

local Wrapper = require "loop.object.Wrapper"                                   -- [[VERBOSE]] verbose = _G.require("cothread").verbose

local CoSocket = {}
local WrapperOf = memoize(function(socket)
	if socket then
		socket:settimeout(0)
		socket = copy(CoSocket, Wrapper{ __object = socket })
	end
	return socket
end, "k")


function CoSocket:settimeout(timeout, timestamp)                                -- [[VERBOSE]] verbose:socket("setting timeout of ",self,timestamp and " to moment " or " to ",timeout)
	if not timeout or timeout < 0 then
		self.timeout = nil
		self.timeoutkind = nil
	else
		self.timeout = timeout
		self.timeoutkind = timestamp and "defer" or "delay"
	end
end

function CoSocket:connect(...)                                                  -- [[VERBOSE]] verbose:socket(true, "connecting to ",...)
	-- connect the socket if possible
	local socket = self.__object
	local result, errmsg = socket:connect(...)
	
	-- check if the job has not yet been completed
	if not result and errmsg == "timeout" then
		local timeout = self.timeout
		if timeout ~= 0 then                                                        -- [[VERBOSE]] verbose:socket(true, "waiting for connection establishment")
			-- wait for a connection completion and finish establishment
			yield("waitwrite", socket, timeout, self.timeoutkind)
			yield("forgetwrite", socket)
			-- try to connect again one last time before giving up
			result, errmsg = socket:connect(...)
			if not result and errmsg == "already connected" then
				result, errmsg = 1, nil -- connection was already established
			end                                                                       -- [[VERBOSE]] verbose:socket(false, "waiting completed")
		end
	end                                                                           -- [[VERBOSE]] verbose:socket(false, "connection ",result and "established" or "failed")
	return result, errmsg
end

function CoSocket:accept(...)                                                   -- [[VERBOSE]] verbose:socket(true, "accepting a new connection")
	-- accept any connection request pending in the socket
	local socket = self.__object
	local result, errmsg = socket:accept(...)
	
	-- check if the job has not yet been completed
	local timeout = self.timeout
	if result then
		result = WrapperOf[result]
	elseif errmsg == "timeout" then
		if timeout ~= 0 then                                                        -- [[VERBOSE]] verbose:socket(true, "waiting for new connection request")
			-- wait for a connection request signal
			yield("waitread", socket, timeout, self.timeoutkind)
			yield("forgetread", socket)
			-- accept any connection request pending in the socket
			result, errmsg = socket:accept(...)
			if result then result = WrapperOf[result] end                             -- [[VERBOSE]] verbose:socket(false, "waiting completed")
		end
	end                                                                           -- [[VERBOSE]] verbose:socket(false, "new connection ",result and "accepted" or "failed")
	return result, errmsg
end

function CoSocket:send(data, i, j)                                              -- [[VERBOSE]] verbose:socket(true, "sending byte stream: ",verbose.viewer:tostring(data:sub(i or 1, j)))
	-- fill space already avaliable in the socket
	local socket = self.__object
	local result, errmsg, lastbyte = socket:send(data, i, j)

	-- check if the job has not yet been completed
	if not result and errmsg == "timeout" then
		local timeout = self.timeout
		if timeout ~= 0 then                                                        -- [[VERBOSE]] verbose:socket(true, "waiting for more space to write stream to be sent")
			-- wait for more space on the socket
			local event = yield("waitwrite", socket, timeout, self.timeoutkind)
			while event == socket do -- otherwise it was a timeout (event==nil)
				-- fill any space free on the socket one last time
				result, errmsg, lastbyte = socket:send(data, lastbyte+1, j)
				if result or errmsg ~= "timeout" then                                   -- [[VERBOSE]] verbose:socket("stream was sent until byte ",lastbyte)
					break
				end
				event = yield("yield") -- wait more
			end
			yield("forgetwrite", socket)
		end
	end                                                                           -- [[VERBOSE]] verbose:socket(false, "stream sending ",result and "completed" or "failed")
	
	return result, errmsg, lastbyte
end

function CoSocket:receive(pattern)                                              -- [[VERBOSE]] verbose:socket(true, "receiving byte stream")
	-- get data already avaliable in the socket
	local socket = self.__object
	local result, errmsg, partial = socket:receive(pattern)
	
	-- check if the job has not yet been completed
	if not result and errmsg == "timeout" then
		local timeout = self.timeout
		if timeout ~= 0 then                                                        -- [[VERBOSE]] verbose:socket(true, "waiting for new data to be read")
			-- initialize data read buffer with data already read
			local buffer = { partial }
			
			-- register socket for network event watch
			local event = yield("waitread", socket, timeout, self.timekind)
			while event == socket do -- otherwise it was a timeout (event==nil)
				-- reduce the number of required bytes
				if type(pattern) == "number" then
					pattern = pattern - #partial                                          -- [[VERBOSE]] verbose:socket("got more ",#partial," bytes, waiting for more ",pattern)
				end
	 			-- read any data left on the socket one last time
				result, errmsg, partial = socket:receive(pattern)
				if result then
					buffer[#buffer+1] = result
					break
				else
					buffer[#buffer+1] = partial
					if errmsg ~= "timeout" then
						break
					end
				end
				event = yield("yield")
			end
		
			-- concat buffered data
			if result then
				result = concat(buffer)
			else
				partial = concat(buffer)
			end
		
			yield("forgetread", socket, reading)                                      -- [[VERBOSE]] verbose:socket(false, "waiting completed")
		end
	end                                                                           -- [[VERBOSE]] verbose:socket(false, "data reading ",result and "completed: "..verbose.viewer:tostring(result) or "failed")
	
	return result, errmsg, partial
end

function CoSocket:close()                                                       -- [[VERBOSE]] verbose:socket("closing socket")
	return self.__object:close()
end

--------------------------------------------------------------------------------
-- Wrapped Lua Socket API ------------------------------------------------------
--------------------------------------------------------------------------------

local sockets = setmetatable({}, {__index = socketcore})

function sockets.select(recvt, sendt, timeout, timekind)                        -- [[VERBOSE]] verbose:socket(true, "selecting sockets ready")
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
	then                                                                          -- [[VERBOSE]] verbose:socket(true, "waiting for sockets to become ready")
		-- block until some socket event is signal or timeout
		yield("waitsockets", recv, send, timeout, timekind)
		yield("forgetsockets", recv, send)
		
		-- collect all ready sockets
		readok, writeok, errmsg = selectsockets(recv, send, 0)                      -- [[VERBOSE]] verbose:socket(false, "waiting completed")
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
	end                                                                           -- [[VERBOSE]] verbose:socket(false, "returning sockets ready")
	
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

return sockets