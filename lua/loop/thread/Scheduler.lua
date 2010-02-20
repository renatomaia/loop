--------------------------------------------------------------------------------
-- Project: LOOP Class Library                                                --
-- Release: 2.3 beta                                                          --
-- Title  : Cooperative Threads Scheduler based on Coroutines                 --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------

local _G           = require "_G"
local coroutine    = require "coroutine"
local os           = require "os"
local oo           = require "loop.base"
local CyclicSets   = require "loop.collection.CyclicSets"
local BiCyclicSets = require "loop.collection.BiCyclicSets"
local SortedMap    = require "loop.collection.SortedMap"

local luaerror     = _G.error
local assert       = _G.assert
local getmetatable = _G.getmetatable
local luapcall     = _G.pcall
local rawget       = _G.rawget
local newthread    = coroutine.create
local runthread    = coroutine.resume
local yield        = coroutine.yield
local status       = coroutine.status
local running      = coroutine.running
local gettime      = os.time
local difftime     = os.difftime

local StartTime  = gettime()
local WeakValues = oo.class{ __mode = "v" }
local WeakKeys   = oo.class{ __mode = "k" }
local HaltKey    = _G.newproxy()
local traceback  = _G.debug and
                   	_G.debug.traceback or
                   	function(_, err) return err end

--[[VERBOSE]] local type        = _G.type
--[[VERBOSE]] local rawget      = _G.rawget
--[[VERBOSE]] local select      = _G.select
--[[VERBOSE]] local tostring    = _G.tostring
--[[VERBOSE]] local string      = require "string"
--[[VERBOSE]] local table       = require "table"
--[[VERBOSE]] local math        = require "math"
--[[VERBOSE]] local tabop       = require "loop.table"
--[[VERBOSE]] local ObjectCache = require "loop.collection.ObjectCache"
--[[VERBOSE]] local Viewer      = require "loop.debug.Viewer"
--[[VERBOSE]] local Verbose     = require "loop.debug.Verbose"
--[[DEBUG]]   local Inspector   = require "loop.debug.Inspector"

module(..., oo.class)

--------------------------------------------------------------------------------
-- Coroutine Compatible pcall --------------------------------------------------
--------------------------------------------------------------------------------

-- NOTE:[maia] Contains all nested pcall chains as disjoint cyclic sets. The
--             ordering is from the upper call to the inner call. Since the
--             ordering is cyclic, the current pcall (inner call) is succeeded
--             by the original calling pcall (upper call), thus it is fast to
--             find which coroutine an yield in the running coroutine will be
--             propagated to due to a nested pcall chain.
local NestedPCalls = CyclicSets()

local function resumepcall(pcall, success, ...)
	if status(pcall) == "suspended" then
		return resumepcall(pcall, runthread(pcall, yield(...)))
	else
		local current = running()       
		NestedPCalls:removefrom(current)                                            --[[VERBOSE]] verbose:copcall(false, "protected call finished in ",NestedPCalls:successor(current))
		if NestedPCalls:successor(current) == current then
			NestedPCalls:removefrom(current)
		end
		return success, ...
	end
end

function pcall(func, ...)
	local thread = running()
	if thread then
		local isluafunc, pcall = luapcall(newthread, func)
		if isluafunc then
			NestedPCalls:add(pcall, thread)                                           --[[VERBOSE]] verbose:copcall(true, "new protected call in ",NestedPCalls:successor(pcall))
			return resumepcall(pcall, runthread(pcall, ...))
		end
	end
	return luapcall(func, ...)
end

function getpcall()
	return pcall
end

--------------------------------------------------------------------------------
-- Initialization Code ---------------------------------------------------------
--------------------------------------------------------------------------------

function __init(class, self)
	self = oo.rawnew(class, self)
	if rawget(self, "threads"  ) == nil then self.threads   = BiCyclicSets() end
	if rawget(self, "wakeindex") == nil then self.wakeindex = SortedMap()    end
	if rawget(self, "wakeentry") == nil then self.wakeentry = WeakValues()   end
	if rawget(self, "traps"    ) == nil then self.traps     = WeakKeys()     end
	if rawget(self, "current"  ) == nil then self.current   = false          end
	if rawget(self, "scheduled") == nil then self.scheduled = false          end
	self.threads:add(false)
	return self
