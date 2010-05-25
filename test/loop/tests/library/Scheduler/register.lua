return function(checks, scheduler)
	local Dummies = {}
	for i = 1, 5 do
		local thread = newtask("Dummy"..i, dummybody)
		Dummies[#Dummies+1] = thread
		checks:assert(scheduler:register(thread), checks.is(thread))
	end
	
	local Middle = newtask("Middle", function() end)
	checks:assert(scheduler:register(Middle, Dummies[3]), checks.is(Middle))
	
	scheduler:run()
	checks:assert(EventLog, checks.similar{
		"Dummy1 started",
		"Dummy2 started",
		"Dummy3 started",
		"Middle started",
		"Middle ended",
		"Dummy4 started",
		"Dummy5 started",
		"Dummy1 ended",
		"Dummy2 ended",
		"Dummy3 ended",
	})
	
	checkend(checks, scheduler)
end
