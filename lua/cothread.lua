-- Project: CoThread
-- Release: 1.0 beta
-- Title  : Cooperative Threads Scheduler based on Coroutines
-- Author : Renato Maia <maia@inf.puc-rio.br>

local _G = require "_G"
local luaerror = _G.error
local next = _G.next
local pairs = _G.pairs
local setmetatable = _G.setmetatable
local type = _G.type

local coroutine = require "coroutine"
local status = coroutine.status
local resume = coroutine.resume
local yield = coroutine.yield

local os = require "os"
local gettime = os.time
local difftime = os.difftime

local tabop = require "loop.table"
local memoize = tabop.memoize

local oo = require "loop.base"
local class = oo.class
local rawnew = oo.rawnew

local BiCyclicSets = require "loop.collection.BiCyclicSets"
local SortedMap = require "loop.collection.SortedMap"

module(...)

local WeakValues = class{ __mode = "v" }
local WeakKeys   = class{ __mode = "k" }
local default    = {}
local traceback  = _G.debug and
                   	_G.debug.traceback or
                   	function(_, err) return err end

--------------------------------------------------------------------------------
-- Customizable Behavior -------------------------------------------------------
--------------------------------------------------------------------------------

local StartTime = gettime()
function default.now()
	return difftime(gettime(), StartTime)
end

local getnow = default.now
function default.idle(timeout)                                                  --[[VERBOSE]] verbose:scheduler("starting busy-waiting for ",timeout-now()," seconds")
	repeat until getnow() > timeout                                               --[[VERBOSE]] verbose:scheduler("busy-waiting ended")
end

function default.error(thread, errmsg)                                          --[[VERBOSE]] verbose:scheduler("re-raising error of ",thread,": ",errmsg)
	luaerror(traceback(thread, errmsg))
end

--------------------------------------------------------------------------------
-- Safe Control Functions ------------------------------------------------------
--------------------------------------------------------------------------------

local paramtypes = {
	halt = false,
	suspend = false,
	pause = false,
	yield = "thread",
	resume = "thread",
	delay = "number",
	defer = "number",
}

for yieldop, paramtype in pairs(paramtypes) do
	if not paramtype then
		default[yieldop] = function(...)
			return yield(yieldop, ...)
		end
	else
		default[yieldop] = function(param, ...)
			local actualtype = type(param)
			if actualtype ~= paramtype then
				error("bad argument #1 to '"..yieldop
				    .."' ("..paramtype.." expected, got "..actualtype..")")
			end
			return yield(yieldop, param, ...)
		end
	end
end

function default.wait(signal, ...)
	if not signal or type(signal) == "thread" then
		error("bad argument #1 to 'wait' (signal cannot be nil, false or thread)")
	end
	return yield("wait", signal, ...)
end

--------------------------------------------------------------------------------
-- Begin of Instantiation Code -------------------------------------------------
--------------------------------------------------------------------------------

function new(attribs)
	if attribs == nil then attribs = {} end
	for field, value in pairs(default) do
		if attribs[field] == nil then attribs[field] = value end
	end
	_G.setfenv(1, attribs) -- Lua 5.2: _ENV = attribs

--------------------------------------------------------------------------------
-- Initialization Code ---------------------------------------------------------
--------------------------------------------------------------------------------

local rescheduled = false -- flag indicating whether the last resumed ready
                          -- thread was explcicitly rescheduled as ready in the
                          -- the same position it was before.
local lastready = false -- Token marking the head of the list of threads ready
                        -- for execution. When it is not 'false' it also
                        -- indicate the last resumed thread from the list of
                        -- threads ready for execution.
local scheduled = BiCyclicSets()    -- Table containing all scheduled threads.
local placeof = scheduled:reverse() -- It is organized as disjoint sets, which
scheduled:add(lastready)            -- values are arranged in cyclic order.
                                    -- The sets are organized as follows:
                                    -- 1. One set of threads ready for execution.
                                    --    This set is always present containing
                                    --    the value 'false' that also indicates
                                    --    the "start" and "end" of the set.
                                    -- 2. At most one set of delayed threads.
                                    --    This set contains threads in ascending
                                    --    order of the time they must wake
                                    --    (except for the point were the last
                                    --    thread to be waken is followed by the
                                    --    first one). The exact time each thread
                                    --    must be waken is maintained in table
                                    --    'wakeindex'.
                                    -- 3. Zero or more sets of threads waiting
                                    --    for a signal. Each set contains the
                                    --    value of the signal followed by the
                                    --    threads waiting for it. There is no
                                    --    set containing only a signal and no
                                    --    threads.
