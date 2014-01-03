-- Project: CoThread
-- Release: 1.0 beta
-- Title  : Cooperative Threads Scheduler based on Coroutines
-- Author : Renato Maia <maia@inf.puc-rio.br>

local _G = require "_G"
local luaerror = _G.error
local next = _G.next
local select = _G.select
local setmetatable = _G.setmetatable

local coroutine = require "coroutine"
local status = coroutine.status
local resume = coroutine.resume
local yield = coroutine.yield

local BiCyclicSets = require "loop.collection.BiCyclicSets"

local traceback = _G.debug and
                  	_G.debug.traceback or
                  	function(_, err) return err end

local function dummy() end
local function error(thread, errmsg)
	luaerror(traceback(thread, errmsg))
end
local function yielderror(thread)
	error(thread, "bad yield operation")
end

local WeakKeys = {__mode = "k"}
local IndexDummyFunc = {__index = function() return dummy end}
local IndexYieldError = {__index = function() return yielderror end}

local function trappedfunc(func, traps)
	return function(key, ...)
		local trap = traps[key]
		if trap ~= nil then
			traps[key] = nil
			trap(key, ...)
		end
		return func(key, ...)
	end
end

--------------------------------------------------------------------------------
-- Verbose Support -------------------------------------------------------------
--------------------------------------------------------------------------------

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
--[[VERBOSE]] local lastused = {thread="",userdata=""}
--[[VERBOSE]] local DefaultLabels = setmetatable({}, {
--[[VERBOSE]] 	__mode = "k",
--[[VERBOSE]] 	__index = function(self, value)
--[[VERBOSE]] 		local type = type(value)
--[[VERBOSE]] 		local last = lastused[type]
--[[VERBOSE]] 		if last ~= nil then
--[[VERBOSE]] 			last = nextstr(last)
--[[VERBOSE]] 			lastused[type] = last
--[[VERBOSE]] 			self[value] = last
--[[VERBOSE]] 			return last
--[[VERBOSE]] 		end
--[[VERBOSE]] 		return tostring(value)
--[[VERBOSE]] 	end,
--[[VERBOSE]] })

--------------------------------------------------------------------------------
-- Begin of Instantiation Code -------------------------------------------------
--------------------------------------------------------------------------------

local function new(cothread)
	local _ENV = {}
	if _G._VERSION=="Lua 5.1" then _G.setfenv(1,_ENV) end -- Lua 5.1 compatibility
	
	if cothread == nil then cothread = {} end

--------------------------------------------------------------------------------
-- Initialization Code ---------------------------------------------------------
--------------------------------------------------------------------------------

lastready = nil -- Token marking the head of the list of threads ready
                -- for execution. When it is not 'false' it also
                -- indicate the last resumed thread from the list of
                -- threads ready for execution.
scheduled = BiCyclicSets()    -- Table containing all scheduled threads.
placeof = scheduled:reverse() -- It is organized as disjoint sets, which
                              -- values are arranged in cyclic order.
if cothread.traps == nil then
	cothread.traps = setmetatable({}, {__mode = "k"}) -- Table mapping threads to
	                                                  -- the function that must be
	                                                  -- executed when the thread
	                                                  -- finishes.
end
if cothread.error == nil then
	cothread.error = error -- function that handles errors raised by threads a
	                       -- defined trap.
end

---
--@param thread
--	thread being scheduled
--@param ...
--	additional parameters passed to operation 'schedule(thread, "name", ...)' or
--	on 'yield("name", ...)'
--
--@return place
--	thread or signal in 'scheduled' where the thread must be placed, or nil if
--	no suitable place was found
--@return ...
--	values to be passed as returned values of this operation to the op. caller
--
local findplace = setmetatable({}, IndexDummyFunc)

---
--@param current
--	thread that invoked the operation
--@param ...
--	operations parameters supplied by thread 'current'.
--
--@return next
--	thread: thread that must be resumed next or nil to resume a scheduled one
--@return ...
--	values to be passed to the thread that will be resumed or returned by
--  'run' if 'scheduled == false' and there are no scheduled threads.
--
local yieldops = setmetatable({}, IndexYieldError)

--------------------------------------------------------------------------------
-- Scheduling Implementation ---------------------------------------------------
--------------------------------------------------------------------------------

local function removedataof(thread, place)
	if lastready == thread then
		lastready = (thread ~= place) and place or nil
	end
end

function reschedule(thread, place)
	local oldplace = placeof[thread]
	if oldplace == nil then
		scheduled:add(thread, place)
	else
		removedataof(thread, oldplace)
		scheduled:movefrom(oldplace, place)
	end
end

local function unschedule(thread)
	local place = placeof[thread]
	if place ~= nil then
		removedataof(thread, place)                                                 --[[VERBOSE]] verbose:threads(thread, " unscheduled")
		return scheduled:remove(thread)                                             --[[VERBOSE]],verbose:state()
	end
end

local function nextready()
	lastready = scheduled[lastready] -- get successor
	return lastready
end

