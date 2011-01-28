return function()
	local PauseSim = newtask("PauseSim", function(name)
		for i = 1, 2 do
			local current = running()
			assert(yield("schedule", current) == current)
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
			assert(yield("schedule", current, "after", Dummy) == current)
			say(name, "suspended")
			yield("suspend")
			say(name, "rescheduled")
		end
	end)
	
	assert(cothread.schedule(PauseSim) == PauseSim)
	assert(cothread.schedule(Dummy) == Dummy)
	assert(cothread.schedule(PauseSim2) == PauseSim2)
	cothread.run()
	checklog{
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
	}
	
	checkend(cothread)
end
