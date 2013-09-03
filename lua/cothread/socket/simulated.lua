
local _G = require "_G"
local assert = _G.assert
local error = _G.error
local getmetatable = _G.getmetatable
local ipairs = _G.ipairs
local pairs = _G.pairs
local type = _G.type

local math = require "math"
local inf = math.huge
local min = math.min

local array = require "table"
local concat = array.concat
local unpack = array.unpack or _G.unpack

local table = require "loop.table"
local memoize = table.memoize

local oo = require "loop.base"
local class = oo.class
local rawnew = oo.rawnew

--------------------------------------------------------------------------------

local now = 0
local ip2name = {}
local name2ip = {}
local peers = memoize(function() return {} end)

--------------------------------------------------------------------------------

local ReadStream = class{
	event = 1,
	consumed = 0,
	stats = 0,
}

function ReadStream:__new(...)
	self = rawnew(self, ...)
	self.buffer = self.buffer or {}
	return self
end

function ReadStream:addbuffer(data)
	local buffer = self.buffer
	buffer[#buffer+1] = data
end

function ReadStream:getbuffer()
	local buffer = self.buffer
	self.buffer = {}
	return concat(buffer)
end

function ReadStream:next()
	local event = self[self.event]
	if type(event) == "string" then
		self.stats = self.stats + #event
	end
	self.event = self.event+1
	self.consumed = nil
end

function ReadStream:getstats()
	return self.stats + self.consumed
end

function ReadStream:setstats(stats)
	self.stats = stats - self.consumed
end

function ReadStream:ready()
	if not self.closed then
		local event = self[self.event]
		if event == nil then
			return inf
		elseif event == false then
			self.closed = true
		elseif type(event) == "number" then
			if event <= now then
				self:next()
				return self:ready()
			else
				return event
			end
		end
	end
	return now
end

function ReadStream:receive(required, timeout)
	if self.closed then return nil, "closed" end
	local data = self[self.event]
	if data == nil then
		if timeout then
			return nil, "timeout", self:getbuffer()
		else
			error("application would hang forever")
		end
	elseif data == false then
		self.closed = true
		if required == "*a" then
			return self:getbuffer()
		else
			return nil, "closed", self:getbuffer()
		end
	end
	local kind = type(data)
	if kind == "string" then
		local consumed = self.consumed
		if required == nil or required == "*l" then
			local found = data:find("\n", consumed+1, true)
			if found then
				self.consumed = found
				self:addbuffer(data:sub(consumed+1, found-1))
				return self:getbuffer()
			end
		elseif type(required) == "number" then
			local available = #data - consumed
			if required <= available then
				if required == available then
					self:next()
					self:addbuffer(data:sub(consumed+1))
				else -- required < available
					self.consumed = consumed+required
					self:addbuffer(data:sub(consumed+1, self.consumed))
				end
				return self:getbuffer()
			end
			required = required-available
		end
		self:addbuffer(data:sub(consumed+1))
	elseif data > now then
		if timeout and data > timeout then
			return nil, "timeout", self:getbuffer()
		end
		now = data
	end
	self:next()
	return self:receive(required, timeout)
end

--------------------------------------------------------------------------------

local WriteStream = class{
	event = ReadStream.event,
	ready = ReadStream.ready,
	stats = ReadStream.stats,
}

function WriteStream:next()
	local event = self[self.event]
	if type(event) == "string" then
		self.stats = self.stats + #event
	end
	self.event = self.event+1
	self.available = nil
end

function WriteStream:getstats()
	return self.stats + #(self[self.event]) - (self.available or 0)
end

function WriteStream:setstats(stats)
	self.stats = stats - (#(self[self.event]) - (self.available or 0))
end

function WriteStream:send(data, i, j, timeout)
	if self.closed then return nil, "closed" end
	i = i or 1
	j = j or #data
	local space = self[self.event]
	if space == nil then
		error("application would hang forever")
	elseif space == false then
		self.closed = true
		return nil, "closed", i-1
	end
	local kind = type(space)
	if kind == "string" then
		local available = self.available or #space
		local required = 1+j-i
		if required <= available then
			if required == available then
				self:next()
			elseif required < available then
				self.available = available-required
			end
			return j
		end
		i = i+available
	elseif space > now then
		if timeout and space > timeout then
			return nil, "timeout", i-1
		end
		now = space
	end
	self:next()
	return self:send(data, i, j, timeout)
end

--------------------------------------------------------------------------------

local class2op = {
	client = "connects",
	server = "accepts",
}

local Socket = class{
	class = "master",
	ip = "0.0.0.0",
	port = 0,
}

function Socket:ready()
	local peer = self.peer
	if peer == nil then return nil end
	local op = class2op[self.class]
	if op == nil then return nil end
	local list = peer[op]
	
	local nextpos = list.nextpos or 1
	local current = list[nextpos]
	if current == nil then return inf end
	if current == false or current.timestamp == nil then return now end
	return current.timestamp
end

function Socket:getnextconn()
	local peer = self.peer
	if peer == nil then return nil end
	local op = class2op[self.class]
	if op == nil then return nil end
	local list = peer[op]
	
	local nextpos = list.nextpos or 1
	local current = list[nextpos]
	local timeout = self.timeout
	if current == nil then
		if timeout then
			now = now+timeout
			return nil, "timeout"
		end
		error("application would hang forever")
	elseif current == false then
		return nil, "closed"
	end
	local arrival = current.timestamp
	if arrival then
		if timeout then
			if arrival > now+timeout then
				return nil, "timeout"
			end
		end
		now = arrival
	end
	list.nextpos = nextpos+1
	self.read = ReadStream(current.read)
	self.write = WriteStream(current.write)
	return 1
end

--------------------------------------------------------------------------------

local connections = memoize(function(userdata)
	return Socket{ birth = now }
end, "k")

local function getinfo(self, op, class)
	local info = connections[self]
	if info.class ~= class then
		error("calling '"..op.."' on bad self (tcp{"..class.."} expected, got userdata)")
	end
	return info
end

--------------------------------------------------------------------------------

local TCP = class()

function TCP:setoption(option, value)
	return 1
end
function TCP:settimeout(value)
	local info = connections[self]
	if not value or value < 0 or value == inf then
		info.timeout = nil
	else
		info.timeout = value
	end
end
function TCP:getpeername()
	local peer = connections[self].peer
	if peer == nil then return nil, "getpeername failed" end
	return peer.ip, peer.port
end
function TCP:getsockname()
	local info = connections[self]
	return info.ip, info.port
end
function TCP:setpeername(address, port)
	local peer = connections[self].peer
	server.hostname, server.port = address, port
end
function TCP:setsockname(address, port)
	local info = connections[self]
	info.hostname, info.port = address, port
end
function TCP:close()
	local info = connections[self]
	local closed = info.closed
	if not closed then
		info.closed = true
		info.read.closed = true
		info.write.closed = true
		return 1
	end
	return nil, "already closed"
end

function TCP:receive(pattern, prefix)
	local info = connections[self]
	local timeout = info.timeout
	if timeout then timeout = now+timeout end
	if prefix then
		info.read.buffer[1] = prefix
		if type(pattern) == "number" then
			pattern = pattern - #prefix
			if pattern <= 0 then return prefix end
		end
	end
	return info.read:receive(pattern, timeout)
end
function TCP:send(data, i, j)
	local info = connections[self]
	local timeout = info.timeout
	if timeout then timeout = now+timeout end
	return info.write:send(data, i, j, timeout)
end

function TCP:getstats()
	local info = connections[self]
	return info.read:getstats(), info.write:getstats(), now-info.birth
end
function TCP:setstats(received, sent, age)
	local info = connections[self]
	info.read:setstats(received)
	info.write:setstats(sent)
	info.birth = now-age
end

function TCP:bind(address, port)
	local info = getinfo(self, "bind", "master")
	local peer = peers[port][address]
	if peer == nil then return nil, "host not found" end
	if info.peer ~= nil then return nil, "Invalid argument" end
	info.hostname = address
	info.port = port
	info.peer = peer
	return 1
end
function TCP:connect(address, port)
	local info = getinfo(self, "connect", "master")
	local peer = peers[port][address]
	if peer == nil then return nil, "host not found" end
	info.class = "client"
	info.peer = peer
	return info:getnextconn()
end
function TCP:listen(backlog)
	local info = getinfo(self, "listen", "master")
	info.class = "server"
	if info.port == 0 then
		port = #peers
		peers[port] = false
		info.port = port
	end
	return 1
end
function TCP:accept()
	local info = getinfo(self, "accept", "server")
	local sock = TCP()
	local sinf = connections[sock]
	sinf.class = "server"
	sinf.peer = info.peer
	sinf.timeout = info.timeout
	local ok, errmsg = sinf:getnextconn()
	if ok then
		sinf.class = "client"
		sinf.timeout = nil
		ok = sock
	end
	return ok, errmsg
end

local validmodes = {send=true,receive=true,both=true}
function TCP:shutdown(mode)
	local info = getinfo(self, "shutdown", "client")
	assert(validmodes[mode] ~= nil,
		"bad argument #1 to 'shutdown' (invalid shutdown method)")
	if mode ~= "send" then
		info.read.closed = true
	end
	if mode ~= "receive" then
		info.write.closed = true
	end
	return 1
end

function TCP:dirty() error("unsupported") end
function TCP:getfd() error("unsupported") end
function TCP:setfd() error("unsupported") end

--------------------------------------------------------------------------------

local UDP = class()

function UDP:receive(size) end
function UDP:receivefrom(size) end
function UDP:send(datagram) end
function UDP:sendto(datagram) end

--------------------------------------------------------------------------------

local function addhost(info)
	assert(info.ip, "missing server IP address")
	assert(info.hostname, "missing server hostname")
	assert(info.port, "missing server port number")
	info.alias = info.alias or {}
	info.moreips = info.moreips or {}
	ip2name[info.ip] = info.hostname
	name2ip[info.hostname] = {
		info.ip, {
			name = info.hostname,
			alias = info.alias,
			ip = { info.ip, unpack(info.moreips) },
		},
	}
	info.accepts  = info.accepts  or {}
	info.connects = info.connects or {}
	for id, connections in pairs{accepts=info.accepts,connects=info.connects} do
		if type(connections) == "number" then
			local list = {}
			for i = 1, connections do
				list[#list+1] = {
					ip = "127.0.0.1",
					port = 5000+i,
					server = info,
				}
			end
			info[id] = list
		else
			for i, conn in ipairs(connections) do
				if conn then
					assert(conn.ip, "missing IP address of connection "..i)
					assert(conn.port, "missing port number of connection"..i)
					conn.server = info
				end
			end
		end
	end
	local peersatport = peers[info.port]
	peersatport[info.ip] = info
	peersatport[info.hostname] = info
	for _, list in ipairs{info.alias, info.moreips} do
		for _, address in ipairs(list) do
			peersatport[address] = info
		end
	end
end

local function protect_cont(ok, err, ...)
	if not ok then
		if type(err) ~= "table" then
			error(err)
		end
		return nil, err[1]
	end
	return err, ...
end

return {
	addhost = addhost,
	
	gettime = function()
		return now
	end,
	sleep = function(time)
		now = now+time
	end,
	
	dns = {
		gethostname = function()
			return hostname
		end,
		tohostname = function(address)
			local name = ip2name[address]
			if not name then return nil, "host not found" end
			return name
		end,
		toip = function(address)
			local info = name2ip[address]
			if not info then return nil, "host not found" end
			return unpack(info)
		end,
	},
	
	udp = function()
		error("Oops! Not supported yet!")
		return UDP()
	end,
	tcp = function()
		return TCP()
	end,

	select = function(recv, send, timeout)
		if timeout == nil or timeout < 0 then
			timeout = inf
		else
			timeout = now+timeout
		end
		for op, list in pairs{read=recv, write=send} do
			for _, sock in ipairs(list) do
				local info = connections[sock]
				info = info[op] or info
				local when = info:ready()
				timeout = min(timeout, when)
			end
		end
		if timeout == inf then
			error("application would hang forever")
		end
		now = timeout
		local result = {
			read = {},
			write = {},
			error = "timeout",
		}
		for op, list in pairs{read=recv, write=send} do
			for _, sock in ipairs(list) do
				local info = connections[sock]
				info = info[op] or info
				if info:ready() <= timeout then
					result.error = nil
					local ok = result[op]
					ok[#ok+1] = sock
					ok[sock] = true
					-- connects sockets waiting for connection completion
					if info.class == "client" and info.read == nil then
						assert(info:getnextconn(),
							"oops! ready socket could not be connected")
					end
				end
			end
		end
		return result.read, result.write, result.error
	end,
	
	skip = nil,
	
	protect = function(func)
		return function(...)
			return protect_cont(pcall(func, ...))
		end
	end,
	newtry = function(handler)
		return function(ok, ...)
			if not ok then
				pcall(handler)
				error{(...)}
			end
			return ok, ...
		end
	end,
	
	_DEBUG = true,
}
