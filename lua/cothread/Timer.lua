-- Project: CoThread
-- Title  : Timer for Triggering of Events at Regular Rates
-- Author : Renato Maia <maia@inf.puc-rio.br>

local coroutine = require "coroutine"
local create = coroutine.create
local yield = coroutine.yield

local oo = require "loop.base"
local class = oo.class
local rawnew = oo.rawnew


local function timer(self)
	while true do
		self:action()
		local started = self.started
		if started then
			local rate = self.rate
			local now = yield("now")
			local elapsed = (now-started)%rate
			yield("defer", now+rate-elapsed)
		else
			yield("suspend")
		end
	end
end


local Timer = class()

function Timer:__new(...)
	self = rawnew(self, ...)
	self.thread = create(timer)
	return self
end

function Timer:enable()
	if not self.started then
		self.started = yield("now")
		yield("resume", self.thread, self)
		return true
	end
end

function Timer:disable()
	if self.started then
		self.started = nil
		yield("unschedule", self.thread)
		return true
	end
end

return Timer
