--------------------------------------------------------------------------------
---------------------- ##       #####    #####   ######  -----------------------
---------------------- ##      ##   ##  ##   ##  ##   ## -----------------------
---------------------- ##      ##   ##  ##   ##  ######  -----------------------
---------------------- ##      ##   ##  ##   ##  ##      -----------------------
---------------------- ######   #####    #####   ##      -----------------------
----------------------                                   -----------------------
----------------------- Lua Object-Oriented Programming ------------------------
--------------------------------------------------------------------------------
-- Project: LOOP Class Library                                                --
-- Release: 2.3 beta                                                          --
-- Title  : Cooperative Threads Scheduler based on Coroutines                 --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------

local global       = require "_G"
local coroutine    = require "coroutine"
local os           = require "os"
local oo           = require "loop.base"
local CyclicSets   = require "loop.collection.CyclicSets"
local BiCyclicSets = require "loop.collection.BiCyclicSets"
local SortedMap    = require "loop.collection.SortedMap"

local luaerror     = global.error
local assert       = global.assert
local getmetatable = global.getmetatable
local luapcall     = global.pcall
local rawget       = global.rawget
local newthread    = coroutine.create
local runthread    = coroutine.resume
local yield        = coroutine.yield
local status       = coroutine.status
local running      = coroutine.running
local gettime      = os.time
local difftime     = os.difftime

local StartTime = gettime()
local WeakSet   = oo.class{ __mode = "k" }
local HaltKey   = global.newproxy()
local traceback = global.debug and
                  	global.debug.traceback or
                  	function(_, err) return err end

--[[VERBOSE]] local type        = global.type
--[[VERBOSE]] local unpack      = global.unpack
--[[VERBOSE]] local rawget      = global.rawget
--[[VERBOSE]] local select      = global.select
--[[VERBOSE]] local tostring    = global.tostring
--[[VERBOSE]] local string      = require "string"
--[[VERBOSE]] local table       = require "table"
--[[VERBOSE]] local math        = require "math"
--[[VERBOSE]] local ObjectCache = require "loop.collection.ObjectCache"
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
		local luafunc, pcall = luapcall(newthread, func)
		if luafunc then
			NestedPCalls:addto(thread, pcall)                                         --[[VERBOSE]] verbose:copcall(true, "new protected call in ",NestedPCalls:successor(pcall))
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
	if rawget(self, "traps"   ) == nil then self.traps    = WeakSet()      end
	if rawget(self, "threads" ) == nil then self.threads  = BiCyclicSets() end
	if rawget(self, "times"   ) == nil then self.times    = SortedMap()    end
	if rawget(self, "current" ) == nil then self.current  = false          end
	if rawget(self, "previous") == nil then self.previous = false          end
	self.threads:addto(nil, false)
	return self
end
__init(getmetatable(_M), _M)

--------------------------------------------------------------------------------
-- Internal Functions ----------------------------------------------------------
--------------------------------------------------------------------------------

function checkcurrent(self)
	local current = self.current
	local thread = running()
	assert(current,
		"attempt to call scheduler operation out of a scheduled thread context.")
	assert(current == thread or PCallMap[thread] == current,
		"inconsistent internal state, current scheduled thread is not running.")
	return current
end

function resumeall(self, success, ...)                                          --[[VERBOSE]] local verbose = self.verbose
	local continue = (... ~= HaltKey)
	if continue then
		local threads = self.threads
		local previous = self.previous
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
			elseif threads:precessor(current) == previous then
				self.previous = current
			end                                                                       --[[VERBOSE]] else verbose:scheduler(true, "resuming running threads")
		end
		current = threads:successor(self.previous)
		if current then
			self.current = current                                                    --[[VERBOSE]] verbose:threads(true, "resuming ",current)
			return self:resumeall(runthread(current, ...))
		end
		self.previous = false
		continue = threads[false] or nil
	end                                                                           --[[VERBOSE]] verbose:scheduler(false, "running threads resumed")
	self.current = false
	return continue
end

function wakeupall(self)                                                        --[[VERBOSE]] local verbose = self.verbose
	local times = self.times
	local head = times:head()
	if head then                                                                  --[[VERBOSE]] verbose:scheduler(true, "waking sleeping threads up")
		local next, time = times:crop(self:time(), true)
		-- TODO: what if 'head' or 'next' are not registered in the sleeping set
		--       anymore? they may have been removed, resumed, re-registered, etc.
		if head ~= next then
			local threads = self.threads
			threads:moveto(self.previous, head, threads:precessor(next or head))     --[[VERBOSE]] verbose:threads("some sleeping threads woke up")
		end                                                                         --[[VERBOSE]] verbose:scheduler(false, "all sleeping threads waken, none left")
		return time
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
	if previous == nil then previous = threads:precessor(false) end
	return threads:addto(previous, thread)
end

function remove(self, thread)                                                   --[[VERBOSE]] local verbose = self.verbose; verbose:threads("removing ",thread)
	local threads = self.threads
	if thread == self.previous then
		self.previous = threads:precessor(thread)
	end
	return threads:remove(thread)
end

function suspend(self, time, ...)                                               --[[VERBOSE]] local verbose = self.verbose
	local current = self:checkcurrent()
	if time == nil then
		self.threads:remove(current)                                                --[[VERBOSE]] verbose:threads(current," suspended")
	elseif time > 0 then
		local previous = self.times:put(self:time() + time, current, true)
		-- TODO: what if 'previous' are not registered in the sleeping set anymore?
		--       they may have been removed, resumed, re-registered, etc.
		self.threads:moveto(previous, current)                                      --[[VERBOSE]] verbose:threads(current," waiting for ",time," seconds")
	end
	return yield(...)
