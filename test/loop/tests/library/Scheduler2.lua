local Scheduler = require "loop.thread.Scheduler"

--Scheduler.verbose:level(2)
--Scheduler.verbose.inspect.threads = Scheduler.verbose.inspect.debug

local EventLog
local function say(name, msg)
	EventLog[#EventLog+1] = name.." "..msg
end
local function finish(name, ...)
	say(name, "ended")
	return ...
end
local function newtask(name, func)
	local task = coroutine.create(function(...)
		say(name, "started")
		return finish(name, (func or coroutine.yield)(name, ...))
	end)
	Scheduler.verbose.viewer.labels[task] = name
	return task
end

local function test(checks, Scheduler)
	local Yielder = newtask("Yielder", function(name)
		for i = 1, 2 do
			coroutine.yield()
			say(name, "resumed")
		end
	end)
	local Resumer = newtask("Resumer", function(name)
		for i = 1, 2 do
			Scheduler:resume(Yielder)
			say(name, "resumed")
		end
	end)
	Scheduler:register(Resumer)
	
	EventLog = {}
	Scheduler:run()
	checks:assert(Scheduler.current, checks.is(false))
	checks:assert(EventLog, checks.similar{
		"Resumer started",
		"Yielder started",
		"Resumer resumed",
		"Yielder resumed",
		"Resumer resumed",
		"Resumer ended",
		"Yielder resumed",
		"Yielder ended",
	})
	
	EventLog = {}
	for i=1, 3 do
		checks:assert(Scheduler:step(), checks.is(nil))
		checks:assert(EventLog, checks.similar{})
	end
	checks:assert(Scheduler:run(), checks.is(nil))
	checks:assert(EventLog, checks.similar{})
end

local stdassert = assert
local function assert(ok, err, ...)
	if not ok then error(err, 2) end
	return ok, err, ...
end

return function(checks)
	local instances = {
		Scheduler(),
		Scheduler,
		Scheduler(),
	}
	-- main loop runs in the main thread
	for index, scheduler in ipairs(instances) do
		--Scheduler.verbose.schedulerdetails = scheduler
		test(checks, scheduler)
	end
end