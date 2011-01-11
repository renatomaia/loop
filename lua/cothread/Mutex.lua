-- Project: CoThread
-- Title  : Mutual Exclusion Locker
-- Author : Renato Maia <maia@inf.puc-rio.br>

local _G = require "_G"
local select = _G.select
local unpack = _G.unpack

local coroutine = require "coroutine"                                           --[[VERBOSE]] local Dummy = require("loop.object.Dummy")()
local running = coroutine.running
local yield = coroutine.yield

local oo = require "loop.base"
local class = oo.class

local BiCyclicSets = require "loop.collection.BiCyclicSets"
local contains = BiCyclicSets.contains
local add = BiCyclicSets.add
local remove = BiCyclicSets.remove

local Token = {} -- private token used to signal a mutex action

local Mutex = class()

function Mutex:isfree()
	return self.inside == nil
end

function Mutex:try(timeout)                                                     --[[VERBOSE]] local verbose = running() == nil and Dummy or yield("verbose")
	local inside = self.inside                                                    --[[VERBOSE]] verbose:mutex(true, "attempt to get access")
	local thread = running()
	if inside == nil then                                                            --[[VERBOSE]] verbose:mutex("resource is free")
		self.inside = thread
	elseif thread ~= inside and (timeout == nil or timeout > 0) then              --[[VERBOSE]] verbose:mutex("resource in use: waiting for notification")
		add(self, thread, false)
		if timeout == nil then
			yield("suspend")
		elseif yield("defer", timeout) == Token then
			timeout = nil
		end                                                                         --[[VERBOSE]] verbose:mutex("notification received")
		remove(self, thread)
	end                                                                           --[[VERBOSE]] verbose:mutex(false, "access ",(self.inside == thread) and "granted" or "denied")
	return thread == self.inside, timeout
end

function Mutex:free()                                                           --[[VERBOSE]] local verbose = running() == nil and Dummy or yield("verbose")
	if self.inside == running() then
		local thread = self[false]
		if thread then
			self.inside = thread                                                      --[[VERBOSE]] verbose:mutex("resouce released for ",thread)
			yield("resume", thread, Token)
		else
			self.inside = nil                                                         --[[VERBOSE]] verbose:mutex("resouce released")
		end
		return true
	end                                                                           --[[VERBOSE]] verbose:mutex("attempt to release resource not owned")
end

function Mutex:deny(thread)                                                     --[[VERBOSE]] local verbose = running() == nil and Dummy or yield("verbose")
	if self[thread] ~= nil then                                                   --[[VERBOSE]] verbose:mutex("deny access for ",thread)
		yield("resume", thread, Token)
		return true
	end                                                                           --[[VERBOSE]] verbose:mutex("attempt to deny access for a thread not interested")
end

function Mutex:grant(thread)                                                    --[[VERBOSE]] local verbose = running() == nil and Dummy or yield("verbose")
	if self.inside == running()
	and self[thread] ~= nil
	then
		self.inside = thread                                                        --[[VERBOSE]] verbose:mutex("access resource granted for ",thread)
		yield("resume", thread, Token)
		return true                                                                 --[[VERBOSE]] else verbose:mutex("attempt to grant resource access for ",thread," failed")
	end
end

function Mutex.select(timeout, ...)                                             --[[VERBOSE]] local verbose = running() == nil and Dummy or yield("verbose")
	local count = select("#", ...)                                                --[[VERBOSE]] verbose:mutex(true, "attempt to get access to any of ",count," resources")
	local thread = running()
	local results = 0
	local granted = {}
	for i = 1, count do
		local self = select(i, ...)
		local inside = self.inside
		if inside == nil or inside == thread then                                   --[[VERBOSE]] verbose:mutex("resource #",i," is free")
			self.inside = thread
			results = results+1
			granted[results] = self
			break
		end
	end
	if results == 0 and (timeout == nil or timeout > 0) then                      --[[VERBOSE]] verbose:mutex("all ",count," resources are in use: waiting for notification")
		for i = 1, count do
			add(select(i, ...), thread, false)
		end
		if timeout == nil then
			yield("suspend")
		else
			yield("defer", timeout)
		end                                                                         --[[VERBOSE]] verbose:mutex("notification received")
		for i = 1, count do
			local self = select(i, ...)
			remove(self, thread)
			if self.inside == thread then                                             --[[VERBOSE]] verbose:mutex("resource #",i," was acquired")
				results = results+1
				granted[results] = self
			end
		end
	end                                                                           --[[VERBOSE]] verbose:mutex(false, "access ",granted and "granted" or "denied")
	return unpack(granted, 1, results)
end

return Mutex
