-- Project: CoThread
-- Title  : Object Used to Wait for Multiple Signals or a Timeout
-- Author : Renato Maia <maia@inf.puc-rio.br>

local _G = require "_G"
local pairs = _G.pairs

local coroutine = require "coroutine"
local create = coroutine.create
local yield = coroutine.yield
local resume = coroutine.resume
local running = coroutine.running

local oo = require "loop.base"
local class = oo.class
local rawnew = oo.rawnew

local function eventbody(self, event, ...)
	yield() -- initialization finished
	while true do
		yield("wakeall", self, "after", running())
		yield("wait", event, event, ...)
	end
end

local function timerbody(self, ...)
	yield() -- initialization finished
	while true do
		yield("wakeall", self, "after", running())
		yield("pause", nil, ...) -- from now on it is triggered as soon as possible
	end
end

local function notifier(group, body, ...)
	local thread = create(body)
	resume(thread, group, ...)
	return thread
end


local WeakKeys = class{__mode = "k"}
local timeoutOf = WeakKeys()
local timerOf = WeakKeys()


local EventGroup = class()

function EventGroup:add(event, ...)
	local thread = self[event]
	if not thread then
		thread = notifier(self, eventbody, event, ...)
		self[event] = thread
		return yield("schedule", thread, "wait", event) ~= nil
	end
end

function EventGroup:remove(event)
	local thread = self[event]
	if not thread then
		self[event] = nil
		return yield("unschedule", thread) ~= nil
	end
end

function EventGroup:settimeout(timeout, ...)
	if timeout ~= timeoutOf[self] then
		local timer = timerOf[self]
		if timeout then
			timeoutOf[self] = timeout
			if not timer then
				timer = notifier(self, timerbody, ...)
				timerOf[self] = timer
			end
			return yield("schedule", timer, "defer", timeout) ~= nil
		elseif timer then
			timeoutOf[self] = nil
			timerOf[self] = nil
			return yield("unschedule", timer) ~= nil
		end
	end
end

function EventGroup:gettimeout()
	return timeoutOf[self]
end


local function waitcont(...)
	yield("pause", ...) -- pass values to the next thread
	return ...
end
function EventGroup:wait(...)
	return waitcont(yield("wait", self, ...))
end

function EventGroup:wakeall(...)
	return yield("wakeall", self, ...)
end

function EventGroup:cancel()
	return yield("cancel", self)
end

function EventGroup:iterate()
	return pairs(self)
end

return EventGroup

--------------------------------------------------------------------------------
-- Sample Usage ----------------------------------------------------------------
--------------------------------------------------------------------------------

--local EventGroup = require "cothread.EventGroup"
--
--function receive(socket, timeout)
--	if timeout then
--		local events = EventGroup()
--		events:settimeout(timeout)
--		events:add(socket)
--		local timeout
--		timeout = (events:wait() == nil)
--		for event in events:iterate() do
--			events:remove(event)
--		end
--		events:settimeout(nil)
--		if timeout then return nil, "timeout" end
--	else
--		yield("wait", socket)
--	end
--	return socket:receive()
--end