end
__init(oo.classof(_M), _M)

--------------------------------------------------------------------------------
-- Internal Functions ----------------------------------------------------------
--------------------------------------------------------------------------------

function checkcurrent(self)
	local current = self.current
	local thread = running()
	assert(current,
		"attempt to call scheduler operation out of a scheduled thread context.")
	assert(current == thread or NestedPCalls:successor(thread) == current,
		"inconsistent internal state, current scheduled thread is not running.")
	return current
end

function resumeall(self, success, ...)                                          --[[VERBOSE]] local verbose = self.verbose
	local continue = (... ~= HaltKey)
	if continue then
		local threads = self.threads
		local scheduled = self.scheduled
		local current = self.current
		if current then                                                             --[[VERBOSE]] verbose:threads(false, current," yielded")
			if status(current) == "dead" then                                         --[[VERBOSE]] verbose:threads(current," has finished")
				self:remove(current)
				self.current = false
				local trap = self.traps[current]
				if trap then                                                            --[[VERBOSE]] verbose:threads(true, "executing trap for ",current)
					trap(self, current, success, ...)                                     --[[VERBOSE]] verbose:threads(false)
				elseif not success then                                                 --[[VERBOSE]] verbose:threads("uncaptured error on ",current)
					self:error(current, ...)
				end
			end                                                                       --[[VERBOSE]] else verbose:scheduler(true, "resuming running threads")
		end
		current = threads:successor(self.scheduled)
		if current then
			self.scheduled = current
			self.current = current                                                    --[[VERBOSE]] verbose:threads(true, "resuming ",current)
			return self:resumeall(runthread(current, ...))
		end
		self.scheduled = false
		continue = nil
	end                                                                           --[[VERBOSE]] verbose:scheduler(false, "running threads resumed")
	self.current = false
	return continue
end

function wakeupall(self)                                                        --[[VERBOSE]] local verbose = self.verbose
	local wakeindex = self.wakeindex
	local first = wakeindex:head()
	if first then                                                                  --[[VERBOSE]] verbose:scheduler(true, "waking sleeping threads up")
		local remains, time = wakeindex:cropuntil(self:time(), true)
		if first ~= remains then
			local threads = self.threads
			local last = threads:predecessor(remains or first)
			threads:move(first, self.scheduled, last)                                 --[[VERBOSE]] verbose:threads("some sleeping threads woke up")
		end                                                                         --[[VERBOSE]] verbose:scheduler(false, "sleeping threads waken")
		return time
	end
end

--------------------------------------------------------------------------------
-- All expected cases:
--
-- Arrows indicate changes performed by the method.
-- No arrows means no change.
--
-- wakeentry = { ... }
-- wakeindex = { ... }
-- threads   = [ ... ]
--
-- wakeentry = { ... [thread] = entry }  --> { ... }
-- wakeindex = { ... }
-- threads   = [ ... ]
--
-- wakeentry = { ... [thread]    = entry }  --> { ... }
-- wakeindex = { ... [entry.key] = thread } --> { ... }
-- threads   = [ ... thread ]
--
-- wakeentry = { ... [thread]    = entry  } --> { ... [nextthread] = entry      }
-- wakeindex = { ... [entry.key] = thread } --> { ... [entry.key]  = nextthread }
-- threads   = [ ... thread, nextthread... ]
--
-- wakeentry = { ... [thread]    = entry , [nextentry.value] = nextentry...       } --> { ... [nextentry.value] = nextentry...       }
-- wakeindex = { ... [entry.key] = thread, [nextentry.key]   = nextentry.value... } --> { ... [nextentry.key]   = nextentry.value... }
-- threads   = [ ... thread, nextentry.value... ]
--
-- wakeentry = { ... [thread]    = entry , [nextentry.value] = nextentry       } --> { [nextthread] = entry     , [nextentry.value] = nextentry       }
-- wakeindex = { ... [entry.key] = thread, [nextentry.key]   = nextentry.value } --> { [entry.key]  = nextthread, [nextentry.key]   = nextentry.value }
-- threads   = [ ... thread, nextthread..nextentry.value... ]
--
function cancelwake(self, thread)                                               --[[VERBOSE]] local verbose = self.verbose
	local wakeentry = self.wakeentry
	local entry = wakeentry[thread]
	if entry then -- 'thread' *may* be sleeping.
		local wakeindex = self.wakeindex
		local path = {}
		local found = wakeindex:findnode(entry.key, path)
		if found == entry then -- yes, it is sleeping.
			local nextentry = wakeindex:nextto(entry)
			local nextthread = self.threads:successor(thread)
			if (nextentry and nextentry.value == nextthread) -- only one in this entry
			or (nextthread == wakeindex:head())            -- the last in sleeping set
			then -- no other thread is waiting here
				wakeindex:removefrom(entry, path)
			else -- other thread is waiting to wake at the same time
				entry.value = nextthread
				wakeentry[nextthread] = entry
			end
		end
		wakeentry[thread] = nil
	end