local wakeindex = SortedMap{ -- Linked list of wake times of delayed threads in
	nodepool = WeakValues(),   -- ascesding order. Each entry contains a reference
}                            -- to the first thread in 'scheduled' that must be
                             -- waken at that time.
local waketime = WeakValues() -- Table mapping threads to its last wake time.
                              -- This last wake time may be old thus the thread
                              -- may not be sleeping anymore.
traps = traps or WeakKeys() -- Table mapping threads to the function that must
                            -- be executed when the thread finishes.

--------------------------------------------------------------------------------
-- Internal Functions ----------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
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
-- waketime  = { ... [thread]    = time   }  --> { ... }
-- wakeindex = { ... [entry.key] = thread } --> { ... }
-- scheduled = [ ... thread ]
--
-- waketime  = { ... [thread] = time   } --> { ... [nextthread] = time        }
-- wakeindex = { ... [time]   = thread } --> { ... [time]       = nextthread }
-- scheduled = [ ... thread, nextthread... ]
--
-- waketime  = { ... [thread] = time  , [nextentry.value] = nextentry.key...   } --> { ... [nextentry.value] = nextentry...       }
-- wakeindex = { ... [time]   = thread, [nextentry.key]   = nextentry.value... } --> { ... [nextentry.key]   = nextentry.value... }
-- scheduled = [ ... thread, nextentry.value... ]
--
-- waketime  = { ... [thread] = time  , [nextentry.value] = nextentry.key   } --> { [nextthread] = time      , [nextentry.value] = nextentry.key   }
-- wakeindex = { ... [time]   = thread, [nextentry.key]   = nextentry.value } --> { [time]       = nextthread, [nextentry.key]   = nextentry.value }
-- scheduled = [ ... thread, nextthread..nextentry.value... ]
--
local function cancelwake(thread)
	local timestamp = waketime[thread]
	if timestamp then -- 'thread' *may* be sleeping.
		waketime[thread] = nil
		local path = {}
		local entry = wakeindex:findnode(timestamp, path)
		if entry ~= nil and entry.value == thread then -- yes, it is sleeping.
			local nextentry = wakeindex:nextnode(entry)
			local nextthread = scheduled[thread]
			if (nextentry and nextentry.value == nextthread) -- only one in this entry
			or (nextthread == wakeindex:head())            -- the last in sleeping set
			then -- no other thread is waiting here
				wakeindex:removefrom(path, entry)
			else -- other thread is waiting to wake at the same time
				entry.value = nextthread
				waketime[nextthread] = timestamp
			end                                                                       --[[VERBOSE]] verbose:threads("wake time of delayed thread ",thread," was cancelled")
			return true
		end
	end
end

local function cancelblock(thread)
	local signal = scheduled[thread]
	if signal -- is not 'nil' nor 'false'
	and scheduled[signal] == thread
	and type(signal) ~= "thread"
	then
		scheduled:remove(signal)
		if signalcanceled then signalcanceled(signal) end
	end
end

--------------------------------------------------------------------------------
-- Introspection Support -------------------------------------------------------
--------------------------------------------------------------------------------

function isscheduled(thread)
	return scheduled[thread] ~= nil
end

local function nextthread(ending, previous)
	if previous == nil then return ending end
	local thread = scheduled[previous]
	if thread ~= ending then return thread end
end
function ready()
	return nextthread, false, false
end
function waiting(signal)
	if signal
		then return nextthread, signal, signal
		else return nextthread, wakeindex:head(), nil
	end
end

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
function delayed()
	local first = wakeindex:nextnode()
	if first == nil then return nextthread, nil, nil end
	local state = { first = first.value, nextwake = wakeindex:nextnode(first) }
	return nextdelayed, state, nil, first.key
end

local function nextsignal(_, signal)
	repeat signal = next(scheduled, signal)
	until signal == nil or (signal and type(signal) ~= "thread")
	return signal
end
function signals()
	return nextsignal
end

--------------------------------------------------------------------------------
-- Scheduling Operations -------------------------------------------------------
--------------------------------------------------------------------------------

