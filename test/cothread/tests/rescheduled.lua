return function(checks)
	local Rescheduled = newtask("Rescheduled", function(name)
		for i = 1, 2 do
			local current = running()
			checks:assert(
				yield("schedule", current, "after", current),
				checks.is(current))
			say(name, "suspended")
			yield("suspend")
			say(name, "rescheduled")
		end
	end)
	
	cothread.run(Rescheduled)
	checks:assert(EventLog, checks.similar{
		"Rescheduled started",
		"Rescheduled suspended",
		"Rescheduled rescheduled",
		"Rescheduled suspended",
		"Rescheduled rescheduled",
		"Rescheduled ended",
	})
	
	checkend(checks, cothread)
end
