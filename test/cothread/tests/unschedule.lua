return function()
	local Dummies = {}
	for i = 1, 6 do
		local thread = newtask("Dummy"..i)
		Dummies[#Dummies+1] = thread
		cothread.schedule(thread)
	end
	
	local Scheduled = {}
	for i = 1, 2 do
		Scheduled[#Scheduled+1] = cothread.schedule(newtask("AfterDummy"..i), "after", Dummies[3])
		Scheduled[#Scheduled+1] = cothread.schedule(newtask("Delayed"..i), "delay", 1)
		Scheduled[#Scheduled+1] = cothread.schedule(newtask("Blocked"..i), "wait", "My Signal")
	end
	
	for i, dummy in ipairs(Dummies) do
		if i%2==0 then
			assert(cothread.unschedule(Dummies[i]) == Dummies[i])
		end
	end
	for i = 1, #Scheduled/2 do
		assert(cothread.unschedule(Scheduled[i]) == Scheduled[i])
	end
	
	local Unscheduler = newtask("Unscheduler", function()
		for i, thread in ipairs(Dummies) do
			assert(yield("unschedule", thread) == (i%2==1 and thread or nil))
		end
		for i, thread in ipairs(Scheduled) do
			assert(yield("unschedule", thread) == (i>#Scheduled/2 and thread or nil))
		end
	end)
	cothread.schedule(Unscheduler)
	
	resetlog()
	cothread.run()
	checklog{
		"Dummy1 started",
		"Dummy3 started",
		"AfterDummy2 started",
		"Dummy5 started",
		"Unscheduler started",
		"Unscheduler ended",
	}
	checkend(cothread)
end
