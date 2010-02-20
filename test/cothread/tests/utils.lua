for name, op in pairs(coroutine) do
	_G[name] = op
end

Labels = {}

function resetlog()
	EventLog = {}
end

function say(name, msg)
	EventLog[#EventLog+1] = name.." "..msg
end

function finish(name, ...)
	say(name, "ended")
	return ...
end

local function defaultbody()
	return yield("pause")
end

function newtask(name, func)
	local task = create(function(...)
		say(name, "started")
		if func == nil then func = defaultbody end
		return finish(name, func(name, ...))
	end)
	Labels[task] = name
	return task
end

function checkend(checks, scheduler)
	resetlog()
	for i=1, 3 do
		checks:assert(scheduler.step(), checks.is(false))
		checks:assert(EventLog, checks.similar{})
	end
end

resetlog()