local function dummy() end
local findplace = rawnew{ __index = function() return dummy end }

function findplace.after(thread, place)
	if place == thread then
		return lastready
	elseif scheduled[place] ~= nil then
		return place
	end
end

function findplace.wait(_, signal)
	if signal and type(signal) ~= "thread" then
		local place = placeof[signal]
		if signal and place == nil then                                             --[[VERBOSE]] verbose:threads("new signal ",signal," will be registered")
			place = signal
		end
		return place
	end
end

function findplace.defer(thread, time)
	local entry = { key = time, value = thread }
	local found, previous = wakeindex:findnode(time, entry)
	if found then
		previous = found.value                                                      --[[VERBOSE]] verbose:threads("wake time of ",thread," is the same as ",previous)
	else
		previous = previous.value
		wakeindex:addto(entry, entry)
		waketime[thread] = time                                                     --[[VERBOSE]] verbose:threads("wake time of ",thread," was registered")
	end
	return previous or thread
end

local defer = findplace.defer
function findplace.delay(thread, time)
	return defer(thread, now()+time)
end



function schedule(thread, how, what)
	local place
	if how == nil then
		if thread == lastready then
			rescheduled = true
			return thread
		end
		place = placeof[lastready]                                                  --[[VERBOSE]] verbose:threads(thread, " will be scheduled for later execution")
	else
		place = findplace[how](thread, what)
		if place == nil then return end
		if thread == lastready then
			local previous = placeof[thread]
			if place == thread then
				lastready = previous
				return thread
			elseif place == previous then
				rescheduled = true
				return thread
			end
			lastready = previous
		end                                                                         --[[VERBOSE]] verbose:threads(thread, " will be scheduled after ",place)
	end
	local oldplace = placeof[thread]
	if oldplace ~= nil then
		return scheduled:movefrom(oldplace, place)
	end
	return scheduled:add(thread, place)
end

function unschedule(thread)
	if thread == lastready then
		lastready = placeof[lastready]
	elseif not cancelwake(thread) then
		cancelblock(thread)
	end                                                                           --[[VERBOSE]] verbose:threads(thread, " will be unscheduled")
	return scheduled:remove(thread)
end

function wakeall(signal, how, what)
	local thread = scheduled[signal]
	if thread ~= nil then
		local place
		if how == nil then
			place = placeof[lastready]
		else
			place = findplace[how](thread, what)
			if place == nil then return end
			if place == thread then return end
		end
		local last = placeof[signal]
		scheduled:movefrom(signal, place, last)
		scheduled:removefrom(signal)                                                --[[VERBOSE]] verbose:threads("all threads waiting for signal ",signal," are ready for execution")
		--if signalcanceled then signalcanceled(signal) end
		return thread, last
	end
end

function cancel(signal)                                                         --[[VERBOSE]] verbose:threads("cancel one thread waiting for signal ",signal)
	local thread = scheduled:removefrom(signal)
	if thread ~= nil then                                                         --[[VERBOSE]] verbose:threads(thread, " waiting for signal ",signal," was unscheduled")
		if scheduled[signal] == signal then
			scheduled:removefrom(signal)
			--if signalcanceled then signalcanceled(signal) end
		end
		return thread                                                               --[[VERBOSE]] else verbose:threads("no threads waiting signal ",signal)
	end
end



---
--@param current
--	thread that invoked the operation
--@param ...
--	operations parameters supplied by thread 'current'.
--
--@return scheduled
--	thread: thread that must be resumed next
--	false : indicates that a scheduled thread must be resumed next
--	nil   : indicates that the scheduling must stop completely
--@return ...
--	values to be passed to the thread that will be resume or returned by
--  'run' if 'scheduled == false' and there are no scheduled threads.
--
local yieldops = {                                                              --[[VERBOSE]] verbose = function() return verbose end,
	now = now,
	idle = idle,
	error = error,
	
	isscheduled = isscheduled,
	ready = ready,
	waiting = waiting,
	delayed = delayed,
	signals = signals,
	
	schedule = schedule,
	unschedule = unschedule,
	wakeall = wakeall,
	cancel = cancel,
}
for name, op in pairs(yieldops) do
	yieldops[name] = function (current, ...)
		return current, op(...)
	end
end

