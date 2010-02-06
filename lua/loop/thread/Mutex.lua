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
-- Title  : Mutual Exclusion Locker                                           --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------

local oo = require "loop.base"
local OrderedSet = require "loop.collection.OrderedSet"

local contains = OrderedSet.contains
local enqueue = OrderedSet.enqueue
local first = OrderedSet.first
local remove = OrderedSet.remove

module("loop.thread.Mutex", oo.class)

function try(wait)
	local scheduler = self.scheduler                                              --[[VERBOSE]] local verbose = scheduler.verbose
	local inside = self.inside                                                    --[[VERBOSE]] verbose:mutex(true, "attempt to get access")
	local thread = scheduler.current
	if not inside then                                                            --[[VERBOSE]] verbose:mutex("resource is free")
		self.inside = thread
	elseif wait and inside ~= thread then                                         --[[VERBOSE]] verbose:mutex("resource in use: waiting for notification")
		enqueue(self, thread)
		scheduler:suspend()                                                         --[[VERBOSE]] verbose:mutex("notification received")
		remove(self, thread)
	end                                                                           --[[VERBOSE]] verbose:mutex(false, "access ",(self.inside == thread) and "granted" or "denied")
	return self.inside == thread
end

function free()
	local scheduler = self.scheduler                                              --[[VERBOSE]] local verbose = scheduler.verbose
	if self.inside == scheduler.current then
		local thread = first(self)
		if thread then
			self.inside = thread                                                      --[[VERBOSE]] verbose:mutex("release resouce for ",thread)
			return scheduler:resume(thread)
		else
			self.inside = nil                                                         --[[VERBOSE]] verbose:mutex("resouce released")
		end                                                                         --[[VERBOSE]] else verbose:mutex("attempt to release resource not owned")
	end
end

function deny(thread)                                                           --[[VERBOSE]] local verbose = self.scheduler.verbose
	if contains(self, thread) then                                                --[[VERBOSE]] verbose:mutex("deny access for ",thread)
		return self.scheduler:resume(thread)                                        --[[VERBOSE]] else verbose:mutex("attempt to deny access for a thread not interested")
	end
end

function grant(thread)                                                          --[[VERBOSE]] local verbose = self.scheduler.verbose
	if self.inside == scheduler.current
	and contains(self, thread)
	then                                                                          --[[VERBOSE]] verbose:mutex("release resource for ",thread)
		self.inside = thread
		self.scheduler:resume(thread)
		return true
	end                                                                           --[[VERBOSE]] else verbose:mutex("attempt to release resource for ",thread," failed")
end

--------------------------------------------------------------------------------

local resource = {}
local mutex

-- entering critical region
if mutex == nil then
	mutex = scheduler.current
else
	scheduler:wait(resource)
end

resouce[#resouce+1] = scheduler.current

-- leaving critical region
scheduler:notify(resource)

--------------------------------------------------------------------------------

local waiting = {}
local mutex

local request = math.random(10)

-- try enter critical region
if mutex == nil then
	mutex = scheduler.current
else
	waiting[request] = scheduler.current
	scheduler:wait(math.random)
	waiting[request] = nil
end

-- execute critical region
if mutex == scheduler.current then
	local result = true
	while result and result ~= request do
		result = math.random(10)
		-- notify possible waiting thread
		local thread = waiting[result]
		if thread then
			scheduler:resume(thread)
		end
	end
	-- leaving critical region
	mutex = ???
	scheduler:notify(math.random, true)
end

