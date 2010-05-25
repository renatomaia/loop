return function(checks, scheduler)
	scheduler:register(newtask("Resumer", function(name)
		scheduler:resume(newtask("By"..name))
	end))
	scheduler:register(newtask("Removed", function(name)
		checks:assert(scheduler:remove(scheduler.current),
		              checks.is(scheduler.current))
		scheduler:resume(newtask("By"..name))
	end))
	scheduler:run()
	checks:assert(EventLog, checks.similar{
		"Resumer started",
		"ByResumer started",
		"Removed started",
		"ByRemoved started",
		"Resumer ended",
		"ByResumer ended",
		"ByRemoved ended",
	})
	checkend(checks, scheduler)
end
