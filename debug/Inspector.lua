--------------------------------------------------------------------------------
-- Project: LOOP Debugging Utilities for Lua                                  --
-- Release: 2.0 alpha                                                         --
-- Title  : Interactive Inspector of Application State                        --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
-- Date   : 27/02/2006 08:51                                                  --
--------------------------------------------------------------------------------

local pcall        = pcall
local rawset       = rawset
local setfenv      = setfenv
local loadstring   = loadstring
local getmetatable = getmetatable
local _G           = _G

local io     = require "io"
local debug  = require "debug"
local oo     = require "loop.base"
local Viewer = require "loop.debug.Viewer"

module("loop.debug.Inspector", oo.class)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local Environment = oo.class()

function Environment:__index(field)
	local name, value

	local func = self._INSPECTOR.level + 4
	local index = 1
	repeat
		name, value = debug.getlocal(func, index)
		if name == field
			then return value
			else index = index + 1
		end
	until not name
	
	func = self._INSPECTOR.current.func
	index = 1
	repeat
		name, value = debug.getupvalue(func, index)
		if name == field
			then return value
			else index = index + 1
		end
	until not name
	
	return _G[field]
end

function Environment:__newindex(field, value)
	local name

	local func = self._INSPECTOR.level + 4
	local index = 1
	repeat
		name = debug.getlocal(func, index)
		if name == field
			then return debug.setlocal(func, index, value)
			else index = index + 1
		end
	until not name
	
	func = self._INSPECTOR.current.func
	index = 1
	repeat
		name = debug.getupvalue(func, index)
		if name == field
			then return debug.setupvalue(func, index, value)
			else index = index + 1
		end
	until not name

	_G[field] = value
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

infoflags = "Slnuf"
active = true
viewer = Viewer

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function __init(class, self)
	self = oo.rawnew(class, self)
	self.environment = Environment{
		_INSPECTOR = self,
		see = function(...)
			self.viewer:write(...)
			self.viewer.output:write("\n")
		end,
		go = function(func)
			self.level = self.level + 1
			self.current = debug.getinfo(func, self.infoflags)
		end,
	}
	return self
end

function stack(self)
	local level = self.level + 2
	self.viewer.output:write(debug.traceback("Current level is "..level, level),"\n")
end

function up(self)
	local next = debug.getinfo(self.level + 3, self.infoflags)
	if next then
		self.level = self.level + 1
		self.current = next
	end
end

function back(self)
	if self.level > 1 then
		self.level = self.level - 1
		self.current = debug.getinfo(self.level + 2, self.infoflags)
	end
end

function locals(self)
	local level = self.level + 2
	local index = 1
	local name, value = debug.getlocal(level, index)
	while name do
		viewer.output:write(name)
		viewer.output:write(" = ")
		viewer:write(value)
		viewer.output:write("\n")
		index = index + 1
		name, value = debug.getlocal(level, index)
	end
end

function upvalues(self)
	local func = self.current.func
	local index = 1
	local name, value = debug.getupvalue(func, index)
	while name do
		viewer.output:write(name)
		viewer.output:write(" = ")
		viewer:write(value)
		viewer.output:write("\n")
		index = index + 1
		name, value = debug.getupvalue(func, index)
	end
end

function cont() end

function breakpoint(self, level)
	if self.active then
		self.level = level or 1
		self.current = debug.getinfo(self.level + 1, self.infoflags)
		local command
		repeat
			local info = self.current
			if info.short_src   then io.stdout:write(info.short_src) end
			if info.currentline then io.stdout:write(":",info.currentline) end
			if info.name        then io.stdout:write(":",info.namewhat," ",info.name) end
			io.stdout:write("> ")
			command = io.stdin:read()
			if self[command] then
				self[command](self)
			else
				local errmsg
				command, errmsg = loadstring(command, "inspect code")
				if command then
					setfenv(command, self.environment)
					command, errmsg = pcall(command)
					if command then errmsg = nil end
				end
				if errmsg then io.stderr:write(errmsg, "\n") end
			end
		until command == "cont"
	end
end

__init(getmetatable(_M), _M)