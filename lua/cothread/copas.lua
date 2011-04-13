-- Project: CoThread
-- Release: 1.0 beta
-- Title  : Copas API Implemented over CoThread
-- Author : Renato Maia <maia@inf.puc-rio.br>


local _G = require "_G"
local pcall = _G.pcall
local print = _G.print
local setmetatable = _G.setmetatable

local coroutine = require "coroutine"
local create = coroutine.create
local running = coroutine.running
local yield = coroutine.yield

local cothread = require "cothread"
local run = cothread.run
local step = cothread.step
local schedule = cothread.schedule
local unschedule = cothread.unschedule

local socket = require "cothread.socket"
local cosocket = socket.cosocket

local Dummy = create(function() end)
local Halter = create(function() yield("requesthalt") end)
local Handlers = setmetatable({}, {__mode="k"})
local SocketOf = setmetatable({}, {__mode="k"})

cothread.loadplugin(require "cothread.plugin.sleep")
cothread.loadplugin(require "cothread.plugin.socket")

local function dummy() end
local function wrap(socket)
	socket = cosocket(socket)
	socket.flush = dummy
	return socket
end
local function endthread(thread, success, errmsg)
	local socket = SocketOf[thread]
	if success then
		socket:close()
	else
		local handler = Handlers[thread] or print
		if handler ~= nil then
			handler(errmsg, thread, socket)
		end
	end
end

return {
	addserver = function(port, handler, timeout)
		port = cosocket(port)
		if timeout ~= nil then port:settimeout(timeout) end
		schedule(create(function()
			while true do
				local conn, err = port:accept()
				if conn ~= nil then
					if timeout ~= nil then conn:settimeout(timeout) end -- is this right?
					local thread = create(handler)
					SocketOf[thread] = conn
					cothread.traps[thread] = endthread
					yield("last", thread, conn)
				else
					port:close()
					return
				end
			end
		end))
	end,
	
	addthread = function(func, ...)
		local thread = create(func)
		local current, main = running()
		if current ~= nil and not main and yield("running") == current then
			yield("next", thread, nil, ...)
		else
			step(thread, nil, ...)
		end
	end,
	
	loop = function(timeout)
		if timeout ~= nil then
			schedule(Halter, "delay", timeout)
		end
		run()
		while timeout == nil do end -- is this a bug or a feature?
	end,
	
	step = function(timeout)
		if timeout ~= nil then
			schedule(Dummy, "delay", timeout)
		end
		step()
		unschedule(Dummy)
	end,
	
	setErrorHandler = function(func)
		local current, main = running()
		if current ~= nil and not main then
			Handlers[current] = func
		end
	end,
	
	flush = function() end,
	
	receive = function(sock, ...)
		return wrap(sock):receive(...)
	end,
	
	send = function(sock, ...)
		return wrap(sock):send(...)
	end,
	
	connect = function(sock, ...)
		return wrap(sock):connect(...)
	end,
	
	wrap = wrap,
}