function yieldops.pause(current, ...)
	if current ~= lastready then
		scheduled:add(current, placeof[lastready])
	end                                                                           --[[VERBOSE]] verbose:threads(current," paused and will be resumed later")
	return false, ...
end

function yieldops.suspend(current, ...)
	if current == lastready and not rescheduled then
		lastready = placeof[lastready]
		scheduled:removefrom(lastready)
	end                                                                           --[[VERBOSE]] verbose:threads(current," suspended itself")
	return false, ...
end

local pause   = yieldops.pause
local suspend = yieldops.suspend

function yieldops.halt(current, ...)
	pause(current)                                                                --[[VERBOSE]] verbose:threads(current," requested halt of scheduling")
	return nil, ...
end

function yieldops.resume(current, thread, ...)                                  --[[VERBOSE]] verbose:threads(current," resumed ",thread)
	pause(current)
	return thread or false, ...
end

function yieldops.yield(current, thread, ...)                                   --[[VERBOSE]] verbose:threads(current," yielded to ",thread)
	suspend(current)
	return thread or false, ...
end

for name, findplace in pairs(findplace) do
	yieldops[name] = function(current, place, ...)                                --[[VERBOSE]] verbose:threads(current, " will ",name," for ",place)
		place = findplace(current, place)
		if place == nil then return current, ... end
		if current == lastready then
			lastready = placeof[lastready]
			scheduled:movefrom(lastready, place)
		else
			scheduled:add(current, place)
		end                                                                         --[[VERBOSE]] verbose:threads(current, " scheduled after ",place)
		return false, ...
	end
end



---
--@return nextwake
--	number: timestamp of the moment for the next sleeping thread to be waken
--	nil   : no more sleeping threads left
-- 
local function wakeupdelayed()
	local first = wakeindex:head()
	if first then
		local remains, time = wakeindex:cropuntil(now(), "orLater") -- exclusive
		if remains ~= first then
			local last = placeof[remains or first]
			scheduled:move(first, lastready, last)                                    --[[VERBOSE]] verbose:threads("delayed ",first," to ",last," are ready for execution")
		end
		return time
	end
end

local function dothread(thread, success, operation, ...)
	if status(thread) == "suspended" then                                         --[[VERBOSE]] verbose:threads(false, thread," yielded with operation ",operation)
		return yieldops[operation](thread, ...)
	end                                                                           --[[VERBOSE]] verbose:threads(false, thread,success and " finished successfully" or " raised an error")
	-- 'thread' has just finished and is dead now
	unschedule(thread)
	local trap = traps[thread]
	if trap then                                                                  --[[VERBOSE]] verbose:threads("executing trap of ",thread)
		return false, trap(thread, success, operation, ...)
	elseif not success then                                                       --[[VERBOSE]] verbose:threads("handling error of ",thread)
		error(thread, operation, ...)
	end
	return false, operation, ... -- resume next scheduled thread followed
end                            -- by the returned values

---
--@param thread
--	thread: resume the provided thread
--	false : resume next scheduled thread
--	nil   : halt the scheduling completely
--@param ...
--	values to be passed to the thread that will be resume or returned by
--  'run' if 'thread == false' and there are no scheduled threads.
--
--@return hasready
--	false: one resuming round has finished
--	nil  : resuming round was halted before completion
--@return ...
--	values yielded by the last thread resumed.
-- 
local function resumeready(thread, ...)
	if thread == false then
		lastready = scheduled[lastready] -- get successor
		rescheduled = false
		thread = lastready
	end
	if thread then                                                                --[[VERBOSE]] verbose:threads(true, "resuming ",thread)
		return resumeready(dothread(thread, resume(thread, ...)))
	end
	return thread, ...
end

--------------------------------------------------------------------------------
-- Control Functions -----------------------------------------------------------
--------------------------------------------------------------------------------

