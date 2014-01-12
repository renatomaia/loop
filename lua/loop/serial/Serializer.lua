-- Project: LOOP Class Library
-- Release: 3.0
-- Title  : Serializer that Serialize Values to Lua Code
-- Author : Renato Maia <maia@inf.puc-rio.br>

local _G = require "_G"
local error = _G.error
local getmetatable = _G.getmetatable
local pairs = _G.pairs
local tostring = _G.tostring
local type = _G.type

local string = require "string"
local byte = string.byte
local dump = string.dump
local gsub = string.gsub

local math = require "math"
local inf = math.huge

local package = require "package"
local debug = package.loaded.debug -- only if available
local getupvalue = debug and debug.getupvalue
local upvalueid = debug and debug.upvalueid

local oo = require "loop.base"
local class = oo.class



local escapecodes = {
	["\b"] = [[\b]],
	["\f"] = [[\f]],
	["\n"] = [[\n]],
	["\t"] = [[\t]],
	["\v"] = [[\v]],
}
local codefmt = "\\%.3d"
local function escapecode(char)
	return escapecodes[char] or codefmt:format(byte(char))
end
local function escapechar(char)
	return "\\"..char
end

local boolean = {
	[true] = "true",
	[false] = "false",
}

local function boolean2lua(value)
	return boolean[value]
end

local function number2lua(value)
	if value ~= value then
		return "0/0"
	elseif value == inf then
		return "1/0"
	elseif value == -inf then
		return "-1/0"
	end
	return tostring(value)
end

local function string2lua(value)
	value = gsub(value, '[\\"]', escapechar)
	value = gsub(value, '[^%p%w ]', escapecode)
	return '"'..value..'"'
end




local Serializer = class{
	varprefix = "",
	getmetatable = getmetatable,
	getupvalue = getupvalue,
	upvalueid = upvalueid,
}

if _G._VERSION=="Lua 5.1" then Serializer.getfenv = _G.getfenv end

local converter2lua = {
	boolean = boolean2lua,
	number = number2lua,
	string = string2lua,
}
function Serializer:register(loaded)
	for name, module in pairs(loaded) do
		self[module] = "require('"..name.."')"
		if type(module) == "table" then
			for field, value in pairs(module) do
				local converter = converter2lua[type(field)]
				if converter ~= nil and converter2lua[type(value)] == nil then
					self[value] = "require('"..name.."')["..converter(field).."]"
				end
			end
		end
	end
end

function Serializer:newlabel()
	local count = (self.lastlabel or 0) + 1
	self.lastlabel = count
	return "v"..count
end

function Serializer:number(value)
	return number2lua(value)
end

function Serializer:string(value)
	return string2lua(value)
end

function Serializer:newlabel()
	local count = (self.lastlabel or 0) + 1
	self.lastlabel = count
	return "v"..count
end

function Serializer:table(value, partial)
	local label
	if partial == nil then
		partial = {}
		self[value] = partial
		-- attempt to serialize contents
		for key, value in pairs(value) do
			key = self:serialize(key)
			value = self:serialize(value)
			partial[key] = value
		end
		-- check if table was parially written in a label
		label = self[value]
		if label ~= partial then
			for key, value in pairs(partial) do
				self:write(label,"[",key,"] = ",value,"\n")
			end
			partial = nil -- table was completelly written
		end
	end
	-- write serialized contents (part or all content)
	if partial ~= nil then
		label = self:newlabel()
		self[value] = label
		self:write(self.varprefix,label," = {\n")
		for key, value in pairs(partial) do
			self:write("\t[",key,"] = ",value,",\n")
			partial[key] = nil -- this entry shall not be written again
		end
		self:write("}\n")
	end
	-- write serialized metatable
	local getmetatble = self.getmetatable
	if getmetatable then
		local meta = getmetatable(value)
		if meta ~= nil then
			meta = self:serialize(meta)
			self:write("setmetatable(",label,", ",meta,")\n")
		end
	end
	return label
end

Serializer["function"] = function(self, value)
	
	-- serialize the function
	local label = self:newlabel()
	local opcodes = self:string(dump(value))
	self:write(self.varprefix,label," = load(",opcodes,")\n")
	self[value] = label

	-- serialize upvalues
	local getupvalue = self.getupvalue
	if getupvalue then
		local upvalueid = self.upvalueid
		local upvalues = self.upvalues
		if upvalueid and upvalues == nil then
			upvalues = {}
			self.upvalues = upvalues
		end
		for i = 1, inf do
			local upname, upvalue = getupvalue(value, i)
			if upname == nil then break end
			if upvalueid then
				local upid = upvalueid(value, i)
				local upinfo = upvalues[upid]
				if upinfo == nil then
					upvalues[upid] = {func=label,index=i}
				else
					self:write("upvaluejoin(",label,", ",i,", ",
					                        upinfo.func,", ",upinfo.index,")\n")
					upvalue = nil -- no need to serialize upvalue's contents
				end
			end
			if upvalue ~= nil then
				upvalue = self:serialize(upvalue)
				self:write("setupvalue(",label,", ",i,", ",upvalue,")\n")
			end
		end
	end
	
	-- serialize environment
	local getfenv = self.getfenv
	if getfenv then
		local env = self:serialize(getfenv(value))
		self:write("setfenv(",label,", ",env,")\n")
	end
	
	return label
end

function Serializer:serialize(value)
	local result
	if value == nil then
		result = "nil"
	else
		result = boolean[value]
		if result == nil then
			local valuetype = type(value)
			if valuetype == "number" then
				result = self:number(value)
			elseif valuetype == "string" then
				result = self:string(value)
			else
				result = self[value]
				if type(result) ~= "string" then
					local serializer = self[valuetype]
					if not serializer then
						error("unable to serialize a "..valuetype)
					end
					result = serializer(self, value, result)
				end
			end
		end
	end
	return result
end

return Serializer
