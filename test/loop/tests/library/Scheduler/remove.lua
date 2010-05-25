return function(checks, scheduler)
	local Dummies = {}
	for i = 1, 6 do
		local thread = newtask("Dummy"..i)
		Dummies[#Dummies+1] = thread
		scheduler:register(thread)
	end
	
	for i, dummy in ipairs(Dummies) do
		if i%2==0 then
			checks:assert(
				scheduler:remove(Dummies[i]),
				checks.is(Dummies[i]))
		end
	end
	
	local Unscheduler = newtask("Unscheduler", function()
		for i, thread in ipairs(Dummies) do
			checks:assert(
				scheduler:remove(thread),
				checks.is((i%2==1) and thread or nil))
		end
	end)
	scheduler:register(Unscheduler)
	
	resetlog()
	scheduler:run()
	checks:assert(EventLog, checks.similar{
		"Dummy1 started",
		"Dummy3 started",
		"Dummy5 started",
		"Unscheduler started",
		"Unscheduler ended",
	})
	
	checkend(checks, scheduler)
end
