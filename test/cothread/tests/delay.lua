local socket = require("socket")
local now = socket.gettime
local sleep = socket.sleep

return function(checks)
	cothread.now = now
	cothread.idle = function(time) sleep(time-now()) end
	
	local delay = 1
	
	local Sleeper = newtask("Sleeper", function()
		local start = now()
		yield("delay", delay)
		local time = now()-start
		checks:assert(time > delay, "no delay: "..time)
	end)
	
	local start
	local Delayed = newtask("Delayed", function()
		local time = now()-start
		checks:assert(time > delay, "no delay: "..time)
		yield("yield", Sleeper)
	end)
	
	checks:assert(cothread.schedule(Delayed, "delay", delay), checks.is(Delayed))

	start = now()
	cothread.run()
	checks:assert(EventLog, checks.similar{
		"Delayed started",
		"Sleeper started",
		"Sleeper ended",
	})
	
	checkend(checks, cothread)
end
