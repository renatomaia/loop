-- Project: CoThread
-- Title  : Timer for Triggering of Events at Regular Rates
-- Author : Renato Maia <maia@inf.puc-rio.br>

local coroutine = require "coroutine"
local create = coroutine.create
local resume = coroutine.resume
local yield = coroutine.yield

local oo = require "loop.base"
local class = oo.class
local rawnew = oo.rawnew


local function nextwake(self)
	local started = self.started
	local rate = self.rate
	local now = yield("now")
	local elapsed = (now-started)%rate
	return now+rate-elapsed
end

local function timer(self)
	yield() -- initialization completed
	while true do
		self:action()
		yield("defer", nextwake(self))
	end
end


local Timer = class()

function Timer:__new(...)
	self = rawnew(self, ...)
	if self.thread == nil then
		local thread = create(timer)
		resume(thread, self) -- initializate timer thread
		self.thread = thread
	end
	return self
end

function Timer:enable()
	if self.started == nil then
		self.started = yield("now")
		yield("schedule", self.thread, "defer", nextwake(self))
		return true
	end
end

function Timer:disable()
	if self.started ~= nil then
		self.started = nil
		yield("unschedule", self.thread)
		return true
	end
end

return Timer
