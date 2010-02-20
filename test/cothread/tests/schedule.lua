return function(checks)
	local Dummies = {}
	for i = 1, 5 do
		local thread = newtask("Dummy"..i, dummybody)
		Dummies[#Dummies+1] = thread
		cothread.schedule(thread)
	end
	
	local Delayed = newtask("Delayed")
	local Future = newtask("Future")
	local Blocked = newtask("Blocked")
	local Unblocker = newtask("Unblocker", function()
		checks:assert(
			yield("notify", "My Signal"),
			checks.is(Blocked))
	end)
	local AfterDummy = newtask("AfterDummy", function()
		checks:assert(
			yield("schedule", Unblocker),
			checks.is(Unblocker))
	end)
	
	checks:assert(
		cothread.schedule(AfterDummy, "after", Dummies[3]),
		checks.is(AfterDummy))
	checks:assert(
		cothread.schedule(Delayed, "delay", 1),
		checks.is(Delayed))
	checks:assert(
		cothread.schedule(Future, "defer", cothread.now()+1),
		checks.is(Future))
	checks:assert(
		cothread.schedule(Blocked, "wait", "My Signal"),
		checks.is(Blocked))
	
	cothread.run()
	checks:assert(EventLog, checks.similar{
		"Dummy1 started",
		"Dummy2 started",
		"Dummy3 started",
		"AfterDummy started",
		"AfterDummy ended",
		"Dummy4 started",
		"Dummy5 started",
		"Dummy1 ended",
		"Dummy2 ended",
		"Dummy3 ended",
		"Unblocker started",
		"Unblocker ended",
		"Dummy4 ended",
		"Dummy5 ended",
		"Blocked started",
		"Blocked ended",
		"Delayed started",
		"Future started",
		"Delayed ended",
		"Future ended",
	})
	
	checkend(checks, cothread)
end
