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

local function notifierbody(group)
	yield() -- finish initialization
	while true do
		if group:deactivate() then
			yield("notify", group)
			yield("yield")
		end
	end
end

local function notifier(group)
	local thread = create(notifierbody)
	resume(thread, group)
	return thread
end


local WeakKeys = class{__mode = "k"}
local timeoutOf = WeakKeys()
local timeKindOf = WeakKeys()
local timerOf = WeakKeys()
local activated = WeakKeys()


local EventGroup = class()

function EventGroup:add(event)
	local thread = self[event]
	if thread == nil then
		thread = notifier(self)
		self[event] = thread
		if activated[self] ~= nil then
			yield("schedule", thread, "wait", event)
		end
		return true
	end
end

function EventGroup:remove(event)
	local thread = self[event]
	if thread ~= nil then
		self[event] = nil
		if activated[self] ~= nil then
			yield("unschedule", thread)
		end
		return true
	end
end

function EventGroup:settimeout(timeout, kind)
	if kind == nil then kind = "delay" end
	if timeout ~= timeoutOf[self] or kind ~= timeKindOf[self] then
		local timer = timerOf[self]
		if timeout ~= nil then
			if timer == nil then
				timer = notifier(self)
				timerOf[self] = timer
			end
			timeoutOf[self] = timeout
			timeKindOf[self] = kind
			if activated[self] ~= nil then
				yield("schedule", timer, kind, timeout)
			end
		elseif timer ~= nil then
			timerOf[self] = nil
			timeoutOf[self] = nil
			timeKindOf[self] = nil
			if activated[self] ~= nil then
				yield("unschedule", timer)
			end
		end
	end
end

function EventGroup:gettimeout()
	return timeoutOf[self], timeKindOf[self]
end

function EventGroup:activate()
	if activated[self] == nil then
		for event, thread in pairs(self) do
			yield("schedule", thread, "wait", event)
		end
		local timer = timerOf[self]
		if timer ~= nil then
			yield("schedule", timer, timerKindOf[self], timeoutOf[self])
		end
		activated[self] = true
		return true
	end
end

function EventGroup:deactivate()
	if activated[self] ~= nil then
		for _, thread in pairs(self) do
			yield("unschedule", thread)
		end
		local timer = timerOf[self]
		if timer ~= nil then
			yield("unschedule", timer)
		end
		activated[self] = nil
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
--		events:settimeout(timeout)
--		events:add(event1)
--		events:add(event2)
--		events:add(event3)
--		events:activate()
--		yield("wait", events)
--	else
--		yield("wait", socket)
--	end
--	return socket:receive()
--end
