local socket = require("socket")
local now = socket.gettime
local sleep = socket.sleep

return function()
	cothread.now = now
	cothread.idle = function(time) sleep(time-now()) end
	
	local delay = 1
	
	local Sleeper = newtask("Sleeper", function()
		local start = now()
		yield("delay", delay)
		local time = now()-start
		assert(time > delay, "no delay: "..time)
	end)
	
	local start
	local Delayed = newtask("Delayed", function()
		local time = now()-start
		assert(time > delay, "no delay: "..time)
		yield("yield", Sleeper)
	end)
	
	assert(cothread.schedule(Delayed, "delay", delay) == Delayed)

	start = now()
	cothread.run()
	checklog{
		"Delayed started",
		"Sleeper started",
		"Sleeper ended",
	}
	
	checkend(cothread)
end