end

--------------------------------------------------------------------------------
-- Customizable Behavior -------------------------------------------------------
--------------------------------------------------------------------------------

function time(self)
	return difftime(gettime(), StartTime)
end

function idle(self, timeout)                                                    --[[VERBOSE]] local verbose = self.verbose; verbose:scheduler(true, "starting busy-waiting until ",timeout)
	repeat until self:time() > timeout                                            --[[VERBOSE]] verbose:scheduler(false, "busy-waiting ended")
end

function error(self, thread, errmsg)
	luaerror(traceback(thread, errmsg))
end

--------------------------------------------------------------------------------
-- Exported API ----------------------------------------------------------------
--------------------------------------------------------------------------------

function register(self, thread, previous)                                       --[[VERBOSE]] local verbose = self.verbose; verbose:threads("registering ",thread)
	local threads = self.threads
	if previous == nil then previous = threads:predecessor(false) end
	return threads:add(thread, previous)
end

function remove(self, thread)                                                   --[[VERBOSE]] local verbose = self.verbose; verbose:threads("removing ",thread)
	local threads = self.threads
	if thread == self.scheduled then
		self.scheduled = threads:predecessor(thread)
	end
	self:cancelwake(thread)
	return threads:remove(thread)
end

function suspend(self, time, ...)                                               --[[VERBOSE]] local verbose = self.verbose
	local current = self:checkcurrent()
	local threads = self.threads
	if current == self.scheduled then
		self.scheduled = threads:predecessor(current)
	end
	if time == nil then
		threads:remove(current)                                                     --[[VERBOSE]] verbose:threads(current," suspended")
	elseif time > 0 then
		local wakeindex = self.wakeindex
		time = self:time() + time
		local entry = { key = time, value = current }
		local found, previous = wakeindex:findnode(time, entry)
		if found then
			previous = found.value
		else
			previous = previous.value
			wakeindex:addto(entry, entry)
			self.wakeentry[current] = entry
		end
		threads:move(current, previous)                                             --[[VERBOSE]] verbose:threads(current," waiting until instant ",time)
	end
	return yield(...)
end

function resume(self, thread, ...)                                              --[[VERBOSE]] local verbose = self.verbose
	self:checkcurrent()
	local threads = self.threads
	local scheduled = self.scheduled
	if thread == scheduled then
		self.scheduled = threads:predecessor(scheduled)
	else
		local place = threads:predecessor(thread)
		if place == nil then
			threads:add(thread, scheduled)                                          --[[VERBOSE]] verbose:threads("resuming unregistered ",thread)
		else
			self:cancelwake(thread)
			threads:movefrom(place, scheduled)                                        --[[VERBOSE]] verbose:threads("resuming registered ",thread)
		end
	end
	return yield(...)
end

