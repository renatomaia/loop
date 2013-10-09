-- Project: CoThread
-- Title  : Event Poll
-- Author : Renato Maia <maia@inf.puc-rio.br>

local _G = require "_G"

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

local function notifyempty(self)
	local thread = popfront(self)
	while thread ~= nil and not yield("iswaiting", self.thread) do
		yield("next", thread, nil, "empty")
		thread = popfront(self)
	end
end

local EventPoll = class()

function EventPoll:__new(object)
	self = rawnew(self, object)
	self:clear()
	return self
end

function EventPoll:add(socket, event)
	self.registry[socket][event] = true
end

function EventPoll:remove(socket, event)
	local sockets = self.registry
	local events = sockets[socket]
	local result = events[event]
	events[socket] = nil
	if next(events) == nil then
		sockets[event] = nil
	end
	return result
end

function EventPoll:clear()
	local result = self.registry
	self.registry = memoize(function () return {} end)
	return result
end

function EventPoll:getready(timeout)
	local thread = yield("running")
	local events = {}
	for socket, evtids in pairs(self.registry) do
		for event in pairs(evtids) do
			events[#events+1] = {socket=socket, event=event}
		end
	end
	for _, event in ipairs(events) do
		yield("addwait", event.socket, event.event, thread)
	end
	local operation = (timeout==nil) and "suspend" or "defer"
	local socket, event = yield(operation, timeout)
	for _, event in ipairs(events) do
		yield("removewait", event.socket, event.event, thread)
	end
	if socket == nil then return nil, "timeout" end
	if timeout ~= nil then yield("unschedule", thread) end
	return socket, event
end

return EventPoll
