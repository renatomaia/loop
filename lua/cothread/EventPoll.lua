-- Project: CoThread
-- Title  : Event Poll
-- Author : Renato Maia <maia@inf.puc-rio.br>

local _G = require "_G"
local rawget = _G.rawget

local coroutine = require "coroutine"
local newcoroutine = coroutine.create
local yield = coroutine.yield

local table = require "loop.table"
local memoize = table.memoize

local oo = require "loop.base"
local class = oo.class
local rawnew = oo.rawnew

local Queue = require "loop.collection.Queue"
local length = Queue.__len
local enqueue = Queue.enqueue
local dequeue = Queue.dequeue

local OrderedSet = require "loop.collection.OrderedSet"
local pushback = OrderedSet.pushback
local popfront = OrderedSet.popfront

local EventPoll = class()

function EventPoll:__new(object)
	self = rawnew(self, object)
	self:clear()
	return self
end

function EventPoll:add(socket, event)
	local events = self.registry[socket]
	if events[event] == nil then
		events[event] = true
		local thread = self.thread
		if thread ~= nil then
			yield("addwait", socket, event, thread)
		end
		return true
	end
end

function EventPoll:remove(socket, event)
	local sockets = self.registry
	local events = rawget(sockets, socket)
	if events ~= nil then
		if events[event] ~= nil then
			events[event] = nil
			if next(events) == nil then
				sockets[socket] = nil
			end
			local thread = self.thread
			if thread ~= nil then
				yield("removewait", socket, event, thread)
			end
			return true
		end
	end
end

function EventPoll:clear()
	local result = self.registry
	self.registry = memoize(function () return {} end)
	return result
end

function EventPoll:getready(timeout)
	local thread = yield("running")
	if timeout == nil then
		yield("unschedule", thread)
	else
		yield("schedule", thread, self.timeoutkind, timeout)
	end
	local registry = self.registry
	for socket, events in pairs(registry) do
		for event in pairs(events) do
			yield("addwait", socket, event, thread)
		end
	end
	self.thread = thread
	local socket, event = yield("yield")
	self.thread = nil
	for socket, events in pairs(registry) do
		for event in pairs(events) do
			yield("removewait", socket, event, thread)
		end
	end
	if socket == nil then return nil, "timeout" end
	if timeout ~= nil then yield("unschedule", thread) end
	return socket, event
end

return EventPoll
