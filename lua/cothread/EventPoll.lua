-- Project: CoThread
-- Title  : Event Poll
-- Author : Renato Maia <maia@inf.puc-rio.br>

local _G = require "_G"

local coroutine = require "coroutine"
local newcoroutine = coroutine.create
local yield = coroutine.yield

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
	if self.thread == nil then
		self.thread = newcoroutine(function(socket, event)
			repeat
				local thread = popfront(self)
				if thread ~= nil then
					socket, event = yield("yield", thread, socket, event)
				else
					yield("removewait", socket, event, self.thread)
					enqueue(self, {socket, event})
					socket, event = yield("yield")
				end
			until false
		end)                                                                        --[[VERBOSE]] yield("verbose").viewer.labels[self.thread] = "EventPoll (".._G.tostring(self)..")"
	end
	return self
end

function EventPoll:add(socket, event)
	return yield("addwait", socket, event, self.thread)
end

function EventPoll:remove(socket, event)
	if yield("removewait", socket, event, self.thread) then
		notifyempty(self)
		return true
	end
end

function EventPoll:clear()
	local result = yield("getwaitof", self.thread)
	yield("unschedule", self.thread)
	notifyempty(self)
	return result
end

function EventPoll:getready(timeout)
	if not yield("iswaiting", self.thread) then
		return nil, "empty"
	end
	local event
	if length(self) == 0 then
		local thread = yield("running")
		pushback(self, thread)
		if timeout == nil then
			return yield("suspend")
		end
		local socket, event = yield("defer", timeout)
		yield("unschedule", thread)
		if socket == nil then return nil, "timeout" end
		return socket, event
	end
	local queued = dequeue(self)
	local socket, event = queued[1], queued[2]
	yield("addwait", socket, event, self.thread)
	return socket, event
end

return EventPoll
