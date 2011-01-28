return function()
	local Dummies = {}
	for i = 1, 5 do
		local thread = newtask("Dummy"..i)
		Dummies[#Dummies+1] = thread
		cothread.schedule(thread)
	end
	
	local Delayed = newtask("Delayed")
	local Future = newtask("Future")
	local Blocked = newtask("Blocked")
	local Unblocker = newtask("Unblocker", function()
		assert(yield("cancel", "My Signal") == Blocked)
		assert(yield("schedule", Blocked) == Blocked)
	end)
	local AfterDummy = newtask("AfterDummy", function()
		assert(yield("schedule", Unblocker) == Unblocker)
	end)
	
	assert(cothread.schedule(AfterDummy, "after", Dummies[3]) == AfterDummy)
	assert(cothread.schedule(Delayed, "delay", 1) == Delayed)
	assert(cothread.schedule(Future, "defer", cothread.now()+1) == Future)
	assert(cothread.schedule(Blocked, "wait", "My Signal") == Blocked)
	
	cothread.run()
	checklog{
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
	}
	checkend(cothread)
end