---
--@param thread
--	thread      : thread to be resumed first during the scheduling round
--	false or nil: indicates that a scheduled thread must be resumed first
--@param ...
--	values to be passed to the first resumed thread
--
--@return nextround
--	0     : there are threads ready for execution
--	number: timestamp of the moment when the round will have threads to schedule
--	false : no more threads to be scheduled, so no use for other round
--	nil   : scheduling was halted
--@return ...
--	values yielded by the last resumed thread
--
local function roundcont(thread, ...)
	local nextwake
	if thread == false then                                                       --[[VERBOSE]] verbose:scheduler(false, "scheduling round finished")
		if scheduled[false] ~= false then
			nextwake = 0                                                              --[[VERBOSE]] verbose:scheduler("threads are ready for execution")
		else
			thread, nextwake = wakeindex:head()
			if nextwake == nil then                                                   --[[VERBOSE]] verbose:scheduler("no more threads scheduled")
				nextwake = false                                                        --[[VERBOSE]] else verbose:scheduler("threads are delayed")
			end
		end                                                                         --[[VERBOSE]] else verbose:scheduler(false, "sheduling round was halted")
	end
	return nextwake, ...
end
function round(thread, ...)                                                      --[[VERBOSE]] verbose:scheduler(true, "scheduling round started")
	wakeupdelayed()
	return roundcont(resumeready(thread or lastready, ...))
end

---
--@param thread
--	thread      : thread to be resumed first during the scheduling
--	false or nil: indicates that a scheduled thread must be resumed first
--@param ...
--	values to be passed to the first resumed thread
--
--@return nextround
--	true : no more threads to be scheduled, so no use for other run
--	false: scheduling was halted
--@return ...
--	values yielded by the last resumed thread
--
local function runcont(nextround, ...)
	if nextround then
		if nextround > 0 then idle(nextround) end
		return run(lastready, ...)
	end
	return nextround == false, ...
end
function run(thread, ...)
	return runcont(round(thread, ...))
end

--------------------------------------------------------------------------------
-- Verbose Support -------------------------------------------------------------
--------------------------------------------------------------------------------