local function dothread(thread, success, operation, ...)
	if status(thread) == "suspended" then                                         --[[VERBOSE]] verbose:threads(false, thread," yielded with operation ",operation)
		return yieldops[operation](thread, ...)
	end                                                                           --[[VERBOSE]] verbose:threads(false, thread,success and " finished successfully" or " raised an error")
	-- 'thread' has just finished and is dead now
	unschedule(thread)
	local trap = cothread.traps[thread]
	if trap ~= nil then                                                           --[[VERBOSE]] verbose:threads("executing trap of ",thread)
		return trap(thread, success, operation, ...)
	elseif not success then                                                       --[[VERBOSE]] verbose:threads("handling error of ",thread)
		return cothread.error(thread, operation, ...)
	end
	return nil, operation, ... -- resume next scheduled thread with the results
end

local function dostep(thread, ...)
	if thread ~= nil then                                                         --[[VERBOSE]] verbose:threads(true, "resuming ",thread)
		return dostep(dothread(thread, resume(thread, ...)))
	end                                                                           --[[VERBOSE]] verbose:scheduler(false, "scheduling step ended")
	return ...
end

local function dorun(...)
	local thread = nextready()
	if thread ~= nil then                                                         --[[VERBOSE]] verbose:scheduler(true, "scheduling step restarted")
		return dorun(dostep(thread, ...))
	end
	return ...
end

--------------------------------------------------------------------------------
-- Plugin Operations -----------------------------------------------------------
--------------------------------------------------------------------------------

function yieldop(name, op)
	yieldops[name] = op
	cothread[name] = function(...)
		return yield(name, ...)
	end
	return op
end

function scheduleop(name, finder)
	findplace[name] = finder
	yieldop(name, function(current, ...)
		return select(2, finder(current, ...))
	end)
	return finder
end

function moduleop(name, op, yieldable)
	_ENV[name] = op
	cothread[name] = op
	if yieldable == "yieldable" then
		yieldops[name] = function (current, ...)
			return current, op(...)
		end
	end
	return op
end

--------------------------------------------------------------------------------
-- Scheduling Operations -------------------------------------------------------
--------------------------------------------------------------------------------

moduleop("unschedule", function(...)
	return unschedule(...)
end, "yieldable")

moduleop("schedule", function(thread, how, ...)
	if how == nil then how = "last" end
	return findplace[how](thread, ...)
end, "yieldable")



scheduleop("next", function(thread, ...)
	if lastready == thread then
		lastready = placeof[lastready]
	else
		reschedule(thread, lastready)
		if lastready == nil then
			lastready = thread
		end
	end                                                                           --[[VERBOSE]] verbose:threads(thread," scheduled as next ready thread");verbose:state()
	return thread, ...
end)

scheduleop("last", function(thread, ...)
	if lastready ~= thread then
		reschedule(thread, lastready)
		lastready = thread
	end                                                                           --[[VERBOSE]] verbose:threads(thread," scheduled as last ready thread");verbose:state()
	return thread, ...
end)

scheduleop("after", function(thread, place, ...)
	if scheduled[place] ~= nil then
		if place ~= thread then
			reschedule(thread, place)
			if lastready == place then
				lastready = thread
			end
		end                                                                         --[[VERBOSE]] verbose:threads(thread," scheduled after ready thread ",place);verbose:state()
		return thread, ...
	end
	return nil, ...
end)

yieldop("yield", function(current, ...)                                         --[[VERBOSE]] verbose:threads(current," yielded")
	return ...
end)

yieldop("suspend", function(current, ...)                                       --[[VERBOSE]] verbose:threads(current," suspended itself")
	unschedule(current)
	return ...
end)

--------------------------------------------------------------------------------
-- Scheduling Control ----------------------------------------------------------
--------------------------------------------------------------------------------

---
--@param thread
--	thread      : thread to be resumed first during this step
--	false or nil: indicates that a scheduled thread must be resumed first
--@param ...
--	values to be passed to the first resumed thread
--
--@return continue
--	true : one resuming step has finished
--	false: resuming step indicated a halting request
--@return ...
--	values yielded by the last resumed thread
--
moduleop("step", function(thread, ...)                                          --[[VERBOSE]] verbose:scheduler(true, "scheduling step started")
	return dostep(thread or nextready(), ...)
end)

---
--@param thread
--	thread      : thread to be resumed first during the scheduling
--	false or nil: indicates that a scheduled thread must be resumed first
--@param ...
--	values to be passed to the first resumed thread
--
--@return continue
--	true : no more threads to be scheduled, so no use for other run
--	false: scheduling was halted
--@return ...
--	values yielded by the last resumed thread
--
moduleop("run", dorun)

do
	local backup = nextready
	local function trap()                                                         --[[VERBOSE]] verbose:scheduler(false, "scheduling halted")
		nextready = backup
	end
	
	moduleop("requesthalt", function()                                            --[[VERBOSE]] verbose:scheduler("scheduling halt requested")
		nextready = trap
	end, "yieldable")
	
	moduleop("cancelhalt", function()                                             --[[VERBOSE]] verbose:scheduler("scheduling halt canceled")
		if nextready == trap then
			nextready = backup
			return true
		end
		return false
	end, "yieldable")
