local Scheduler = require "loop.thread.NewScheduler"

--Scheduler.verbose:level(2)
--Scheduler.verbose:flag("debug", false)

local EventLog
local function say(name, msg)
	EventLog[#EventLog+1] = name.." "..msg

print(EventLog[#EventLog])

end

local function test(checks, Scheduler)
	--Scheduler.verbose.schedulerdetails = Scheduler
	
	local function newtask(name, func)
		local task = coroutine.create(function(...)
			say(name, "started");
			(func or coroutine.yield)(name, ...)
			say(name, "ended")
		end)
		Scheduler.verbose.labels[task] = name
		return task
	end
	
	local First = newtask("First")
	local Last = newtask("Last")
	local Waker = newtask("Waker", function(name)
		local msg = Scheduler:suspend()
		checks:assert(msg, checks.is("from Resumer"))
	end)
	local Resumer = newtask("Resumer", function(name, msg)
		checks:assert(msg, checks.is("from Sleeper1"))
		Scheduler:resume(Waker, "from "..name)
	end)
	local Sleeper1 = newtask("Sleeper1", function(name)
		Scheduler:suspend(1)
		say(name, "woke")
		Scheduler:resume(Resumer, "from "..name)
	end)
	local Sleeper2 = newtask("Sleeper2", function(name)
		Scheduler:suspend(2)
		say(name, "woke")
	end)
	local Sleeper3 = newtask("Sleeper3", function(name)
		Scheduler:suspend(3)
		say(name, "woke")
	end)
	local Suspender = newtask("Suspender", function(name)
		Scheduler:suspend() -- never returns
	end)
	local Starter = newtask("Starter", function(name)
		Scheduler:start(function()
			say("Started", "started")
			coroutine.yield()
			say("Started", "ended")
		end)
	end)
	local Raiser = newtask("Raiser", function(name)
		assert(pcall(Scheduler.halt, Scheduler)) -- should raise an error
	end)
	Scheduler.traps[Raiser] = function(scheduler, coroutine, success, error)
		checks:assert(scheduler, checks.is(Scheduler))
		checks:assert(coroutine, checks.is(Raiser))
		checks:assert(success, checks.is(false))
		checks:assert(error, checks.match("./loop/tests/library/Scheduler.lua:%d%d: attempt to yield across metamethod/C%-call boundary"))
		say("Raiser", "failed")
	end
	local Catcher = newtask("Catcher", function(name)
		pcall(Scheduler.halt, Scheduler) -- halt should fail
	end)
	local Halter = newtask("Halter", function(name)
		Scheduler:halt()
	end)

	Scheduler:register(First)
	Scheduler:register(Sleeper1)
	Scheduler:register(Sleeper2)
	Scheduler:register(Sleeper3)
	Scheduler:register(Suspender)
	Scheduler:register(Starter)
	Scheduler:register(Waker)
	Scheduler:register(Raiser)
	Scheduler:register(Catcher)
	Scheduler:register(Halter)
	Scheduler:register(Last)
	
	EventLog = {}
	Scheduler:run()

print("-- halt --")

	checks:assert(Scheduler.current, checks.is(false))
	checks:assert(EventLog, checks.similar{
		"First started",
		"Sleeper1 started",
		"Sleeper2 started",
		"Sleeper3 started",
		"Suspender started",
		"Starter started",
		"Started started",
		"Waker started",
		"Raiser started",
		"Raiser failed",
		"Catcher started",
		"Catcher ended",
		"Halter started",
	})
	local Expected
	if not coroutine.running() or coroutine.yield() == 1 then
		Expected = {
			{
				"Halter ended",
				"Last started",
			},{
				"First ended",
				"Starter ended",
				"Started ended",
				"Last ended",
				 pause=true,
			},{
				"Sleeper1 woke",
				"Resumer started",
				"Waker ended",
			},{
				"Sleeper1 ended",
				"Resumer ended",
				 pause=true,
			},{
				"Sleeper2 woke",
				"Sleeper2 ended",
				 pause=true,
			},{
				"Sleeper3 woke",
				"Sleeper3 ended",
			},
		}
	else
		Expected = {
			{
				"Sleeper1 woke",    --
				"Resumer started", --
				"Waker ended",     --
				"Sleeper2 woke",   --  woken before the current thread ?
				"Sleeper2 ended",  --
				"Sleeper3 woke",   --
				"Sleeper3 ended",  --
				"Halter ended",
				"Last started",
			},{
				"First ended",
				"Starter ended",
				"Started ended",
				"Sleeper1 ended",
				"Resumer ended",
				"Last ended",
			}
		}
	end
	local last = #Expected
	for step, events in ipairs(Expected)  do
		EventLog = {}
		local stepresult
		if events.pause then
			stepresult = checks.both( checks.typeis("number"), checks.isnot(0) )
		elseif step ~= last then
			stepresult = checks.is(0)
		else
			stepresult = checks.is(nil)
		end
		local nextstep = Scheduler:step()
		if nextstep == nil then
			checks:assert(step, checks.is(last))
		elseif nextstep == 0 then
			checks:assert(step < last, "step should have returned 'nil', but was 0")
		else
			EventLog.pause = true
		end
		checks:assert(Scheduler.current, checks.is(false))
		checks:assert(EventLog, checks.similar(events))
		if nextstep and nextstep > 0 then

print("-- pause --")

			Scheduler:idle(nextstep)

else print("-- step --")

		end
	end
	EventLog = {}
	for i=1, 3 do
		checks:assert(EventLog, checks.similar{})
		checks:assert(Scheduler:step(), checks.is(nil))
	end
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
		test(checks, scheduler)
	end
	-- main loop runs in a coroutine
	local nests = {
		coroutine.create(test),
		coroutine.create(test),
		coroutine.create(test),
	}
	for index, scheduler in ipairs(instances) do
		assert(coroutine.resume(nests[index], checks, scheduler))
	end
	for index, nest in ipairs(nests) do

print("-- SCHEDULER YIELD --")

		assert(coroutine.resume(nest, index))
	end
end