-- Project: CoThread
-- Title  : Timer for Triggering of Events at Regular Rates
-- Author : Renato Maia <maia@inf.puc-rio.br>

local coroutine = require "coroutine"
local create = coroutine.create
local yield = coroutine.yield

local oo = require "loop.base"
local class = oo.class
local rawnew = oo.rawnew

module(...)


local function timer(self)
	self:action()
	local started = self.started
	if started then
		local rate = self.rate
		local now = yield("now")
		local count = (now-started)%rate
		yield("defer", started+rate*(count+1))
	else
		yield("suspend")
	end
	return timer(self)
end


local Timer = class(_M)

function Timer:__new(...)
	self = rawnew(self, ...)
	self.timer = create(timer)
	return self
end

function Timer:enable()
	if self.started then
		self.started = yield("now")
		yield("resume", self.timer, self)
		return true
	end
end

function Timer:disable()
	if self.started then
		self.started = nil
		yield("unschedule", self.timer)
		return true
	end
end
