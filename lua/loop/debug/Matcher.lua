-- Project: LOOP Class Library
-- Release: 2.3 beta
-- Title  : Matcher of Lua Values
-- Author : Renato Maia <maia@inf.puc-rio.br>

local _G = require "_G"
local pairs = _G.pairs
local type = _G.type
local select = _G.select
local getfenv = _G.pcall(_G.getfenv, 2) and _G.getfenv or nil
local tostring = _G.tostring
local getmetatable = _G.getmetatable
local setmetatable = _G.setmetatable
local getupvalue = _G.debug and _G.debug.getupvalue -- only if available

local string = require "string"
local format = string.format
local dump = string.dump

local table = require "table"
local insert = table.insert
local concat = table.concat

local tabop = require "loop.table"
local copy = tabop.copy

local oo = require "loop.base"
local class = oo.class

local module = oo.class{
	__mode = "k",
	isomorphic = true,
	environment = getfenv,
	upvalue = getupvalue,
	metakey = {},
	envkey = {},
}


function module.error(self, message)
	local path = { "value" }
	for i = 2, #self do
		local key = self[i]
		if key == self.metakey then
			insert(path, 1, "getmetatable(")
			key = ")"
		elseif key == self.envkey then
			insert(path, 1, "getfenv(")
			key = ")"
		elseif type(key) == "string" then
			if key:match("^[%a_][%w_]*$") then
				key = "."..key
			else
				key = format("[%q]", key)
			end
		else
			key = format("[%s]", tostring(key))
		end
		path[#path+1] = key
	end
	return format("%s: %s", concat(path), message)
end

function module.matchtable(self, value, other)
	local matched, errmsg = true
	local keysmatched = {}
	self[value], self[other] = other, value
	for key, field in pairs(value) do
		local otherfield = other[key]
		if otherfield == nil then
			matched = false
			for otherkey, otherfield in pairs(other) do
				local matcher = setmetatable(copy(self), getmetatable(self))
				matcher.error = nil
				if
					matcher:match(key, otherkey) and
					matcher:match(field, otherfield)
				then
					copy(matcher, self)
					keysmatched[otherkey] = true
					matched = true
					break
				end
			end
			if not matched then
				self[#self+1] = key
				errmsg = self:error("no match found")
				self[#self] = nil
				break
			end
		else
			self[#self+1] = key
			matched, errmsg = self:match(field, otherfield)
			self[#self] = nil
			if matched then
				keysmatched[key] = true
			else
				break
			end
		end
	end
	if matched and self.isomorphic then
		for otherkey, otherfield in pairs(other) do
			if not keysmatched[otherkey] then
				self[#self+1] = otherkey
				matched, errmsg = false, self:error("missing")
				self[#self] = nil
				break
			end
		end
	end
	if not matched then self[value], self[other] = nil, nil end
	return matched, errmsg
end

function module.matchfunction(self, func, other)
	local matched, errmsg = (dump(func) == dump(other))
	if matched then
		self[func], self[other] = other, func
		local upvalue = self.upvalue
		if upvalue then
			local name, value
			local up = 1
			repeat
				name, value = upvalue(func, up)
				if name then
					self[#self+1] = name
					matched, errmsg = self:match(value, select(2, upvalue(other, up)))
					self[#self] = nil
					if not matched then
						self[func], self[other] = nil, nil
						break
					end
					up = up + 1
				end
			until not name
		end
		local environment = self.environment
		if matched and environment then
			self[#self+1] = self.envkey
			matched, errmsg = self:match(environment(func), environment(other))
			self[#self] = nil
		end
	else
		errmsg = self:error "bytecodes not matched"
	end
	return matched, errmsg
end

function module.match(self, value, other)
	self[0] = self[0] or other
	self[1] = self[1] or value
	local matched, errmsg = false
	local kind = type(value)
	local matcher = self[kind]
	if matcher then
		local valuematch = self[value]
		local othermatch = self[other]
		matched = (valuematch == other and othermatch == value)
		if not matched then
			if valuematch == nil and othermatch == nil then
				if value == other then
					matched = true
				elseif kind == type(other) then
					matched, errmsg = matcher(self, value, other)
					matcher = self.metatable
					if matched and matcher then
						self[#self+1] = self.metakey
						matched, errmsg = matcher(self, getmetatable(value), getmetatable(other))
						self[#self] = nil
					end
				else
					errmsg = self:error "not matched"
				end
			else
				errmsg = self:error "wrong match"
			end
		end
	elseif value == other then
		matched = true
	else
		errmsg = self:error "not matched"
	end
	return matched, errmsg
end

-- aliases
module.table = module.matchtable 
module["function"] = module.matchfunction
module.metatable = module.match

return module
