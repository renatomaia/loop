-- Project: CoThread
-- Title  : Queue with Support for Syncronization of CoThreads
-- Author : Renato Maia <maia@inf.puc-rio.br>


local coroutine = require "coroutine"                                           --[[VERBOSE]] local Dummy = require("loop.object.Dummy")()
local running = coroutine.running
local yield = coroutine.yield

local oo = require "loop.simple"
local class = oo.class

local Queue = require "loop.collection.Queue"
local length = Queue.__len
local enqueue = Queue.enqueue
local dequeue = Queue.dequeue

local OrderedSet = require "loop.collection.OrderedSet"
local pushback = OrderedSet.pushback
local popfront = OrderedSet.popfront

local CoQueue = class({}, Queue)

function CoQueue:enqueue(item)
	local thread = popfront(self)
	if thread ~= nil then
		yield("next", thread, item)
		return item
	end
	return enqueue(self, item)
end

function CoQueue:dequeue()
	if length(self) == 0 then
		pushback(self, yield("running"))
		return yield("suspend")
	end
	return dequeue(self)
end

return CoQueue
