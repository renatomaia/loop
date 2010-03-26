-- Project: CoThread
-- Title  : Object Used to Wait for Multiple Signals or a Timeout
-- Author : Renato Maia <maia@inf.puc-rio.br>

local _G = require "_G"
local ipairs = _G.ipairs

local coroutine = require "coroutine"
local create = coroutine.create
local yield = coroutine.yield
local resume = coroutine.resume
local running = coroutine.running

local tabop = require "loop.table"
local memoize = tabop.memoize

local oo = require "loop.base"
local class = oo.class
local rawnew = oo.rawnew

module(...)


local function activate(self)
	local threads = self.threads
	for index, thread in ipairs(threads) do
		yield("schedule", thread, "wait", self[index])
	end
	local timer = threads.timer
	if timer then
		yield("schedule", timer, "delay", self.timeout)
	end
	self.active = true
end

local function deactivate(self)
	for _, thread in ipairs(self.threads) do
		yield("unschedule", thread)
	end
	self.active = false
end

local function notifierbody(group, event, ...)
	yield() -- initialization finished
	while true do
		yield("wakeall", group, "after", running())
		deactivate(group)
		yield("suspend", event, ...)
	end
end

local function notifier(group, ...)
	local thread = create(notifierbody)
	resume(thread, group, ...)
	return thread
end


local EventGroup = class(_M)

function EventGroup:__new(group, ...)
	self = rawnew(self, group)
	local threads = {}
	for index, event in ipairs(self) do
		threads[index] = notifier(self, event, ...)
	end
	local timeout = self.timeout
	if timeout then
		threads.timer = notifier(self, nil, ...)
	end
	self.threads = threads
	return self
end

function EventGroup:wait(...)
	if not self.active then activate(self) end
	yield("pause", yield("wait", self, ...)) -- pass values to the next thread
	return event
end

function EventGroup:wakeall(...)
	if self.active then deactivate(self) end
	return yield("wakeall", self, ...)
end

function EventGroup:cancel(...)
	local thread = yield("cancel", self)
	if self.active and not yield("isscheduled", self) then
		deactivate(self)
	end
	return thread
end

--------------------------------------------------------------------------------
-- Sample Usage ----------------------------------------------------------------
--------------------------------------------------------------------------------

--local EventGroup = require "cothread.EventGroup"
--
--function receive(socket, timeout)
--	if timeout then
--		local events = EventGroup{ socket, timeout=timeout }
--		if events:wait() ~= socket then
--			return nil, "timeout"
--		end
--	else
--		yield("wait", socket)
--	end
--	return socket:receive()
--end