end

function resume(self, thread, ...)                                              --[[VERBOSE]] local verbose = self.verbose
	local current = self:checkcurrent()
	local threads = self.threads
	local place = threads:precessor(thread)
	if place == nil
		then threads:addto(current, thread)                                         --[[VERBOSE]] verbose:threads("resuming unregistered ",thread)
		else threads:movetofrom(current, place)                                     --[[VERBOSE]] verbose:threads("resuming registered ",thread)
	end
	return yield(...)
end

function start(self, func, ...)                                                 --[[VERBOSE]] local verbose = self.verbose
	self.threads:addto(self:checkcurrent(), newthread(func))                      --[[VERBOSE]] verbose:threads("starting ",self.threads:successor(self.current))
	return yield(...)
end

function halt(self)
	self:checkcurrent()
	return yield(HaltKey)
end

--------------------------------------------------------------------------------
-- Control Functions -----------------------------------------------------------
--------------------------------------------------------------------------------

function step(self, ...)                                                        --[[VERBOSE]] local verbose = self.verbose; verbose:scheduler(true, "performing scheduling step")
	local nextwake = self:wakeupall()
	local nextrun = self:resumeall(nil, ...)                                      --[[VERBOSE]] verbose:scheduler(false, "scheduling step performed")
	if nextrun then
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

--[[VERBOSE]] verbose = Verbose()
--[[VERBOSE]] 
--[[VERBOSE]] local LabelStart = string.byte("A")
--[[VERBOSE]] verbose.labels = ObjectCache{ current = 0 }
--[[VERBOSE]] function verbose.labels:retrieve(value)
--[[VERBOSE]] 	if type(value) == "thread" then
--[[VERBOSE]] 		local id = self.current
--[[VERBOSE]] 		local label = {}
--[[VERBOSE]] 		repeat
--[[VERBOSE]] 			label[#label+1] = LabelStart + (id % 26)
--[[VERBOSE]] 			id = math.floor(id / 26)
--[[VERBOSE]] 		until id <= 0
--[[VERBOSE]] 		self.current = self.current + 1
--[[VERBOSE]] 		value = string.char(unpack(label))
--[[VERBOSE]] 	end
--[[VERBOSE]] 	return value
--[[VERBOSE]] end
--[[VERBOSE]] 
--[[VERBOSE]] verbose.groups.concurrency = { "scheduler", "threads", "copcall" }
--[[VERBOSE]] verbose:newlevel{"threads"}
--[[VERBOSE]] verbose:newlevel{"scheduler"}
--[[VERBOSE]] verbose:newlevel{"copcall"}
--[[VERBOSE]] function verbose.custom:threads(...)
--[[VERBOSE]] 	local viewer  = self.viewer
--[[VERBOSE]] 	local output  = self.viewer.output
--[[VERBOSE]] 	
--[[VERBOSE]] 	for i = 1, select("#", ...) do
--[[VERBOSE]] 		local value = select(i, ...)
--[[VERBOSE]] 		if type(value) == "string" then
--[[VERBOSE]] 			output:write(value)
--[[VERBOSE]] 		elseif type(value) == "thread" then
--[[VERBOSE]] 			output:write("thread ", self.labels[value], "[", tostring(value):match("%l+: (.+)"), "]")
--[[VERBOSE]] 		else
--[[VERBOSE]] 			viewer:write(value)
--[[VERBOSE]] 		end
--[[VERBOSE]] 	end
--[[VERBOSE]] 	
--[[VERBOSE]] 	local scheduler = rawget(self, "schedulerdetails")
--[[VERBOSE]] 	if scheduler then
--[[VERBOSE]] 		local newline = "\n"..viewer.prefix..viewer.indentation
--[[VERBOSE]] 	
--[[VERBOSE]] 		output:write(newline)
--[[VERBOSE]] 		output:write("Current: ")
--[[VERBOSE]] 		output:write(tostring(self.labels[scheduler.current]))
--[[VERBOSE]] 	
--[[VERBOSE]] 		output:write(newline)
--[[VERBOSE]] 		output:write("Running:")
--[[VERBOSE]] 		for current in scheduler.threads:forward(false) do
--[[VERBOSE]] 			if not current then break end
--[[VERBOSE]] 			output:write(" ")
--[[VERBOSE]] 			output:write(tostring(self.labels[current]))
--[[VERBOSE]] 		end
--[[VERBOSE]] 	
--[[VERBOSE]] 		output:write(newline)
--[[VERBOSE]] 		output:write("Sleeping:")
--[[VERBOSE]] 		for time, current in scheduler.times:pairs() do
--[[VERBOSE]] 			output:write(" ")
--[[VERBOSE]] 			output:write(tostring(self.labels[current]))
--[[VERBOSE]] 			output:write("(")
--[[VERBOSE]] 			output:write(time)
--[[VERBOSE]] 			output:write(")")
--[[VERBOSE]] 		end
--
--output:write(newline,
--	"ThreadSets: ",
--	scheduler.threads:__tostring(function(thread)
--		return tostring(self.labels[thread])
--	end))
--
--[[VERBOSE]] 	end
--[[VERBOSE]] end
--[[VERBOSE]] verbose.custom.copcall = verbose.custom.threads
--[[VERBOSE]] 
--[[DEBUG]] verbose.I = Inspector{ viewer = viewer }
--[[DEBUG]] function verbose.inspect:debug() self.I:stop(4) end
--[[DEBUG]] verbose:flag("debug", true)
