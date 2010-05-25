local oo = require "loop.cached"
local Suite = require "loop.test.Suite"
local Fixture = require "loop.test.Fixture"

Fixture = oo.class({}, Fixture)

function Fixture:setup()
	local Scheduler = require "loop.thread.Scheduler"
	                  require "loop.tests.library.Scheduler.utils"
	local test = self.test
	local instances = {
		Scheduler(),
		Scheduler,
		Scheduler(),
	}
	for index, scheduler in ipairs(instances) do
		self[#self+1] = function(checks)
			test(checks, scheduler)
		end
	end
	for index, scheduler in ipairs(instances) do
		self[#self+1] = function(checks)
			assert(coroutine.resume(coroutine.create(test), checks, scheduler))
		end
	end
end

function Fixture:teardown()
	for index in ipairs(self) do
		self[index] = nil
	end
	resetlog()
end

local function new(name)
	return Fixture{ test = require("loop.tests.library.Scheduler."..name) }
end

return Suite{
	register = new("register"),
	remove = new("remove"),
	resume = new("resume"),
	suspend = new("suspend"),
}