--[[VERBOSE]] local Viewer = _G.require "loop.debug.Viewer"
--[[VERBOSE]] local Verbose = _G.require "loop.debug.Verbose"
--[[VERBOSE]] verbose = Verbose{ viewer = Viewer{ labels = DefaultLabels } }
--[[VERBOSE]] verbose:newlevel{"threads"}
--[[VERBOSE]] verbose:newlevel{"scheduler"}
--[[VERBOSE]] verbose:newlevel{"state"}
--[[VERBOSE]] 
--[[VERBOSE]] 
--[[VERBOSE]] 
--[[VERBOSE]] local select = _G.select
--[[VERBOSE]] local copy = tabop.copy
--[[VERBOSE]] function verbose.custom:threads(...)
--[[VERBOSE]] 	local viewer = self.viewer
--[[VERBOSE]] 	local output = self.viewer.output
--[[VERBOSE]] 	local labels = self.viewer.labels
--[[VERBOSE]] 	
--[[VERBOSE]] 	for i = 1, select("#", ...) do
--[[VERBOSE]] 		local value = select(i, ...)
--[[VERBOSE]] 		if type(value) == "string" then
--[[VERBOSE]] 			output:write(value)
--[[VERBOSE]] 		elseif type(value) == "thread" then
--[[VERBOSE]] 			output:write("thread ",labels[value])
--[[VERBOSE]] 		else
--[[VERBOSE]] 			viewer:write(value)
--[[VERBOSE]] 		end
--[[VERBOSE]] 	end
--[[VERBOSE]] 	
--[[VERBOSE]] 	if self.flags.state then
--[[VERBOSE]] 		local missing = copy(scheduled)
--[[VERBOSE]] 		
--[[VERBOSE]] 		local newline = "\n"..viewer.prefix..viewer.indentation
--[[VERBOSE]] 		
--[[VERBOSE]] 		output:write(newline,"Ready  :")
--[[VERBOSE]] 		local sep = "  "
--[[VERBOSE]] 		for thread in scheduled:forward(false) do
--[[VERBOSE]] 			if missing[thread] == nil then
--[[VERBOSE]] 				output:write("<STATE CORRUPTION>")
--[[VERBOSE]] 				break
--[[VERBOSE]] 			end
--[[VERBOSE]] 			missing[thread] = nil
--[[VERBOSE]] 			if not thread then break end
--[[VERBOSE]] 			if thread == lastready then sep = " [" end
--[[VERBOSE]] 			output:write(sep,labels[thread])
--[[VERBOSE]] 			if     sep == " [" then sep = "] "
--[[VERBOSE]] 			elseif sep == "] " then sep = "  " end
--[[VERBOSE]] 		end
--[[VERBOSE]] 		if sep ~= "  " then output:write("]") end
--[[VERBOSE]] 		
--[[VERBOSE]] 		output:write(newline,"Delayed:")
--[[VERBOSE]] 		local start = now()
--[[VERBOSE]] 		local last = wakeindex:nextnode()
--[[VERBOSE]] 		local first = last and last.value
--[[VERBOSE]] 		while last ~= nil do
--[[VERBOSE]] 			local waketime = last.key
--[[VERBOSE]] 			output:write(" [",waketime-start,"]:")
--[[VERBOSE]] 			local next = wakeindex:nextnode(last)
--[[VERBOSE]] 			local limit = (next ~= nil) and next.value or first
--[[VERBOSE]] 			local thread = last.value
--[[VERBOSE]] 			repeat
--[[VERBOSE]] 				if missing[thread] == nil then
--[[VERBOSE]] 					output:write("<STATE CORRUPTION>")
--[[VERBOSE]] 					break
--[[VERBOSE]] 				end
--[[VERBOSE]] 				missing[thread] = nil
--[[VERBOSE]] 				output:write(" ",labels[thread])
--[[VERBOSE]] 				thread = scheduled[thread]
--[[VERBOSE]] 			until thread == limit
--[[VERBOSE]] 			last = next
--[[VERBOSE]] 		end
--[[VERBOSE]] 		
--[[VERBOSE]] 		output:write(newline,"Blocked:")
--[[VERBOSE]] 		while next(missing) ~= nil do
--[[VERBOSE]] 			local signalfound
--[[VERBOSE]] 			for signal in pairs(missing) do
--[[VERBOSE]] 				if signal and type(signal) ~= "thread" then
--[[VERBOSE]] 					signalfound = true
--[[VERBOSE]] 					output:write(newline,"  ",labels[signal],":")
--[[VERBOSE]] 					for thread in scheduled:forward(signal) do
--[[VERBOSE]] 						if missing[thread] == nil then
--[[VERBOSE]] 							output:write("<STATE CORRUPTION>")
--[[VERBOSE]] 							break
--[[VERBOSE]] 						end
--[[VERBOSE]] 						missing[thread] = nil
--[[VERBOSE]] 						if thread == signal then break end
--[[VERBOSE]] 						output:write(" ",labels[thread])
--[[VERBOSE]] 					end
--[[VERBOSE]] 				end
--[[VERBOSE]] 			end
--[[VERBOSE]] 			if not signalfound then
--[[VERBOSE]] 				output:write("<STATE CORRUPTION>")
--[[VERBOSE]] 				break
--[[VERBOSE]] 			end
--[[VERBOSE]] 		end
--[[VERBOSE]] 	end
--[[VERBOSE]] end

--------------------------------------------------------------------------------
-- End of Instantiation Code -------------------------------------------------
--------------------------------------------------------------------------------

	_G.setfenv(1, default) -- Lua 5.2:
	return attribs
end



--[[VERBOSE]] local string = _G.require "string"
--[[VERBOSE]] local strrep = string.rep
--[[VERBOSE]] local char = string.char
--[[VERBOSE]] local byte = string.byte
--[[VERBOSE]] local lastcode = byte("Z")
--[[VERBOSE]] local function nextstr(text)
--[[VERBOSE]] 	for i = #text, 1, -1 do
--[[VERBOSE]] 		local code = text:byte(i)
--[[VERBOSE]] 		if code < lastcode then
--[[VERBOSE]] 			return text:sub(1,i-1)..char(code+1)..strrep("A", #text-i)
--[[VERBOSE]] 		end
--[[VERBOSE]] 	end
--[[VERBOSE]] 	return strrep("A", #text+1)
--[[VERBOSE]] end
--[[VERBOSE]] 
--[[VERBOSE]] local tostring = _G.tostring
--[[VERBOSE]] local lastused = ""
--[[VERBOSE]] DefaultLabels = memoize(function(value)
--[[VERBOSE]] 	if type(value) == "thread" then
--[[VERBOSE]] 		lastused = nextstr(lastused)
--[[VERBOSE]] 		return lastused
--[[VERBOSE]] 	end
--[[VERBOSE]] 	return tostring(value)
--[[VERBOSE]] end)



setmetatable(new(_M), { __call = function(_, attribs) return new(attribs) end })
