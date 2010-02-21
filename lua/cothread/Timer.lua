-- Project: CoThread
-- Release: 1.0 beta
-- Title  : Timer for Triggering of Events at Regular Rates
-- Author : Renato Maia <maia@inf.puc-rio.br>


local coroutine = require "coroutine"
local create = coroutine.create
local yield = coroutine.yield

local oo = require "loop.base"
local class = oo.class
local rawnew = oo.rawnew

module(..., class)

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



function __init(self, ...)
	self = rawnew(self, ...)
	self.timer = create(timer)
	return self
end

function enable(self)
	if self.started then
		self.started = yield("now")
		yield("resume", self.timer, self)
		return true
	end
end

function disable(self)
	if self.started then
		self.started = nil
		yield("unschedule", self.timer)
		return true
	end
end
