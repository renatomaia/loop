return function(checks)
	local PauseSim = newtask("PauseSim", function(name)
		for i = 1, 2 do
			local current = running()
			checks:assert(
				yield("schedule", current),
				checks.is(current))
			say(name, "suspended")
			yield("suspend")
			say(name, "rescheduled")
		end
	end)
	local Dummy = newtask("Dummy", function (name)
		for i = 1, 2 do
			say(name, "suspended")
			yield("pause")
			say(name, "rescheduled")
		end
	end)
	local PauseSim2 = newtask("PauseSim2", function(name)
		for i = 1, 2 do
			local current = running()
			checks:assert(
				yield("schedule", current, "after", Dummy),
				checks.is(current))
			say(name, "suspended")
			yield("suspend")
			say(name, "rescheduled")
		end
	end)
	
	checks:assert(cothread.schedule(PauseSim), checks.is(PauseSim))
	checks:assert(cothread.schedule(Dummy), checks.is(Dummy))
	checks:assert(cothread.schedule(PauseSim2), checks.is(PauseSim2))
	cothread.run()
	checks:assert(EventLog, checks.similar{
		"PauseSim started",
		"PauseSim suspended",
		"Dummy started",
		"Dummy suspended",
		"PauseSim2 started",
		"PauseSim2 suspended",
		"PauseSim rescheduled",
		"PauseSim suspended",
		"Dummy rescheduled",
		"Dummy suspended",
		"PauseSim2 rescheduled",
		"PauseSim2 suspended",
		"PauseSim rescheduled",
		"PauseSim ended",
		"Dummy rescheduled",
		"Dummy ended",
		"PauseSim2 rescheduled",
		"PauseSim2 ended",
	})
	
	checkend(checks, cothread)
end
