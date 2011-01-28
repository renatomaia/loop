return function()
	local Rescheduled = newtask("Rescheduled", function(name)
		for i = 1, 2 do
			local current = running()
			assert(yield("schedule", current, "after", current) == current)
			say(name, "suspended")
			yield("suspend")
			say(name, "rescheduled")
		end
	end)
	
	cothread.run(Rescheduled)
	checklog{
		"Rescheduled started",
		"Rescheduled suspended",
		"Rescheduled rescheduled",
		"Rescheduled suspended",
		"Rescheduled rescheduled",
		"Rescheduled ended",
	}
	
	checkend(cothread)
end
