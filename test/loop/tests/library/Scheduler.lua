local Scheduler = require "loop.thread.Scheduler"

--Scheduler.verbose:level(2)
--Scheduler.verbose:flag("print", true)
--Scheduler.verbose:flag("debug", false)

local EventLog
local function say(name, msg)
	EventLog[#EventLog+1] = name.." "..msg

--print(EventLog[#EventLog])

end
local function finish(name, ...)
	say(name, "ended")
	return ...
end
local function newtask(name, func)
	local task = coroutine.create(function(...)
		say(name, "started");
		return finish(name, (func or coroutine.yield)(name, ...))
	end)
	Scheduler.verbose.viewer.labels[task] = name
	return task
end

local function test(checks, Scheduler)
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
	local Remover = newtask("Remover", function(name)
		Scheduler:remove(Scheduler.current)
		say(name, "removed itself")
		coroutine.yield()
	end)
	local Removed = newtask("Removed")
	local RemovedSleeper = newtask("RemovedSleeper", function(name)
		Scheduler:suspend(1)
		say(name, "woke")
	end)
	local ResumedSleeper = newtask("ResumedSleeper", function(name)
		Scheduler:suspend(10)
		say(name, "woke")
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
		Scheduler:remove(Removed)
		Scheduler:remove(RemovedSleeper)
		Scheduler:resume(ResumedSleeper)
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
		local success = pcall(Scheduler.halt, Scheduler) -- halt should fail
		checks:assert(success, checks.is(false))
	end)
	local Halter = newtask("Halter", function(name)
		Scheduler:halt()
	end)
	local Waiter1 = newtask("Waiter1", function(name)
		say(name, "waiting")
		local msg = Scheduler:wait("event")
		checks:assert(msg, checks.is("from Notifier"))
		return msg
	end)
	local Waiter2 = newtask("Waiter2", function(name)
		say(name, "waiting")
		local msg = Scheduler:wait("event")
		checks:assert(msg, checks.is("from Notifier"))
		return msg
	end)
	local Waiter3 = newtask("Waiter3", function(name)
		say(name, "waiting")
		local msg = Scheduler:wait("event")
		checks:assert(msg, checks.is("from Notifier"))
		return msg
	end)
	local Notifier = newtask("Notifier", function(name)
		say(name, "notifing one")
		Scheduler:notify("event", "from "..name)
		say(name, "notifing all others")
		return Scheduler:notifyall("event", "from "..name)
	end)

	Scheduler:register(First)
	Scheduler:register(Sleeper1)
	Scheduler:register(Sleeper2)
	Scheduler:register(Sleeper3)
	Scheduler:register(Waiter1)
	Scheduler:register(Waiter2)
	Scheduler:register(Waiter3)
	Scheduler:register(Remover)
	Scheduler:register(Removed)
	Scheduler:register(RemovedSleeper)
	Scheduler:register(ResumedSleeper)
	Scheduler:register(Suspender)
	Scheduler:register(Starter)
	Scheduler:register(Waker)
	Scheduler:register(Raiser)
	Scheduler:register(Catcher)
	Scheduler:register(Halter)
	Scheduler:register(Notifier)
	Scheduler:register(Last)
	
	EventLog = {}
	Scheduler:run()
	
	checks:assert(Scheduler.current, checks.is(false))
	checks:assert(EventLog, checks.similar{
		"First started",
		"Sleeper1 started",
		"Sleeper2 started",
		"Sleeper3 started",
		"Waiter1 started",
		"Waiter1 waiting",
		"Waiter2 started",
		"Waiter2 waiting",
		"Waiter3 started",
		"Waiter3 waiting",
		"Remover started",
		"Remover removed itself",
		"Removed started",
		"RemovedSleeper started",
		"ResumedSleeper started",
		"Suspender started",
		"ResumedSleeper woke",
		"ResumedSleeper ended",
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
				"Notifier started",
				"Notifier notifing one",
				"Waiter3 ended",
				"Last started",
			},{
				"First ended",
				"Starter ended",
				"Started ended",
				"Notifier notifing all others",
				"Waiter2 ended",
				"Waiter1 ended",
				"Last ended",
			},{
				"Notifier ended",
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
				"Sleeper1 woke",   --
				"Resumer started", --
				"Waker ended",     --
				"Sleeper2 woke",   --  woken before the current thread ?
				"Sleeper2 ended",  --
				"Sleeper3 woke",   --
				"Sleeper3 ended",  --
				"Halter ended",
				"Notifier started",
				"Notifier notifing one",
				"Waiter3 ended",
				"Last started",
			},{
				"First ended",
				"Starter ended",
				"Started ended",
				"Sleeper1 ended",
				"Resumer ended",
				"Notifier notifing all others",
				"Waiter2 ended",
				"Waiter1 ended",
				"Last ended",
			},{
				"Notifier ended",
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

--print("-- pause --")

			Scheduler:idle(nextstep)

--else print("-- step --")

		end
	end
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
	-- main loop runs in a coroutine
	local nests = {
		coroutine.create(test),
		coroutine.create(test),
		coroutine.create(test),
	}
	for index, scheduler in ipairs(instances) do
		--Scheduler.verbose.schedulerdetails = scheduler
		assert(coroutine.resume(nests[index], checks, scheduler))
	end
	for index, nest in ipairs(nests) do

--print("-- SCHEDULER YIELD --")

		--Scheduler.verbose.schedulerdetails = scheduler
		assert(coroutine.resume(nest, index))
	end
end