function start(self, func, ...)                                                 --[[VERBOSE]] local verbose = self.verbose
	self:checkcurrent()
	self.threads:add(newthread(func), self.scheduled)                             --[[VERBOSE]] verbose:threads("starting ",self.threads:successor(self.current))
	return yield(...)
end

function halt(self)
	local current = self:checkcurrent()
	local scheduled = self.scheduled
	if current == scheduled then
		self.scheduled = self.threads:predecessor(scheduled)
	end
	return yield(HaltKey)
end

function wait(self, signal, ...)                                                --[[VERBOSE]] local verbose = self.verbose
	local current = self:checkcurrent()
	local threads = self.threads
	if current == self.scheduled then
		local previous = threads:predecessor(current)
		self.scheduled = previous
		threads:movefrom(previous, signal)
	else
		threads:add(current, signal)
	end
	return yield(...)
end

function notifyall(self, signal, ...)                                           --[[VERBOSE]] local verbose = self.verbose
	self:checkcurrent()
	local threads = self.threads
	threads:movefrom(signal, self.scheduled, threads:predecessor(signal))
	threads:removefrom(signal)
	return yield(...)
end

function notify(self, signal, ...)                                              --[[VERBOSE]] local verbose = self.verbose
	self:checkcurrent()
	local threads = self.threads
	threads:movefrom(signal, self.scheduled)
	if threads:successor(signal) == signal then
		threads:removefrom(signal)
	end
	return yield(...)
end

function cancel(self, signal)                                                   --[[VERBOSE]] local verbose = self.verbose
	return self.threads:removeall(signal)
end

--------------------------------------------------------------------------------
-- Control Functions -----------------------------------------------------------
--------------------------------------------------------------------------------

function step(self, ...)                                                        --[[VERBOSE]] local verbose = self.verbose; verbose:scheduler(true, "performing scheduling step")
	local nextrun = self:resumeall(nil, ...)
	local nextwake = self:wakeupall()                                             --[[VERBOSE]] verbose:scheduler(false, "scheduling step performed")
	if self.threads[false] ~= false then
		return 0
	elseif nextrun == nil then
		return nextwake
	end
end

function run(self, ...)                                                         --[[VERBOSE]] local verbose = self.verbose; verbose:scheduler(true, "running scheduler")
	local nextstep = self:step(...)
	if nextstep then
		if nextstep > 0 then self:idle(nextstep) end                                --[[VERBOSE]] verbose:scheduler(false, "reissue scheduling")
		return self:run()
	end                                                                           --[[VERBOSE]] verbose:scheduler(false, "no thread pending scheduling or scheduler halted")
end

--------------------------------------------------------------------------------
-- Verbose Support -------------------------------------------------------------
--------------------------------------------------------------------------------

