--------------------------------------------------------------------------------
---------------------- ##       #####    #####   ######  -----------------------
---------------------- ##      ##   ##  ##   ##  ##   ## -----------------------
---------------------- ##      ##   ##  ##   ##  ######  -----------------------
---------------------- ##      ##   ##  ##   ##  ##      -----------------------
---------------------- ######   #####    #####   ##      -----------------------
----------------------                                   -----------------------
----------------------- Lua Object-Oriented Programming ------------------------
--------------------------------------------------------------------------------
-- Project: LOOP Class Library                                                --
-- Release: 2.3 beta                                                          --
-- Title  : Lua Socket Wrapper for Cooperative Scheduling                     --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------

--[[VERBOSE]] local verbose = require("loop.thread.Scheduler").verbose
--[[VERBOSE]] verbose.groups.concurrency[#verbose.groups.concurrency+1] = "cosocket"
--[[VERBOSE]] verbose:newlevel{"cosocket"}

local ipairs       = ipairs
local assert       = assert
local setmetatable = setmetatable
local type         = type
local next         = next
local coroutine    = require "coroutine"
local oo           = require "loop.base"
local Wrapper      = require "loop.object.Wrapper"

module("loop.thread.CoSocket", oo.class)

--------------------------------------------------------------------------------
-- Initialization Code ---------------------------------------------------------
--------------------------------------------------------------------------------

function __init(class, self, scheduler)
	self = oo.rawnew(class, self)
	self.readlocks = {}
	self.writelocks = {}
	if not self.scheduler then
		self.scheduler = scheduler
	end
	return self
end

function __index(self, field)
	return _M[field] or self.socketapi[field]
end

--------------------------------------------------------------------------------
-- Wrapping functions ----------------------------------------------------------
--------------------------------------------------------------------------------

local function wrappedsettimeout(self, timeout)
	self.timeout = timeout or false
end

local function wrappedsettimeout(self, timeout)
	self.timeout    = timeout or false
	self.readevent  = self.__object
	self.writeevent = self
	if timeout and timeout > 0 then
		self.readevent  = EventGroup{ self.readevent , timeout = timeout }
		self.writeevent = EventGroup{ self.writeevent, timeout = timeout }
	end
end

--------------------------------------------------------------------------------

local function wrappedconnect(self, host, port)                                 --[[VERBOSE]] local verbose = self.cosocket.scheduler.verbose
	local socket = self.__object                                                  --[[VERBOSE]] verbose:cosocket(true, "performing blocking connect")
	socket:settimeout(-1)
	local result, errmsg = socket:connect(host, port)
	socket:settimeout(0)                                                          --[[VERBOSE]] verbose:cosocket(false, "blocking connect done")
	return result, errmsg
end

local function wrappedconnect(self, ...)
	local socket    = self.__object
	local timeout   = self.timeout
	local cosocket  = self.cosocket
	local scheduler = cosocket.scheduler                                          --[[VERBOSE]] local verbose = scheduler.verbose
	local current   = scheduler:checkcurrent()                                    --[[VERBOSE]] verbose:cosocket(true, "performing wrapped accept")
	
	assert(socket, "bad argument #1 to `connect' (wrapped socket expected)")
	
	local success, errmsg = socket:connect(...)
	
	-- check if job has completed
	if not success and errmsg == "timeout" and timeout ~= 0 then                  --[[VERBOSE]] verbose:cosocket(true, "waiting to connection be established")
		local event = self.writeevent
		local writing = cosocket.writing
		
		-- subscribing current socket for writing signal
	
		-- wait for writing signal until timeout
		writing:add(socket, self)                                                   --[[VERBOSE]] verbose:threads(current," subscribed for write signal")
		event:activate()
		local trigger = scheduler:wait(event)                                       --[[VERBOSE]] verbose:cosocket(false, "wrapped accept resumed")    
		event:deactivate()
		writing:remove(socket)                                                      --[[VERBOSE]] verbose:threads(current," unsubscribed for write signal")
		
		-- if trigger was the socket itself then connection was estabilshed
		if trigger == self then
			success, errmsg = socket:connect(...)                                     --[[VERBOSE]] verbose:cosocket(false, "returing results after waiting")
		else
			success, errmsg = nil, "timeout"                                          --[[VERBOSE]] verbose:cosocket(false, "waiting timed out")
		end
	end
	
	return success, errmsg
end

--------------------------------------------------------------------------------

local function wrappedaccept(self, ...)
	local socket    = self.__object
	local timeout   = self.timeout
	local cosocket  = self.cosocket
	local scheduler = cosocket.scheduler                                          --[[VERBOSE]] local verbose = scheduler.verbose
	local current   = scheduler:checkcurrent()                                    --[[VERBOSE]] verbose:cosocket(true, "performing wrapped accept")

	assert(socket, "bad argument #1 to `accept' (wrapped socket expected)")
	
	local result, errmsg = socket:accept(...)
	if result then                                                                --[[VERBOSE]] verbose:cosocket("connection accepted without waiting")
		result = cosocket:wrap(result)
	elseif errmsg == "timeout" and timeout ~= 0 then                              --[[VERBOSE]] verbose:cosocket(true, "waiting for results")
		local event   = self.readevent
		local reading = cosocket.reading
		
		-- wait for signal until timeout
		reading:add(socket, socket)                                                 --[[VERBOSE]] verbose:threads(current," subscribed for read signal")
		event:activate()
		local trigger = scheduler:wait(event)                                       --[[VERBOSE]] verbose:cosocket(false, "wrapped accept resumed")
		event:deactivate()
		reading:remove(socket)                                                      --[[VERBOSE]] verbose:threads(current," unsubscribed for read signal")
		
		-- if trigger was the socket itself then connection was estabilshed
		if trigger == socket then
			result, errmsg = cosocket:wrap(socket:accept()), nil
		elseif timeout then
			result, errmsg = nil, "timeout"                                           --[[VERBOSE]] verbose:cosocket("waiting timed out")
		end                                                                         --[[VERBOSE]] else verbose:cosocket("returning error ",errmsg," without waiting")
	end                                                                           --[[VERBOSE]] verbose:cosocket(false)
	
	return result, errmsg
end

--------------------------------------------------------------------------------

local function wrappedreceive(self, pattern)
	local socket    = self.__object
	local timeout   = self.timeout
	local cosocket  = self.cosocket
	local scheduler = cosocket.scheduler                                          --[[VERBOSE]] local verbose = scheduler.verbose
	local current   = scheduler:checkcurrent()                                    --[[VERBOSE]] verbose:cosocket(true, "performing wrapped receive")

	assert(socket, "bad argument #1 to `receive' (wrapped socket expected)")

	-- get data already avaliable
	local result, errmsg, partial = socket:receive(pattern)

	-- check if job has completed
	if not result and errmsg == "timeout" and timeout ~= 0 then                   --[[VERBOSE]] verbose:cosocket(true, "waiting for remaining of results")
		local event   = self.readevent
		local reading = cosocket.reading
		
		-- reduce the number of required bytes
		if type(pattern) == "number" then
			pattern = pattern - #partial                                              --[[VERBOSE]] verbose:cosocket("amount of required bytes reduced to ",pattern)
		end
		
		-- subscribing current socket for reading signal
		reading:add(socket, socket)                                                 --[[VERBOSE]] verbose:threads(current," subscribed for read signal")
		event:activate()
		repeat
			-- stop current thread
			local trigger = scheduler:wait(event)                                     --[[VERBOSE]] verbose:cosocket(false, "wrapped receive resumed")
			-- check if the socket is ready
			if trigger == socket then                                                 --[[VERBOSE]] verbose:cosocket "reading more data from socket"
				local newdata
				result, errmsg, newdata = socket:receive(pattern)
				if result then                                                          --[[VERBOSE]] verbose:cosocket "received all requested data"
					result, errmsg, partial = partial..result, nil, nil                   --[[VERBOSE]] verbose:cosocket(false, "returning results after waiting")
				else                                                                    --[[VERBOSE]] verbose:cosocket "received only partial data"
					partial = partial..newdata
					if errmsg == "timeout" then
						-- reduce the number of required bytes
						if type(pattern) == "number" then
							pattern = pattern - #newdata                                      --[[VERBOSE]] verbose:cosocket("amount of required bytes reduced to ",pattern)
						end
						-- cancel error message
						errmsg = nil                                                        --[[VERBOSE]] else verbose:cosocket(false, "returning error ",errmsg," after waiting")
					end
				end
			else
				errmsg = "timeout"                                                      --[[VERBOSE]] verbose:cosocket(false, "wrapped send timed out")
			end
		until result or errmsg
		event:deactivate()
		reading:remove(socket)                                                      --[[VERBOSE]] verbose:threads(current," unsubscribed for read signal")
	end
	
	return result, errmsg, partial
end

--------------------------------------------------------------------------------

local function wrappedsend(self, data, i, j)
	local socket    = self.__object
	local timeout   = self.timeout
	local cosocket  = self.cosocket
	local scheduler = cosocket.scheduler                                          --[[VERBOSE]] local verbose = scheduler.verbose
	local current   = scheduler:checkcurrent()                                    --[[VERBOSE]] verbose:cosocket(true, "performing wrapped send")

	assert(socket, "bad argument #1 to `send' (wrapped socket expected)")

	-- fill buffer space already avaliable
	local sent, errmsg, lastbyte = socket:send(data, i, j)

	-- check if job has completed
	if not sent and errmsg == "timeout" and timeout ~= 0 then                     --[[VERBOSE]] verbose:cosocket(true, "waiting to send remaining data")
		local event = self.writeevent
		local writing = cosocket.writing
		
		-- subscribing current socket for writing signal
		writing:add(socket, self)                                                   --[[VERBOSE]] verbose:threads(current," subscribed for write signal")
		event:activate()
		repeat
			-- stop current thread
			local trigger = scheduler:wait(event)                                     --[[VERBOSE]] verbose:cosocket "wrapped send resumed"
			-- check if the socket is ready
			if trigger == self then                                                   --[[VERBOSE]] verbose:cosocket "writing remaining data into socket"
				sent, errmsg, lastbyte = socket:send(data, lastbyte+1, j)
				if not sent and errmsg == "timeout" then
					-- cancel error message
					errmsg = nil                                                          --[[VERBOSE]] elseif sent then verbose:cosocket "sent all supplied data" else verbose:cosocket("returning error ",errmsg," after waiting")
				end
			else
				errmsg = "timeout"                                                      --[[VERBOSE]] verbose:cosocket "wrapped send timed out"
			end
		until sent or errmsg
		event:deactivate()
		writing:remove(socket)                                                      --[[VERBOSE]] verbose:threads(current," unsubscribed for write signal") else verbose:cosocket(false, "send done without waiting")
	end
	
	return sent, errmsg, lastbyte
end

--------------------------------------------------------------------------------
-- Wrapped Socket API ----------------------------------------------------------
--------------------------------------------------------------------------------

function select(self, recvt, sendt, timeout)
	local scheduler = self.scheduler                                              --[[VERBOSE]] local verbose = scheduler.verbose
	local current = scheduler:checkcurrent()                                      --[[VERBOSE]] verbose:cosocket(true, "performing wrapped select")
		
	if (recvt and #recvt > 0) or (sendt and #sendt > 0) then
		local recv, send
		-- assert that no thread is already blocked on these sockets
		if recvt then
			recv = {}
			for index, wrapper in ipairs(recvt) do
				recv[index] = wrapper.__object
			end
		end
		if sendt then
			send = {}
			for index, wrapper in ipairs(sendt) do
				send[index] = wrapper.__object
			end
		end
		
		local readok, writeok, errmsg = scheduler.select(recv, send, 0)
		
		if
			timeout ~= 0 and
			errmsg == "timeout" and
			next(readok) == nil and
			next(writeok) == nil
		then                                                                        --[[VERBOSE]] verbose:cosocket(true, "waiting for ready socket selection")
			local reading = self.reading
			local writing = self.writing
	
			-- block current thread on the sockets and lock them
			if recv then
				for _, socket in ipairs(recv) do
					reading:add(socket, socket)                                           --[[VERBOSE]] verbose:threads(current," subscribed for read signal")
				end
			end
			if send then
				for index, socket in ipairs(send) do
					local wrapper = sendt[index]
					recv[#recv+1] = wrapper
					writing:add(socket, wrapper)                                          --[[VERBOSE]] verbose:threads(current," subscribed for write signal")
				end
			end
			recv.timeout = timeout
			local event = EventGroup(recv)
			
			event:activate()
			local trigger = scheduler:wait(event)
			event:deactivate()
			
			-- check which sockets are ready and remove block for other sockets
			if recvt then
				for _, socket in ipairs(recvt) do
					readlocks[socket] = nil
					if reading[socket] == current then
						reading:remove(socket)                                              --[[VERBOSE]] verbose:threads(current," unsubscribed for read signal")
					else
						local wrapper = recvt[socket]
						readok[#readok+1] = wrapper
						readok[wrapper] = true
					end
				end
			end
			if sendt then
				for _, socket in ipairs(sendt) do
					writelocks[socket] = nil
					if writing[socket] == current then
						writing:remove(socket)                                              --[[VERBOSE]] verbose:threads(current," unsubscribed for write signal")
					else
						local wrapper = sendt[socket]
						writeok[#writeok+1] = wrapper
						writeok[wrapper] = true
					end
				end
			end
		else
			for index, socket in ipairs(readok) do
				local wrapper = recvt[socket]
				readok[index] = wrapper
				readok[socket] = nil
				readok[wrapper] = true
			end
			for index, socket in ipairs(writeok) do
				local wrapper = sendt[socket]
				writeok[index] = wrapper
				writeok[socket] = nil
				writeok[wrapper] = true
			end
		end                                                                         --[[VERBOSE]] verbose:cosocket(false, "returning selected sockets after waiting")
		
		return readok, writeok, errmsg
	else                                                                          --[[VERBOSE]] verbose:cosocket(false, "no sockets for selection")
		return {}, {}
	end
end

function sleep(self, timeout)
	assert(timeout, "bad argument #1 to `sleep' (number expected)")
	return self.scheduler:suspend(timeout)
end

function tcp(self)
	return self:wrap(self.socketapi.tcp())
end

function udp(self)
	return self:wrap(self.socketapi.udp())
end

function connect(self, address, port)
	return self:wrap(self.socketapi.connect(address, port))
end

function bind(self, address, port)
	return self:wrap(self.socketapi.bind(address, port))
end

function wrap(self, socket, ...)                                                --[[VERBOSE]] self.scheduler.verbose:cosocket "new wrapped socket"
	if socket then
		socket:settimeout(0)
		socket = Wrapper {
			__object = socket,
			cosocket = self,
			timeout = false,

			settimeout = wrappedsettimeout,
			connect    = wrappedconnect,
			accept     = wrappedaccept,
			send       = wrappedsend,
			receive    = wrappedreceive,
		}
	end
	return socket, ...
end
