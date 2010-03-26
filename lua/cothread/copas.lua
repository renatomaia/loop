-- Project: CoThread
-- Release: 1.0 beta
-- Title  : Copas API Implemented over CoThread
-- Author : Renato Maia <maia@inf.puc-rio.br>


local coroutine = require "coroutine"
local create = coroutine.create
local yield = coroutine.yield

local cothread = require "cothread"
local run = cothread.run
local now = cothread.now
local round = cothread.round
local schedule = cothread.schedule

local socket = require "cothread.socket"
local waitevent = socket.waitevent
local cosocket = socket.cosocket

module(...)

function addserver(port, handler)
	port = cosocket(port)
	schedule(create(function()
		while true do
			local conn, err = port:accept()
			if conn then
				yield("resume", create(handler), conn)
			else
				break
			end
		end
		port:close()
	end))
end

function addthread(func, ...)
	yield("resume", create(func), ...)
end

function loop(timeout)
	if timeout then
		while timeout > 0 and round() do
			local before = now()
			waitevent(timeout)
			timeout = timeout - (now()-before)
		end
	else
		return run()
	end
end

function step(timeout)
	waitevent(timeout)
	round()
end

function receive(sock, ...)
	return cosocket(sock):receive(...)
end

function send(sock, ...)
	return cosocket(sock):send(...)
end

wrap = cosocket
