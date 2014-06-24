--------------------------------------------------------------------------------
-- Project: LuaCooperative                                                    --
-- Release: 2.0 beta                                                          --
-- Title  :                                                                   --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------

local _G = require "_G"
local assert = _G.assert
local ipairs = _G.ipairs
local setmetatable = _G.setmetatable
local type = _G.type

local coroutine = require "coroutine"
local yield = coroutine.yield

local array = require "table"
local concat = array.concat

local table = require "loop.table"
local copy = table.copy

local Wrapper = require "loop.object.Wrapper"                                   --[[VERBOSE]] local verbose = _G.require("cothread").verbose

local cosocket = require "cothread.socket"
local createtcp = cosocket.tcp
local selectsockets = cosocket.select
local trywait = cosocket.trywait

local ssl = require "ssl"
local newctxt = ssl.newcontext
local sslwrap = ssl.wrap

local SSLSocket = {}

function SSLSocket:dohandshake()
	local result, errmsg
	local socket = self.__object
	local sslcontext = self.sslcontext
	if sslcontext ~= nil then                                                     --[[VERBOSE]] verbose:ssl("initialize SSL handshake")
		self.peerhost, self.peerport = socket:getpeername()
		if self.peerhost == nil then return nil, self.peerport end
		result, errmsg = sslwrap(socket, sslcontext)
		if not result then return nil, errmsg end
		socket:close()
		socket = result
		self.__object = socket
		self.sslcontext = nil
		assert(socket:settimeout(0))                                                --[[VERBOSE]] else verbose:ssl("resuming SSL handshake")
	end
	result, errmsg = socket:dohandshake()
	while not result do
		local op
		if errmsg == "wantread" then
			op = "r"
		elseif errmsg == "wantwrite" then
			op = "w"
		else                                                                        --[[VERBOSE]] verbose:ssl("unable to complete handshake: ",errmsg)
			break
		end
		local thread = trywait(self, socket, op)
		if thread ~= nil then                                                       --[[VERBOSE]] verbose:ssl("wait to complete handshake: ",errmsg)
			yield("yield")
			yield("unschedule", thread)
			result, errmsg = socket:dohandshake()
		else                                                                        --[[VERBOSE]] verbose:ssl("unable to complete handshake due to no timeout")
			result, errmsg = nil, "timeout"
			break
		end
	end
	if result then
		result = self
		self.sslhandshake = true
	end

	if not result and errmsg == "Bad file descriptor" then
		errmsg = "closed"
	end

	return result, errmsg
end

function SSLSocket:getpeername()
	local host = self.peerhost
	if host == nil then return self.__object:getpeername() end
	return host, self.peerport
end

do
	local err2op = {
		timeout = "w",
		wantread = "r",
		wantwrite = "w",
	}
	function SSLSocket:send(data, i, j)                                            --[[VERBOSE]] verbose:socket(true, "sending byte stream: ",verbose.viewer:tostring(data:sub(i or 1, j)))
		if self.sslhandshake == nil then
			local result, errmsg = self:dohandshake()
			if not result then
				return nil, errmsg, i==nil and 0 or i-1, 0
			end
		end
		local socket = self.__object
		local result, errmsg, lastbyte, elapsed = socket:send(data, i, j)

		-- check if the job has not yet been completed
		local op = err2op[errmsg]
		if not result and op ~= nil then
			errmsg = "timeout"
			local thread = trywait(self, socket, op)
			if thread ~= nil then                                                     --[[VERBOSE]] verbose:socket(true, "waiting for more space to write stream to be sent")
				-- wait for more space on the socket
				while yield("yield") == socket do -- otherwise it was a timeout (event==nil)
					-- fill any space free on the socket one last time
					local extra
					result, errmsg, lastbyte, extra = socket:send(data, lastbyte+1, j)
					if extra then elapsed = elapsed + extra end
					local newop = err2op[errmsg]
					if result or newop == nil then                                        --[[VERBOSE]] verbose:socket("stream was sent until byte ",lastbyte)
						break
					else
						errmsg = "timeout"
						if newop ~= op then                                                 --[[VERBOSE]] verbose:ssl("changing socket event from ",op," to ",newop," due to SSL protocol")
							op = newop
							yield("unschedule", thread)
							thread = trywait(self, socket, op)
						end
					end
				end                                                                     --[[VERBOSE]] verbose:socket(false, "waiting completed")
				yield("unschedule", thread)
			end
		end                                                                         --[[VERBOSE]] verbose:socket(false, "stream sending ",result and "completed" or "failed")

		if not result and errmsg == "Broken pipe" then
			errmsg = "closed"
		end

		return result, errmsg, lastbyte, elapsed
	end
