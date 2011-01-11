-- Project: LOOP Class Library
-- Release: 2.3 beta
-- Title  : Verbose/Log Mechanism for Layered Applications
-- Author : Renato Maia <maia@inf.puc-rio.br>

local _G = require "_G"
local type = _G.type
local rawget = _G.rawget
local ipairs = _G.ipairs
local pairs = _G.pairs
local select = _G.select

local io = require "io"
local read = io.read

local os = require "os"
local date = os.date

local math = require "math"
local max = math.max

local table = require "table"
local insert = table.insert

local string = require "string"
local strrep = string.rep

local coroutine = require "coroutine"
local running = coroutine.running

local tabop  = require "loop.table"
local memoize = tabop.memoize

local oo = require "loop.base"
local class = oo.class
local rawnew = oo.rawnew

local Viewer = require "loop.debug.Viewer"

module(..., class)

--------------------------------------------------------------------------------

local FlagColWidth = 12 -- 9 for flag, 2 for square brackets, and 1 for a space
local ThreadRuler = strrep("-", 55).." "
local CurrentThread = false

local function write(self, newthread, flag, ...)
	local count = select("#", ...)
	if count > 0 then
		local viewer = self.viewer
		local output = viewer.output
		local timed  = self.timed
		local custom = self.custom
		local pause  = self.pause
		
		if CurrentThread ~= newthread then
			CurrentThread = newthread
			output:write(ThreadRuler)
			if newthread then viewer:write(newthread) end
			output:write("\n")
		end
		
		local prefix = viewer.prefix
		local timelength = self.timelength
		if timelength > 0 then
			timed = (type(timed) == "table") and timed[flag] or timed
			if timed == true then
				output:write(date(self.timeformat or nil), " ")
			else
				output:write(prefix:sub(1, timelength+1))
			end
		end
		
		if #flag+3 > FlagColWidth then
			output:write("[", flag:sub(1, 7), "...] ")
		else
			output:write("[", flag, "] ")
			output:write(viewer.prefix:sub(timelength + #flag+4))
		end
		
		custom = custom[flag]
		if custom == nil or custom(self, ...) then
			for i = 1, count do
				local value = select(i, ...)
				if type(value) == "string"
					then output:write(value)
					else viewer:write(value)
				end
			end
		end
		
		pause = (type(pause) == "table") and pause[flag] or pause
		if pause == true then
			read()
		else
			output:write("\n")
			if type(pause) == "function" then pause(self) end
		end
		
		output:flush()
	end
end

local function updatetabs(self, thread, shift)
	local viewer = self.viewer
	local tabs = self.tabsof[thread]
	if shift then
		tabs = max(tabs + shift, 0)
		self.tabsof[thread] = tabs
	end
	viewer.prefix = strrep(" ", self.timelength + FlagColWidth)
	              ..viewer.indentation:rep(tabs)
end

local function maketag(tag)
	return function (self, start, ...)
		local thread = running() or false
		if start == false then
			updatetabs(self, thread, -1)
			write(self, thread, tag, ...)
		else
			updatetabs(self, thread)
			if start == true then
				write(self, thread, tag, ...)
				updatetabs(self, thread, 1)
			else
				write(self, thread, tag, start, ...)
			end
		end
	end
end

--------------------------------------------------------------------------------

timestamp = false
thread = false
nothreads = false
timelength = 0
timeformat = false
viewer = Viewer{ maxdepth = 2 }

function __new(class, verbose)
	verbose = rawnew(class, verbose)
	verbose.flags  = {}
	verbose.groups = rawget(verbose, "groups") or {}
	verbose.custom = rawget(verbose, "custom") or {}
	verbose.pause  = rawget(verbose, "pause")  or {}
	verbose.timed  = rawget(verbose, "timed")  or {}
	verbose.tabsof = memoize(function() return rawget(verbose.tabsof, CurrentThread) or 0 end, "k")
	return verbose
end

local function dummy() end

function __index(self, field)
	local value = _M[field]
	if value ~= nil then return value end
	return field and self.flags[field] or dummy
end

--------------------------------------------------------------------------------

function setgroup(self, name, group)
	self.groups[name] = group
end

function newlevel(self, level, group)
	local groups = self.groups
	local count = #groups
	if not group then
		groups[count+1] = level
	elseif level <= count then
		insert(groups, level, group)
	else
		self:setlevel(level, group)
	end
end

function setlevel(self, level, group)
	for i = 1, level - 1 do
		if not self.groups[i] then
			self.groups[i] = {}
		end
	end
	self.groups[level] = group
end

--------------------------------------------------------------------------------

function settimeformat(self, format)
	self.timeformat = format
	self.timelength = #date(format)
end

function flag(self, name, ...)
	local group = self.groups[name]
	if group then
		for _, name in ipairs(group) do
			if not self:flag(name, ...) then return false end
		end
	elseif select("#", ...) > 0 then
		self.flags[name] = (...) and maketag(name) or nil
	else
		return self.flags[name] ~= nil
	end
	return true
end

function level(self, ...)
	if select("#", ...) == 0 then
		for level = 1, #self.groups do
			if not self:flag(level) then return level - 1 end
		end
		return #self.groups
	else
		for level = 1, #self.groups do
			self:flag(level, level <= ...)
		end
	end
end


--[[----------------------------------------------------------------------------
LOG = loop.debug.Verbose{
	groups = {
		-- levels
		{"main"},
		{"counter"},
		-- aliases
		all = {"main", "counter"},
	},
}
LOG:flag("all", true)
-------------------------------------
local Counter = loop.base.class{
	value = 0,
	step = 1,
}
function Counter:add()                LOG:counter "Adding step to counter"
	self.value = self.value + self.step
end
-------------------------------------
counter = Counter()                   LOG:main "Counter object created"
steps = 10                            LOG:main(true, "Counting ",steps," steps")
for i=1, steps do counter:add() end   LOG:main(false, "Done! Counter=",counter)
-------------------------------------
--> [main]    Counter object created
--> [main]    Counting 10 steps
--> [counter] |  Adding step to counter
--> [counter] |  Adding step to counter
--> [counter] |  Adding step to counter
--> [counter] |  Adding step to counter
--> [counter] |  Adding step to counter
--> [counter] |  Adding step to counter
--> [counter] |  Adding step to counter
--> [counter] |  Adding step to counter
--> [counter] |  Adding step to counter
--> [counter] |  Adding step to counter
--> [main]    Done! Counter={ table: 0x9c3e390
-->           |  value = 10,
-->           }
----------------------------------------------------------------------------]]--
