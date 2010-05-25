return function(checks, scheduler)
	local timenow = 0
	function scheduler.time() return timenow end
	function scheduler:idle(time) if time then timenow = time end end
	
	for delay = 0, 3 do
		local Sleeper = newtask("Sleeper"..delay, function()
			local start = scheduler.time()
			scheduler:suspend(delay)
			local time = scheduler.time()-start
			checks:assert(time >= delay, "no delay: "..time)
		end)
		checks:assert(scheduler:register(Sleeper), checks.is(Sleeper))
	end

	scheduler:run()
	checks:assert(EventLog, checks.similar{
		"Sleeper0 started",
		"Sleeper1 started",
		"Sleeper2 started",
		"Sleeper3 started",
		"Sleeper0 ended",
		"Sleeper1 ended",
		"Sleeper2 ended",
		"Sleeper3 ended",
	})
	checkend(checks, scheduler)
end
