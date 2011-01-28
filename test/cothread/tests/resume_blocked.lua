return function()
	local Blocked = newtask("Blocked", function()
		yield("pause")
		say("Blocked", "resumed")
		yield("suspend")
	end)
	cothread.schedule(Blocked, "wait", "some event")
	
	local Resumer = newtask("Resumer", function()
		yield("yield", Blocked)
		say("Resumer", "resumed")
		yield("yield", Blocked)
		say("Resumer", "resumed again")
		yield("schedule", yield("cancel", "some event"))
	end)
	
	cothread.run(Resumer)
	checklog{
		"Resumer started",
		"Blocked started",
	}
	
	resetlog()
	cothread.run(Resumer)
	checklog{
		"Resumer resumed",
		"Blocked resumed",
	}
	
	resetlog()
	cothread.run(Resumer)
	checklog{
		"Resumer resumed again",
		"Resumer ended",
		"Blocked ended",
	}
	
	checkend(cothread)
end
