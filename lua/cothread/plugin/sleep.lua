local _G = require "_G"                                                         --[[VERBOSE]] local strformat = require("string").format
local setmetatable = _G.setmetatable

local coroutine = require "coroutine"
local newcoroutine = coroutine.create
local yield = coroutine.yield

local os = require "os"
local gettime = os.time
local difftime = os.difftime

local SortedMap = require "loop.collection.SortedMap"

local StartTime = gettime()
local function defaultnow()
	return difftime(gettime(), StartTime)
end

local WeakKeys = {__mode = "k"}
local WeakValues = {__mode = "v"}

return function(_ENV, cothread)
	if _G._VERSION=="Lua 5.1" then _G.setfenv(1,_ENV) end -- Lua 5.1 compatibility
	
	now = cothread.now
	if now == nil then
		now = defaultnow
	end
	idle = cothread.idle
	if idle == nil then
		function idle(timeout)
			repeat until now() >= timeout
		end
	end
	
	-- Linked list of wake times of delayed threads in ascesding order. Each entry
	-- contains a reference to the first thread in 'scheduled' that must be waken
	-- at that time.
	local wakeindex = SortedMap{ nodepool = setmetatable({}, WeakValues) }
	-- Table mapping threads to its last wake time. This last wake time may be old
	-- thus the thread may not be sleeping anymore.
	local waketime = setmetatable({}, WeakKeys)

	waker = newcoroutine(function()
		while true do
			local first, time = wakeindex:head()
			if first ~= nil then
				local timenow = now()
				local remains
				remains, time = wakeindex:cropuntil(timenow, "orLater") -- exclusive
				if time == timenow then -- make it inclusive if its a perfect match!
					wakeindex:pop()
					remains, time = wakeindex:head()
				end
				if remains ~= first then
					local last = placeof[remains or first]
					scheduled:move(first, lastready, last)                                --[[VERBOSE]] verbose:threads("delayed ",first," to ",last," are ready for execution");verbose:state()
				end
			end
			if time == nil then                                                       --[[VERBOSE]] verbose:scheduler("no threads to be waken")
				yield("suspend")
			elseif scheduled[waker] ~= waker then                                     --[[VERBOSE]] verbose:scheduler("other threads are ready to be resumed")
				idle(now())
				yield("yield")
			else                                                                      --[[VERBOSE]] verbose:scheduler("nothing to be done until ",time)
				idle(time)
			end
		end
	end)                                                                          --[[VERBOSE]] verbose.viewer.labels[waker] = "Waker"

	------------------------------------------------------------------------------
	-- All expected cases:
	--
	-- Arrows indicate changes performed by the method.
	-- No arrows means no change.
	--
	-- waketime  = { ... }
	-- wakeindex = { ... }
	-- scheduled = [ ... ]
	--
	-- waketime  = { ... [thread] = time }  --> { ... }
	-- wakeindex = { ... }
	-- scheduled = [ ... ]
	--
	-- waketime  = { ... [thread] = time   } --> { ... }
	-- wakeindex = { ... [time]   = thread } --> { ... }
	-- scheduled = [ ... thread ]
	--
	-- waketime  = { ... [thread] = time   } --> { ... [nextthread] = time       }
	-- wakeindex = { ... [time]   = thread } --> { ... [time]       = nextthread }
	-- scheduled = [ ... thread, nextthread... ]
	--
	-- waketime  = { ... [thread] = time  , [nextentry.value] = nextentry.key...   } --> { ... [nextentry.value] = nextentry...       }
	-- wakeindex = { ... [time]   = thread, [nextentry.key]   = nextentry.value... } --> { ... [nextentry.key]   = nextentry.value... }
	-- scheduled = [ ... thread, nextentry.value... ]
	--
	-- waketime  = { ... [thread] = time  , [nextentry.value] = nextentry.key...   } --> { [nextthread] = time      , [nextentry.value] = nextentry.key...   }
	-- wakeindex = { ... [time]   = thread, [nextentry.key]   = nextentry.value... } --> { [time]       = nextthread, [nextentry.key]   = nextentry.value... }
	-- scheduled = [ ... thread, nextthread..nextentry.value... ]
	--
	local function unscheduled(thread)
		onreschedule(thread, nil)
		local timestamp = waketime[thread]
		if timestamp ~= nil then -- 'thread' *may* be sleeping.
			waketime[thread] = nil
			local path = {}
			local entry = wakeindex:findnode(timestamp, path)
			if entry ~= nil
			and entry.key == timestamp
			and entry.value == thread
			then -- yes, it is sleeping.
				local nextentry = wakeindex:nextnode(entry)
				local nextthread = scheduled[thread]
				if (nextentry ~= nil and nextentry.value == nextthread) -- one thread here
				or (nextthread == wakeindex:head())      -- last thread in the whole queue
				then -- no other thread is waiting here
					wakeindex:removefrom(path, entry)
					if wakeindex:head() == nil then
						unschedule(waker)
					end
				else -- other thread is waiting to wake at the same time
					entry.value = nextthread
					waketime[nextthread] = timestamp
					onreschedule(nextthread, unscheduled)
				end                                                                     --[[VERBOSE]] verbose:threads("wake time of delayed ",thread," was cancelled")
				return true
			end
		end
	end

	local defer = scheduleop("defer", function(thread, time, ...)
		local entry = wakeindex:getnode()
		local found = wakeindex:findnode(time, entry)
		local place
		if found ~= nil and found.key == time then
			wakeindex:freenode(entry)
			place = found.value
			if place ~= thread then                                                   --[[VERBOSE]] verbose:threads("wake time of ",thread," is the same of ",place)
				reschedule(thread, place)
			end
		else
			if found == nil then
				place = wakeindex:head()
				if place == nil then
					schedule(waker, "last")
					place = thread
				else
					place = placeof[place]
				end
			else
				place = placeof[found.value]
			end
			reschedule(thread, place)
			entry.key = time
			entry.value = thread
			wakeindex:addto(entry, entry)
			waketime[thread] = time
			onreschedule(thread, unscheduled)
		end                                                                         --[[VERBOSE]] verbose:threads(thread," was deferred until ",strformat("%.2f", time-begin)); verbose:state()
		return thread, ...
	end)

	scheduleop("delay", function(thread, time, ...)
		return defer(thread, now()+time, ...)
	end)

	local function nextdelayed(state, previous, timestamp)
		if previous == nil then return state.first, timestamp end
		local thread = scheduled[previous]
		if thread == state.first then return end
		local nextwake = state.nextwake
		if nextwake and nextwake.value == thread then
			state.nextwake = wakeindex:nextnode(nextwake)
			timestamp = nextwake.key
		end
		return thread, timestamp
	end
	moduleop("alldeferred", function()
		local first = wakeindex:nextnode()
		if first == nil then return nextthread, nil, nil end
		local state = { first = first.value, nextwake = wakeindex:nextnode(first) }
		return nextdelayed, state, nil, first.key
	end, "yieldable")

	moduleop("now", now, "yieldable")

	--[[VERBOSE]] begin = now()
	--[[VERBOSE]] local string = _G.require "string"
	--[[VERBOSE]] local format = string.format
	--[[VERBOSE]] statelogger("Delayed", function(self, missing, newline)
	--[[VERBOSE]] 	local output = self.viewer.output
	--[[VERBOSE]] 	local labels = self.viewer.labels
	--[[VERBOSE]] 	local last = wakeindex:nextnode()
	--[[VERBOSE]] 	local first = last and last.value
	--[[VERBOSE]] 	while last ~= nil do
	--[[VERBOSE]] 		local waketime = last.key
	--[[VERBOSE]] 		output:write(format(" [%.2f]:", waketime-begin))
	--[[VERBOSE]] 		local next = wakeindex:nextnode(last)
	--[[VERBOSE]] 		local limit = (next ~= nil) and next.value or first
	--[[VERBOSE]] 		local thread = last.value
	--[[VERBOSE]] 		repeat
	--[[VERBOSE]] 			if missing[thread] == nil then
	--[[VERBOSE]] 				output:write("<STATE CORRUPTION>")
	--[[VERBOSE]] 				break
	--[[VERBOSE]] 			end
	--[[VERBOSE]] 			missing[thread] = nil
	--[[VERBOSE]] 			output:write(" ",labels[thread])
	--[[VERBOSE]] 			thread = scheduled[thread]
	--[[VERBOSE]] 		until thread == limit
	--[[VERBOSE]] 		last = next
	--[[VERBOSE]] 	end
	--[[VERBOSE]] end)
end