--[[VERBOSE]] verbose = Verbose{
--[[VERBOSE]] 	viewer = Viewer{
--[[VERBOSE]] 		labels = ObjectCache{ current = 0 }
--[[VERBOSE]] 	}
--[[VERBOSE]] }
--[[VERBOSE]] 
--[[VERBOSE]] local LabelStart = string.byte("A")
--[[VERBOSE]] function verbose.viewer.labels:retrieve(value)
--[[VERBOSE]] 	if type(value) == "thread" then
--[[VERBOSE]] 		local id = self.current
--[[VERBOSE]] 		local label = {}
--[[VERBOSE]] 		repeat
--[[VERBOSE]] 			label[#label+1] = LabelStart + (id % 26)
--[[VERBOSE]] 			id = math.floor(id / 26)
--[[VERBOSE]] 		until id <= 0
--[[VERBOSE]] 		self.current = self.current + 1
--[[VERBOSE]] 		value = string.char(table.unpack(label))
--[[VERBOSE]] 	end
--[[VERBOSE]] 	return tostring(value)
--[[VERBOSE]] end
--[[VERBOSE]] 
--[[VERBOSE]] verbose.groups.concurrency = { "scheduler", "threads", "copcall" }
--[[VERBOSE]] verbose:newlevel{"threads"}
--[[VERBOSE]] verbose:newlevel{"scheduler"}
--[[VERBOSE]] verbose:newlevel{"copcall"}
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
--[[VERBOSE]] 			output:write("thread ", labels[value], "[", tostring(value):match("%l+: (.+)"), "]")
--[[VERBOSE]] 		else
--[[VERBOSE]] 			viewer:write(value)
--[[VERBOSE]] 		end
--[[VERBOSE]] 	end
--[[VERBOSE]] 	
--[[VERBOSE]] 	local scheduler = rawget(self, "schedulerdetails")
--[[VERBOSE]] 	if scheduler then
--[[VERBOSE]] 		local threads = scheduler.threads
--[[VERBOSE]] 		local wakeindex = scheduler.wakeindex
--[[VERBOSE]] 		local missing = tabop.copy(threads)
--[[VERBOSE]] 		missing.back = nil
--[[VERBOSE]] 
--[[VERBOSE]] 		local newline = "\n"..viewer.prefix..viewer.indentation
--[[VERBOSE]] 
--[[VERBOSE]] 		output:write(newline,"Ready  :")
--[[VERBOSE]] 		local sep = "  "
--[[VERBOSE]] 		for thread in threads:forward(false) do
--[[VERBOSE]] 			if missing[thread] == nil then
--[[VERBOSE]] 				output:write("<STATE CORRUPTION>")
--[[VERBOSE]] 				break
--[[VERBOSE]] 			end
--[[VERBOSE]] 			missing[thread] = nil
--[[VERBOSE]] 			if not thread then break end
--[[VERBOSE]] 			if thread == self.current then sep = " [" end
--[[VERBOSE]] 			output:write(sep,labels[thread])
--[[VERBOSE]] 			if     sep == " [" then sep = "] "
--[[VERBOSE]] 			elseif sep == "] " then sep = "  " end
--[[VERBOSE]] 		end
--[[VERBOSE]] 		if sep ~= "  " then output:write("]") end
--[[VERBOSE]] 		
--[[VERBOSE]] 		output:write(newline,"Delayed:")
--[[VERBOSE]] 		local start = scheduler:time()
--[[VERBOSE]] 		local last = wakeindex:nextto()
--[[VERBOSE]] 		local first = last and last.value
--[[VERBOSE]] 		while last ~= nil do
--[[VERBOSE]] 			local waketime = last.key
--[[VERBOSE]] 			output:write(" [",waketime-start,"]:")
--[[VERBOSE]] 			local next = wakeindex:nextto(last)
--[[VERBOSE]] 			local limit = (next ~= nil) and next.value or first
--[[VERBOSE]] 			local thread = last.value
--[[VERBOSE]] 			repeat
--[[VERBOSE]] 				if missing[thread] == nil then
--[[VERBOSE]] 					output:write("<STATE CORRUPTION>")
--[[VERBOSE]] 					break
--[[VERBOSE]] 				end
--[[VERBOSE]] 				missing[thread] = nil
--[[VERBOSE]] 				output:write(" ",labels[thread])
--[[VERBOSE]] 				thread = threads[thread]
--[[VERBOSE]] 			until thread == limit
--[[VERBOSE]] 			last = next
--[[VERBOSE]] 		end
--[[VERBOSE]] 		
--[[VERBOSE]] 		output:write(newline,"Blocked:")
--[[VERBOSE]] 		while _G.next(missing) ~= nil do
--[[VERBOSE]] 			output:write(newline,"  ")
--[[VERBOSE]] 			local signalfound
--[[VERBOSE]] 			for signal in pairs(missing) do
--[[VERBOSE]] 				if signal and type(signal) ~= "thread" then
--[[VERBOSE]] 					signalfound = true
--[[VERBOSE]] 					output:write(labels[signal],":")
--[[VERBOSE]] 					for thread in threads:forward(signal) do
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
--[[VERBOSE]] verbose.custom.copcall = verbose.custom.threads
--[[VERBOSE]] 
--[[DEBUG]] verbose.I = Inspector{ viewer = verbose.viewer }
--[[DEBUG]] function verbose.inspect:debug() self.I:stop(4) end
--[[DEBUG]] verbose:flag("debug", true)
