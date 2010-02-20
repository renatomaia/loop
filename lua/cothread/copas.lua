--------------------------------------------------------------------------------
-- Project: LuaCooperative                                                    --
-- Release: 2.0 beta                                                          --
-- Title  :                                                                   --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------

local coroutine = require "coroutine"
local create = coroutine.create
local yield = coroutine.yield

local cothread = require "cothread"
local run = cothread.run
local now = cothread.now
local step = cothread.step
local schedule = cothread.schedule

local socket = require "cothread.socket"
local waitevent = socket.waitevent
local cosocket = socket.cosocket

module(...)

function addserver(port, handler)
	port = cosocket(port)
	cothread.schedule(create(function()
		repeat
			local conn, err = port:accept()
			if conn then
				yield("resume", create(handler), conn)
			end
		until conn == nil
		port:close()
	end))
end

function addthread(func, ...)
	yield("resume", create(func), ...)
end

function loop(timeout)
	if timeout then
		while step() and timeout > 0 do
			local before = now()
			waitevent(timeout)
			timeout = timeout - (now()-before)
		end
	else
		return run()
	end
end

function step(timeout)
	waitevent(now()+timeout)
	step()
end

function receive(sock, ...)
	return cosocket(sock):receive(...)
end

function send(sock, ...)
	return cosocket(sock):send(...)
end

wrap = cosocket
