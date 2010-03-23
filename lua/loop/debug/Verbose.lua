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

local function dummy() end

local function write(self, flag, ...)
	local count = select("#", ...)
	if count > 0 then
		local viewer = self.viewer
		local output = viewer.output
		local timed  = self.timed
		local custom = self.custom
		local pause  = self.pause
		
		local flaglength = self.flaglength
		output:write("[", flag, "]")
		output:write(viewer.prefix:sub(#flag + 3, flaglength))
		
		timed = (type(timed) == "table") and timed[flag] or timed
		if timed == true then
			timed = date()
			output:write(timed, " - ")
			output:write(viewer.prefix:sub(flaglength + #timed + 4))
		elseif type(timed) == "string" then
			timed = date(timed)
			output:write(timed, " ")
			output:write(viewer.prefix:sub(flaglength + #timed + 2))
		else
			output:write(viewer.prefix:sub(flaglength + 1))
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

local function updatetabs(self, shift)
	local viewer = self.viewer
	local thread = self.thread
	local threadtabs = self.threadtabs
	local tabs = threadtabs[thread]
	if shift then
		tabs = max(tabs + shift, 0)
		threadtabs[thread] = tabs
	end
	local length = self.flaglength + self.timelength
	self.threadruler = strrep("-", length)
	viewer.prefix = strrep(" ", length)..viewer.indentation:rep(tabs)
end

local ThreadRuler = strrep("-", 60).." "
local function maketag(tag)
	return function (self, start, ...)
		local thread = running() or false
		if self.thread ~= thread then
			self.thread = thread
			updatetabs(self)
			if not self.nothreads then
				local viewer = self.viewer
				local output = viewer.output
				output:write(ThreadRuler)
				if thread then viewer:write(thread) end
				output:write("\n")
			end
		end
		if start == false then
			updatetabs(self, -1)
			write(self, tag, ...)
		elseif start == true then
			write(self, tag, ...)
			updatetabs(self, 1)
		else
			write(self, tag, start, ...)
		end
	end
end

--------------------------------------------------------------------------------

thread = false
nothreads = false
flaglength = 8
timelength = 0
viewer = Viewer{ maxdepth = 2 }

function __new(class, verbose)
	verbose = rawnew(class, verbose)
	verbose.flags      = {}
	verbose.threadtabs = memoize(function() return 0 end, "k")
	verbose.groups     = rawget(verbose, "groups")  or {}
	verbose.custom     = rawget(verbose, "custom")  or {}
	verbose.pause      = rawget(verbose, "pause") or {}
	verbose.timed      = rawget(verbose, "timed")   or {}
	return verbose
end

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

function flag(self, name, ...)
	local group = self.groups[name]
	if group then
		for _, name in ipairs(group) do
			if not self:flag(name, ...) then return false end
		end
	elseif select("#", ...) > 0 then
		self.flags[name] = (...) and maketag(name) or nil
		local timed = self.timed
		local timelen = 0
		local taglen = 5
		for name in pairs(self.flags) do
			local length = (type(timed) == "table") and timed[name] or timed
			if length == true then
				length = 19 -- length of 'DD/MM/YY HH:mm:ss -'
			elseif type(length) == "string" then
				length = #date(length)
			else
				length = 0
			end
			timelen = max(timelen, length)
			taglen = max(taglen, #name)
		end
		self.flaglength = max(taglen + 3, self.flaglength)
		self.timelength = max(timelen + 1, self.timelength)
		updatetabs(self)
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
