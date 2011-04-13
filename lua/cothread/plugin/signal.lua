local _G = require "_G"
local next = _G.next

return function(_ENV, cothread)
	_G.pcall(_G.setfenv, 2, _ENV) -- compatibility with Lua 5.1
	
	local lastwait = {}
	local signalof = {}
	
	local function freesignal(signal, thread)
		lastwait[signal] = nil
		signalof[thread] = nil
		onreschedule(thread, nil)
	end
	local function unscheduled(thread, previous)
		local signal = signalof[thread]
		if previous == thread then
			freesignal(signal, thread)
		else
			lastwait[signal] = previous
			signalof[previous] = signal
			onreschedule(previous, unscheduled)
			signalof[thread] = nil
			onreschedule(thread, nil)
		end
	end
	local function newsignal(signal, thread)
		lastwait[signal] = thread
		signalof[thread] = signal
		onreschedule(thread, unscheduled)
	end
	
	
	
	--do
	--	local eventcreator = setmetatable({}, WeakKeys)
	--	local backup = newsignal
	--	local trapped
	--	function api.oneventwait(event, trap)
	--		eventcreator[event] = trap
	--		if trap ~= nil then
	--			newsignal = trapped
	--		elseif next(eventcreator) == nil then
	--			newsignal = backup
	--		end
	--	end
	--	trapped = trappedfunc(backup, eventcreator)
	--end
	--
	--do
	--	local eventreleaser = setmetatable({}, WeakKeys)
	--	local backup = freesignal
	--	local trapped
	--	function api.oneventignored(event, trap)
	--		eventreleaser[event] = trap
	--		if trap ~= nil then
	--			freesignal = trapped
	--		elseif next(eventreleaser) == nil then
	--			freesignal = backup
	--		end
	--	end
	--	trapped = trappedfunc(backup, eventcreator)
	--end
	
	
	
	scheduleop("wait", function(thread, signal, ...)
		local last = lastwait[signal]
		if last ~= thread then
			reschedule(thread, last)
			newsignal(signal, thread)
			last = thread
		end                                                                         -- [[VERBOSE]] verbose:threads(thread," scheduled as waiting ",signal);verbose:state()
		return thread, ...
	end)
	
	moduleop("notify", function(signal)
		local last = lastwait[signal]
		if last ~= nil then
			freesignal(signal, last)
			scheduled:movefrom(last, lastready, last)
			lastready = last
			return true
		end
	end, "yieldable")
	
	moduleop("allsignals", function()
		return next, lastwait
	end, "yieldable")
	
	moduleop("allwaiting", function(signal)
		return nextthread, lastwait[signal]
	end, "yieldable")
	
	
	
	-- [[VERBOSE]] local string = _G.require "string"
	-- [[VERBOSE]] local format = string.format
	-- [[VERBOSE]] statelogger("Blocked", function(self, missing, newline)
	-- [[VERBOSE]] 	local output = self.viewer.output
	-- [[VERBOSE]] 	local labels = self.viewer.labels
	-- [[VERBOSE]] 	local first = true
	-- [[VERBOSE]] 	for signal, last in pairs(lastwait) do
	-- [[VERBOSE]] 		if not first then
	-- [[VERBOSE]] 			output:write(newline, "        ")
	-- [[VERBOSE]] 			first = false
	-- [[VERBOSE]] 		end
	-- [[VERBOSE]] 		output:write(" ", labels[signal] or tostring(signal), "=[")
	-- [[VERBOSE]] 		for thread in scheduled:forward(last) do
	-- [[VERBOSE]] 			if missing[thread] == nil then
	-- [[VERBOSE]] 				output:write("<STATE CORRUPTION>")
	-- [[VERBOSE]] 				break
	-- [[VERBOSE]] 			end
	-- [[VERBOSE]] 			missing[thread] = nil
	-- [[VERBOSE]] 			output:write(" ",labels[thread])
	-- [[VERBOSE]] 			if thread == last then
	-- [[VERBOSE]] 				output:write(" ]")
	-- [[VERBOSE]] 				break
	-- [[VERBOSE]] 			end
	-- [[VERBOSE]] 		end
	-- [[VERBOSE]] 	end
	-- [[VERBOSE]] end)
end