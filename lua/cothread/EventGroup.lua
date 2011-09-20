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

local tabop = require "loop.memoize"
local memoize = tabop.memoize

local oo = require "loop.base"
local class = oo.class
local rawnew = oo.rawnew

local function timerbody(self)
	yield() -- finish initialization
	while true do
		self:disable()
		yield("notify", self)
		yield("suspend")
	end
end

local function notifierbody(self, ...)
	yield() -- finish initialization
	while true do
		yield("notify", self)
		yield(...)
	end
end

local function newthread(body, ...)
	local thread = create(body)
	resume(thread, ...) -- initialization
	return thread
end


local enabled = setmetatable({}, {__mode = "k"})
local timerOf = memoize(function(self)
	return newthread(timerbody, self)
end, "k")


local EventGroup = class()

function EventGroup:add(event)
	local thread = self[event]
	if thread == nil then
		thread = newthread(notifierbody, self, "wait", event)
		self[event] = thread
		if enabled[self] ~= nil then
			yield("schedule", thread, "wait", event)
		end
		return true
	end
end

function EventGroup:remove(event)
	local thread = self[event]
	if thread ~= nil then
		self[event] = nil
		if enabled[self] ~= nil then
			yield("unschedule", thread)
		end
		return true
	end
end

function EventGroup:enable(timeout)
	if enabled[self] == nil then
		for event, thread in pairs(self) do
			yield("schedule", thread, "wait", event)
		end
		if timeout == nil then
			enabled[self] = true
		else
			local timer = timerOf[self]
			yield("schedule", timer, "defer", timeout)
			enabled[self] = timer
		end
		return true
	end
end

function EventGroup:disable()
	local timer = enabled[self]
	if timer ~= nil then
		for _, thread in pairs(self) do
			yield("unschedule", thread)
		end
		if timer ~= true then
			yield("unschedule", timer)
		end
		enabled[self] = nil
		return true
	end
end

return EventGroup

--------------------------------------------------------------------------------
-- Sample Usage ----------------------------------------------------------------
--------------------------------------------------------------------------------

--local EventGroup = require "cothread.EventGroup"
--
--function receive(socket, timeout)
--	if timeout ~= nil then
--		local events = EventGroup()
--		events:add(socket)
--		events:enable(yield("now")+timeout)
--		yield("wait", events)
--		events:disable() -- if this evaluates to 'false', there was a timeout.
--	else
--		yield("wait", socket)
--	end
--	return socket:receive()
--end
