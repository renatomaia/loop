local _G        = require "_G"
local coroutine = require "coroutine"
local oo        = require "loop.base"

module("loop.thread.EventGroup", oo.class)

-- Internal --------------------------------------------------------------------

local ipairs    = _G.ipairs
local newthread = coroutine.create
local yield     = coroutine.yield
local resume    = coroutine.resume

local function notifier(self, scheduler, op, event)
	local token = yield() -- value that indicates whether the thread was resumed
	repeat                -- by an activation (ResetToken) or an event.
		-- suspend waiting for the event and pass the token to the next thread
		token = scheduler[op](scheduler, event, token)
		if token ~= ResetToken then -- resumed by a triggering event
			token = scheduler:notifyall(self, event)
		end
	until #self == 0
end

-- Members ---------------------------------------------------------------------

function __init(self, ...)
	self = oo.rawnew(self, ...)
	local scheduler = self.scheduler
	for index, event in ipairs(self) do
		local thread = newthread(notifier)
		resume(thread, self, scheduler, "wait", event)
		self[index] = thread
	end
	local timeout = self.timeout
	if timeout then
		local thread = newthread(notifier)
		resume(thread, self, scheduler, "suspend", event)
		self[#self+1] = thread
	end
	return self
end

function activate(self)
	if not self.active then
		local scheduler = self.scheduler
		local scheduled = scheduler.scheduled
		-- register all threads in a chain after the currently scheduled thread
		for _, thread in ipairs(self) do
			scheduler:register(thread, scheduled)
		end
		self.active = true
		-- resume all registered threads yielding the token that reset their state
		yield(ResetToken)
	end
end

function deactivate(self, notify)
	if self.active then
		local scheduler = self.scheduler
		-- cancel all event notifiers
		for _, thread in ipairs(self) do
			scheduler:remove(thread)
		end
		self.active = nil
		if notify == nil then
			-- cancel threads waiting for the events
			return scheduler:cancel(self)
		else
			-- notify threads waiting for the events, passing the notification
			return scheduler:notifyall(self, notify)
		end
	end
end

--------------------------------------------------------------------------------
-- Sample Usage ----------------------------------------------------------------
--------------------------------------------------------------------------------

--local EventGroup = require "loop.thread.EventGroup"
--
--function receive(socket, timeout)
--	if timeout then
--		local events = EventGroup{ socket, timeout, scheduler = scheduler }
--		events:activate()
--		if scheduler:wait(events) == timeout then
--			return nil, "timeout" -- TODO:[maia] shouldn't decativate the group before returning?
--		end
--		events:deactivate()
--	else
--		scheduler:wait(socket)
--	end
--	local result, partial = socket:receive(0)
--	return result or partial
--end
