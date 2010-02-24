-- Project: LOOP Class Library
-- Release: 2.3 beta
-- Title  : Reachable Values Crawler
-- Author : Renato Maia <maia@inf.puc-rio.br>


local _G = require "_G"
local getfenv = _G.getfenv
local getmetatable = _G.getmetatable
local pairs = _G.pairs
local select = _G.select
local type = _G.type
local debug = _G.debug -- only if available

local coroutine = require "coroutine"
local running = coroutine.running

local math = require "math"
local huge = math.huge

local oo = require "loop.base"
local class = oo.class


module(..., class)

metatable = getmetatable
environment = debug and debug.getfenv
upvalue = debug and debug.getupvalue
registry = debug and debug.getregistry
callstack = debug and debug.getinfo
localvar = debug and debug.getlocal



function crawlmetatable(self, value)
	local getmetatable = self.metatable
	if getmetatable then
		local meta = getmetatable(value)
		if meta ~= nil then
			self:found(meta, value, "metatable")
		end
	end
end

function crawlenvironment(self, value)
	local getenv = self.environment
	if getenv then
		local env = getenv(value)
		if env ~= nil then
			self:found(env, value, "environment")
		end
	end
end

function crawltable(self, value)
	for key, entry in pairs(value) do
		self:found(key, value, "key", entry)
		self:found(entry, value, "entry", key)
	end
	self:crawlmetatable(value)
end

function crawlfunction(self, value)
	local getupvalue = self.upvalue
	if getupvalue then
		for i = 1, huge do
			local upname, upvalue = getupvalue(value, i)
			if upname == nil then break end
			self:found(upname, value, "upname", upvalue, i)
			self:found(upvalue, value, "upvalue", upname, i)
		end
	end
	self:crawlenvironment(value)
end

function crawluserdata(self, value)
	self:crawlenvironment(value)
	self:crawlmetatable(value)
end

function crawlthread(self, value)
	local getinfo = self.callstack
	if getinfo then
		local ignored = 0
		if value == self.mythread then
			repeat
				ignored = ignored+1
				local stack
				if value == nil
					then stack = getinfo(ignored, "f")
					else stack = getinfo(value, ignored, "f")
				end
			until stack.func == self.crawl
		end
		local getlocal = self.localvar
		for lvl = ignored+1, huge do
			local stack
			if value == nil
				then stack = getinfo(lvl, "nSf")
				else stack = getinfo(value, lvl, "nsf")
			end
			if stack == nil then break end
			self:found(stack.func     , value, "callfunc"        , stack, lvl)
			self:found(stack.name     , value, "callfuncname"    , stack, lvl)
			self:found(stack.namewhat , value, "callfuncnamewhat", stack, lvl)
			self:found(stack.source   , value, "callfuncsource"  , stack, lvl)
			self:found(stack.short_src, value, "callfuncsrc"     , stack, lvl)
			self:found(stack.what     , value, "callfuncwhat"    , stack, lvl)
			if getlocal then
				for loc = 1, huge do
					local locname, locvalue
					if value == nil
						then locname, locvalue = getlocal(lvl, loc)
						else locname, locvalue = getlocal(value, lvl, loc)
					end
					if locname == nil then break end
					self:found(locname, value, "locname", locvalue, loc, lvl)
					self:found(locvalue, value, "local", locname, loc, lvl)
				end
			end
		end
	end
	if value ~= nil then
		self:crawlenvironment(value)
	elseif self.environment then
		self:found(getfenv(0), value, "environment")
	end
end

_M["table"]    = crawltable
_M["function"] = crawlfunction
_M["userdata"] = crawluserdata
_M["thread"]   = crawlthread



input = 0
function add(self, value)
	local i = self.input+1
	self[i] = value
	self.input = i
end
function remove(self)
	local i = self.input
	local value = self[i]
	self[i] = nil
	self.input = i-1
	return value
end
function empty(self)
	return self.input == 0
end

output = 1
local function dequeue(self)
	local i = self.output
	local value = self[i]
	self[i] = nil
	self.output = i+1
	return value
end
local function emptyqueue(self)
	return self.input < self.output
end



function found(self, value, ...)
	local visited = self.visited
	local regval = visited[value]
	local ignore = (regval ~= nil)
	local valtype = type(value)
	
	local visitor = self["found"..valtype] or self["foundvalue"]
	if visitor then
		if regval == nil and value ~= nil then
			visited[value] = true
		end
		local new, cancel = visitor(self, value, regval, ...)
		if cancel ~= nil then ignore = cancel end
		if new ~= nil and value ~= nil then visited[value] = new end
	elseif value ~= nil then
		visited[value] = true
	end
	
	if not ignore and self[valtype] then
		self:add(value)
	end
end

function crawl(self, ...)
	-- define default objects that must be ignored during the crawling
	local visited = self.visited
	if visited == nil then
		visited = {}
		self.visited = visited
	end
	visited[visited] = true
	visited[self] = true
	
	-- register current thread so it knows how to ignore this call
	self.mythread = running()
	
	-- change the way the crawling goes, if requested
	if self.broadsearch then
		self.remove = dequeue
		self.empty = emptyqueue
	end
	
	-- define roots of the crawling
	local count = select("#", ...)
	if count > 0 then
		for i = 1, select("#", ...) do
			self:found(select(i, ...), nil, "root", i)
		end
	else
		self:crawlthread() -- crawl the main thread
		local getregistry = self.registry
		if getregistry then
			self:found(getregistry(), nil, "registry")
		end
	end
	
	-- do the crawling
	while not self:empty() do
		local value = self:remove()
		local crawler = self[type(value)]
		if crawler then crawler(self, value) end
	end
end
