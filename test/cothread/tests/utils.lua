for name, op in pairs(coroutine) do
	_G[name] = op
end

Labels = {}

function resetlog()
	EventLog = {}
end

function resetscheduler(cothread)
	-- the following code unschedules all threads currently scheduled.
	for _, iter in ipairs{cothread.ready,cothread.waiting} do
		while true do
			local f,s,i = iter()
			local thread = f(s,i)
			if thread == nil then break end
			cothread.unschedule(thread)
		end
	end
	while true do
		local f,s,i = cothread.signals()
		local signal = f(s,i)
		if signal == nil then break end
		while true do
			local f,s,i = cothread.waiting(signal)
			local thread = f(s,i)
			if thread == nil then break end
			cothread.unschedule(thread)
		end
	end
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

function checklog(expected)
	for index, expected in ipairs(expected) do
		assert(EventLog[index] == expected, "wrong event "..index)
	end
end

function checkend(scheduler)
	resetlog()
	for i=1, 3 do
		assert(scheduler.round() == false)
		assert(next(EventLog) == nil)
	end
end

resetlog()