end

--------------------------------------------------------------------------------
-- Scheduling Introspection ----------------------------------------------------
--------------------------------------------------------------------------------

function nextthread(ending, previous)
	if previous ~= ending then
		return scheduled[previous or ending]
	end
end

moduleop("allready", function()
	return nextthread, lastready
end, "yieldable")

moduleop("hasready", function()
	return lastready ~= nil
end, "yieldable")

moduleop("isscheduled", function(thread)
	return scheduled[thread] ~= nil
end, "yieldable")

yieldop("running", function(current) return current, current end)               --[[VERBOSE]] yieldop("verbose", function(current) return current, verbose end)

--------------------------------------------------------------------------------
-- Plugin Support --------------------------------------------------------------
--------------------------------------------------------------------------------

do
	local reschedulers = setmetatable({}, WeakKeys)
	local backup = removedataof
	local trapped
	function onreschedule(thread, trap)
		reschedulers[thread] = trap
		if trap ~= nil then
			removedataof = trapped
		elseif next(reschedulers) == nil then
			removedataof = backup
		end
	end
	trapped = trappedfunc(backup, reschedulers)
end

do
	local unschedulers = setmetatable({}, WeakKeys)
	local backup = unschedule
	local trapped
	function onunschedule(thread, trap)
		unschedulers[thread] = trap
		if trap ~= nil then
			unschedule = trapped
		elseif next(unschedulers) == nil then
			unschedule = backup
		end
	end
	trapped = trappedfunc(backup, unschedulers)
end

loaded = {}
moduleop("plugin", function(plugin)
	if loaded[plugin] == nil then
		loaded[plugin] = true
		plugin(_ENV, cothread)
	end
end, "yieldable")

--------------------------------------------------------------------------------
-- Verbose Support -------------------------------------------------------------
--------------------------------------------------------------------------------

--[[VERBOSE]] local pairs = _G.pairs
--[[VERBOSE]] local type = _G.type
--[[VERBOSE]] local Viewer = _G.require "loop.debug.Viewer"
--[[VERBOSE]] local Verbose = _G.require "loop.debug.Verbose"
--[[VERBOSE]] verbose = Verbose{
--[[VERBOSE]] 	viewer = Viewer{ labels = DefaultLabels },
--[[VERBOSE]] }
--[[VERBOSE]] verbose:newlevel{"threads"}
--[[VERBOSE]] verbose:newlevel{"scheduler"}
--[[VERBOSE]] verbose:newlevel{"state"}
--[[VERBOSE]] 
--[[VERBOSE]] local select = _G.select
--[[VERBOSE]] local string = _G.require("string")
--[[VERBOSE]] local format = string.format
--[[VERBOSE]] local tabop = _G.require("loop.table")
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
--[[VERBOSE]] end
--[[VERBOSE]] 	
--[[VERBOSE]] local stateloggers = {}
--[[VERBOSE]] function statelogger(name, logger)
--[[VERBOSE]] 	stateloggers[name] = logger
--[[VERBOSE]] end
--[[VERBOSE]] function verbose.custom:state(...)
--[[VERBOSE]] 	local viewer = self.viewer
--[[VERBOSE]] 	local output = self.viewer.output
--[[VERBOSE]] 	local labels = self.viewer.labels
--[[VERBOSE]] 	local missing = copy(scheduled)
--[[VERBOSE]] 	local newline = "\n"..viewer.prefix
--[[VERBOSE]] 	
--[[VERBOSE]] 	output:write("Ready  :")
--[[VERBOSE]] 	for thread in scheduled:forward(lastready) do
--[[VERBOSE]] 		if missing[thread] == nil then
--[[VERBOSE]] 			output:write("<STATE CORRUPTION>")
--[[VERBOSE]] 			break
--[[VERBOSE]] 		end
--[[VERBOSE]] 		missing[thread] = nil
--[[VERBOSE]] 		output:write(" ",labels[thread])
--[[VERBOSE]] 		if thread == lastready then break end
--[[VERBOSE]] 	end
--[[VERBOSE]] 	
--[[VERBOSE]] 	for name, logger in pairs(stateloggers) do
--[[VERBOSE]] 		output:write(newline, format("%-7.7s:", name))
--[[VERBOSE]] 		logger(self, missing, newline)
--[[VERBOSE]] 	end
--[[VERBOSE]] end
--[[VERBOSE]] verbose:flag("print", true)
--[[VERBOSE]] cothread.verbose = verbose

--------------------------------------------------------------------------------
-- Inspection Support ----------------------------------------------------------
--------------------------------------------------------------------------------

--[[DEBUG]] local inspector = _G.require "inspector"
--[[DEBUG]] yieldop("inspect", function(current)
--[[DEBUG]] 	return current, inspector.activate(2)
--[[DEBUG]] end)

--------------------------------------------------------------------------------
-- End of Instantiation Code -------------------------------------------------
--------------------------------------------------------------------------------

	return cothread
end

return setmetatable(new(), { __call = function(_, ...) return new(...) end })