end

do
	local err2op = {
		timeout = "r",
		wantread = "r",
		wantwrite = "w",
	}
	function SSLSocket:receive(pattern, ...)
		if self.sslhandshake == nil then
			local result, errmsg = self:dohandshake()
			if not result then
				return nil, errmsg, "", 0
			end
		end                                                                         --[[VERBOSE]] verbose:socket(true, "receiving byte stream")
		local socket = self.__object
		local result, errmsg, partial, elapsed = socket:receive(pattern, ...)

		-- check if the job has not yet been completed
		local op = err2op[errmsg]
		if not result and op ~= nil then
			errmsg = "timeout"
			local thread = trywait(self, socket, op)
			if thread ~= nil then                                                     --[[VERBOSE]] verbose:socket(true, "waiting for new data to be read")
				-- initialize data read buffer with data already read
				local buffer = { partial }
				
				-- register socket for network event watch
				while yield("yield") == socket do -- otherwise it was a timeout (event==nil)
					-- reduce the number of required bytes
					if type(pattern) == "number" then
						pattern = pattern - #partial                                        --[[VERBOSE]] verbose:socket("got more ",#partial," bytes, waiting for more ",pattern)
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
						local newop = err2op[errmsg]
						if newop == nil then
							break
						else
							errmsg = "timeout"
							if newop ~= op then                                               --[[VERBOSE]] verbose:ssl("changing socket event from ",op," to ",newop," due to SSL protocol")
								op = newop
								yield("unschedule", thread)
								thread = trywait(self, socket, op)
							end
						end
					end
				end
				
				-- concat buffered data
				if result then
					result = concat(buffer)
				else
					partial = concat(buffer)
				end                                                                     --[[VERBOSE]] verbose:socket(false, "waiting completed")

				yield("unschedule", thread)
			end
		end                                                                         --[[VERBOSE]] verbose:socket(false, "data reading ",result and "completed" or "failed")

		return result, errmsg, partial, elapsed
	end
end

--------------------------------------------------------------------------------
-- Wrapped Lua Socket API ------------------------------------------------------
--------------------------------------------------------------------------------

local sockets = setmetatable({}, {__index = cosocket})

function sockets.sslcontext(...)
	return newctxt(...)
end

function sockets.ssl(socket, context)
	copy(SSLSocket, socket)
	socket.sslcontext = context
	return socket
end

function sockets.select(recvt, sendt, timeout, timekind)                        --[[VERBOSE]] verbose:socket(true, "selecting sockets ready")
	-- collect sockets and check for concurrent use
	local defset = {}
	local recv, send
	if recvt ~= nil then
		recv = {}
		defset[recvt] = recv
	end
	if sendt ~= nil then
		send = {}
		defset[sendt] = send
	end
	local want2set = {
		read = recv,
		write = send,
	}
	for input, output in pairs(defset) do
		for index, socket in ipairs(input) do
			if socket.want ~= nil then
				local newset = want2set[socket:want()]
				if newset ~= output then
					defset[socket] = true
					output = newset
				end
			end
			output[#output+1] = socket
		end
	end

	-- collect any ready socket
	local readok, writeok, errmsg = selectsockets(recv, send, 0)

	-- replace sockets for the corresponding cosocket wrapper
	local readres, writeres = {}, {}
	local out2res = {
		[false] = readres,
		[true] = writeres,
	}
	for key, result in pairs(out2res) do
		for index, socket in ipairs(key and writeok or readok) do
			if defset[socket] ~= nil then
				result = out2res[not key]
			end
			result[result+1] = socket
			result[socket] = true
		end
	end                                                                           --[[VERBOSE]] verbose:socket(false, "returning sockets ready")
	
	return readok, writeok, errmsg
end

return sockets
