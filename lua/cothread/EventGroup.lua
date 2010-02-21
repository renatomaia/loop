-- Project: CoThread
-- Release: 1.0 beta
-- Title  : Object Used to Wait for Multiple Signals or a Timeout
-- Author : Renato Maia <maia@inf.puc-rio.br>

local _G = require "_G"
local ipairs = _G.ipairs

local coroutine = require "coroutine"
local newthread = coroutine.create
local yield = coroutine.yield
local resume = coroutine.resume

local tabop = require "loop.table"
local memoize = tabop.memoize

local oo = require "loop.base"
local class = oo.class

module(..., class)

local function activate(self)
	if not self.active then
		for index, event in ipairs(self) do
			yield("schedule", thread, "wait", event)
		end
		local timer = self.timer
		if timer then
			yield("schedule", timer, "delay", self.timeout)
		end
		self.active = true
	end
end

local function deactivate(self)
	self.active = false
	for _, thread in ipairs(self) do
		yield("unschedule", thread)
	end
end

local function notifierbody(group, event, ...)
	yield() -- initialization finished
	while true do
		deactivate(group)
		yield("notifyall", group, "after")
		yield("suspend", event, ...)
	end
end

local function notifier(group, ...)
	thread = newthread(notifierbody)
	resume(thread, group, ...)
	return thread
end



function __init(self, group, ...)
	self = oo.rawnew(self, group, ...)
	for index, event in ipairs(self) do
		self[index] = notifier(self, event, ...)
	end
	local timeout = self.timeout
	if timeout then
		self.timer = notifier(self, nil, ...)
	end
	return self
end

function wait(self, ...)
	if not self.active then activate(self) end
	yield("pause", yield("wait", self, ...)) -- pass values received to the next thread
	return event
end

function notifyall(self, ...)
	if self.active then deactivate(self) end
	return yield("notifyall", self, ...)
end

function cancelall(self, ...)
	if self.active then deactivate(self) end
	return yield("cancelall", self, ...)
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
