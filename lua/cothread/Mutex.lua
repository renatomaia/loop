-- Project: CoThread
-- Title  : Mutual Exclusion Locker
-- Author : Renato Maia <maia@inf.puc-rio.br>

local coroutine = require "coroutine"
local running = coroutine.running
local yield = coroutine.yield

local oo = require "loop.base"
local class = oo.class

local BiCyclicSets = require "loop.collection.BiCyclicSets"
local contains = BiCyclicSets.contains
local add = BiCyclicSets.add
local remove = BiCyclicSets.remove

module(...)


local Mutex = class(_M)

function Mutex:try(wait)                                                        --[[VERBOSE]] local verbose = yield("verbose")
	local inside = self.inside                                                    --[[VERBOSE]] verbose:mutex(true, "attempt to get access")
	local thread = running()
	if not inside then                                                            --[[VERBOSE]] verbose:mutex("resource is free")
		self.inside = thread
	elseif wait and inside ~= thread then                                         --[[VERBOSE]] verbose:mutex("resource in use: waiting for notification")
		add(self, thread, false)
		yield("suspend")                                                            --[[VERBOSE]] verbose:mutex("notification received")
		remove(self, thread)
	end                                                                           --[[VERBOSE]] verbose:mutex(false, "access ",(self.inside == thread) and "granted" or "denied")
	return self.inside == thread
end

function Mutex:free()                                                           --[[VERBOSE]] local verbose = yield("verbose")
	if self.inside == running() then
		local thread = self[false]
		if thread then
			self.inside = thread                                                      --[[VERBOSE]] verbose:mutex("resouce released for ",thread)
			yield("resume", thread)
		else
			self.inside = nil                                                         --[[VERBOSE]] verbose:mutex("resouce released")
		end
		return true
	end                                                                           --[[VERBOSE]] verbose:mutex("attempt to release resource not owned")
end

function Mutex:deny(thread, ...)                                                --[[VERBOSE]] local verbose = yield("verbose")
	if self[thread] ~= nil then                                                   --[[VERBOSE]] verbose:mutex("deny access for ",thread)
		yield("resume", thread)
		return true
	end                                                                           --[[VERBOSE]] verbose:mutex("attempt to deny access for a thread not interested")
end

function Mutex:grant(thread, ...)                                               --[[VERBOSE]] local verbose = yield("verbose")
	if self.inside == running()
	and self[thread] ~= nil
	then
		self.inside = thread                                                        --[[VERBOSE]] verbose:mutex("access resource granted for ",thread)
		yield("resume", thread, ...)
		return true                                                                 --[[VERBOSE]] else verbose:mutex("attempt to grant resource access for ",thread," failed")
	end
end
