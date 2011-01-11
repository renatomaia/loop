-- Project: LOOP Class Library
-- Release: 2.3 beta
-- Title  : Visualization of Lua Values
-- Author : Renato Maia <maia@inf.puc-rio.br>

local _G = require "_G"
local select = _G.select
local type = _G.type
local next = _G.next
local pairs = _G.pairs
local rawget = _G.rawget
local rawset = _G.rawset
local getmetatable = _G.debug and _G.debug.getmetatable -- only if available
                  or _G.getmetatable
local setmetatable = _G.setmetatable
local luatostring = _G.tostring
local loaded = _G.package and _G.package.loaded -- only if available

local math = require "math"
local huge = math.huge

local string = require "string"
local byte = string.byte
local find = string.find
local gmatch = string.gmatch
local gsub = string.gsub
local strrep = string.rep

local table = require "table"
local concat = table.concat

local io = require "io"
local defaultoutput = io.output

local oo = require "loop.base"
local class = oo.class

module(..., class)

maxdepth = -1
indentation = "  "
linebreak = "\n"
prefix = ""
output = defaultoutput()
keywords = {
	["and"] = true,
	["break"] = true,
	["do"] = true,
	["else"] = true,
	["elseif"] = true,
	["end"] = true,
	["false"] = true,
	["for"] = true,
	["function"] = true,
	["if"] = true,
	["in"] = true,
	["local"] = true,
	["nil"] = true,
	["not"] = true,
	["or"] = true,
	["repeat"] = true,
	["return"] = true,
	["then"] = true,
	["true"] = true,
	["until"] = true,
	["while"] = true,
}

local escapecodes = {
	["\b"] = [[\b]],
	["\f"] = [[\f]],
	["\n"] = [[\n]],
	["\t"] = [[\t]],
	["\v"] = [[\v]],
}
local function escapecode(char)
	return escapecodes[char] or "\\"..byte(char)
end
local function escapechar(char)
	return "\\"..char
end

function writevalue(self, buffer, value, history, prefix, maxdepth)
	local luatype = type(value)
	if luatype == "nil" or luatype == "boolean" or luatype == "number" then
		buffer:write(luatostring(value))
	elseif luatype == "string" then
		local quote
		if self.noaltquotes then
			quote = self.singlequotes and "'" or '"'
		else
			local other
			if self.singlequotes then
				quote, other = "'", '"'
			else
				quote, other = '"', "'"
			end
			if find(value, quote, 1, true) and not find(value, other, 1, true) then
				quote = other
			end
		end
		if not self.nolongbrackets
		and not find(value, "[^%d%p%w \n\t]") --no illegal chars for long brackets
		and find(value, "[\\"..quote.."\n\t]") -- one char that looks ugly in quotes
		and find(value, "[%d%p%w]") then -- one char that indicates plain text
			local nesting = {}
			if find(value, "%[%[") then
				nesting[0] = true
			end
			for level in gmatch(value, "](=*)]") do
				nesting[#level] = true
			end
			if next(nesting) == nil then
				nesting = ""
			else
				for i = 1, huge do
					if nesting[i] == nil then
						nesting = strrep("=", i)
						break
					end
				end
			end
			local open = find(value, "\n") and "[\n" or "["
			buffer:write("[", nesting, open, value, "]", nesting, "]")
		else
			value = gsub(value, "[\\"..quote.."]", escapechar)
			value = gsub(value, "[^%d%p%w ]", escapecode)
			buffer:write(quote, value, quote)
		end
	else
		local label = history[value]
		if label then
			buffer:write(label)
		else
			if self.nolabels
				then label = luatype
				else label = self.labels[value] or self:label(value)
			end
			history[value] = label
			if luatype == "table" then
				if self.nolabels
					then buffer:write("{")
					else buffer:write("{ --[[",label,"]]")
				end
				local key, field = next(value)
				if key ~= nil then
					if maxdepth == 0 then
						buffer:write(" ... ")
					else
						maxdepth = maxdepth - 1
						local newprefix = prefix..self.indentation
						local linebreak = self.linebreak
						if not self.noarrays then
							for i = 1, #value do
								buffer:write(linebreak, newprefix)
								if not self.noindices then buffer:write("[", i, "] = ") end
								self:writevalue(buffer, value[i], history, newprefix, maxdepth)
								buffer:write(",")
							end
						end
						repeat
							local keytype = type(key)
							if self.noarrays
							or keytype ~= "number"
							or key<=0 or key>#value or (key%1)~=0
							then
								buffer:write(linebreak, newprefix)
								if not self.nostructs
								and keytype == "string"
								and not self.keywords[key]
								and key:match("^[%a_][%w_]*$")
								then
									buffer:write(key)
								else
									buffer:write("[")
									self:writevalue(buffer, key, history, newprefix, maxdepth)
									buffer:write("]")
								end
								buffer:write(" = ")
								self:writevalue(buffer, field, history, newprefix, maxdepth)
								buffer:write(",")
							end
							key, field = next(value, key)
						until key == nil
						buffer:write(linebreak, prefix)
					end
				elseif not self.nolabels then
					buffer:write(" ")
				end
				buffer:write("}")
			else
				buffer:write(label)
			end
		end
	end
end

function writeto(self, buffer, ...)
	local prefix   = self.prefix
	local maxdepth = self.maxdepth
	local history  = self.history or {}
	for i = 1, select("#", ...) do
		if i ~= 1 then buffer:write(", ") end
		self:writevalue(buffer, select(i, ...), history, prefix, maxdepth)
	end
end

local function add(self, ...)
	for i = 1, select("#", ...) do self[#self+1] = select(i, ...) end
end
function tostring(self, ...)
	local buffer = { write = add }
	self:writeto(buffer, ...)
	return concat(buffer)
end

function write(self, ...)
	self:writeto(self.output, ...)
end

function print(self, ...)
	local output   = self.output
	local prefix   = self.prefix
	local maxdepth = self.maxdepth
	local history  = self.history or {}
	local value
	for i = 1, select("#", ...) do
		value = select(i, ...)
		if type(value) == "string"
			then output:write(value)
			else self:writevalue(output, value, history, prefix, maxdepth)
		end
	end
	output:write("\n")
end

function label(self, value)
	local meta = getmetatable(value)
	if type(meta) == "table" then
		local custom = rawget(meta, "__tostring")
		if custom ~= nil then
			rawset(meta, "__tostring", nil)
			local raw = luatostring(value)
			rawset(meta, "__tostring", custom)
			if self.tostringmeta then
				custom = luatostring(value)
				if custom ~= raw then
					custom = custom.." ("..raw..")"
				end
			else
				custom = raw
			end
			return custom
		end
	end
	return luatostring(value)
end

function package(self, name, pack)
	local labels = self.labels
	labels[pack] = name
	for field, member in pairs(pack) do
		local kind = type(member)
		if
 			labels[member] == nil and
			(kind == "function" or kind == "userdata") and
			field:match("^[%a_]+[%w_]*$")
		then
			labels[member] = name.."."..field
		end
	end
end

function getpackageinfo(self, loaded)
	local luapacks = {
		coroutine = true,
		package   = true,
		string    = true,
		table     = true,
		math      = true,
		io        = true,
		os        = true,
	}
	-- create cache for global values
	labels = { __mode = "k" }
	setmetatable(labels, labels)
	-- cache names of global functions
	for name, func in pairs(loaded["_G"]) do
		if type(func) == "function" then
			labels[func] = name
		end
	end
	-- label loaded Lua library packages
	for name in pairs(luapacks) do
		local pack = loaded[name]
		if pack then self:package(name, pack) end
	end
	-- label other loaded packages
	for name, pack in pairs(loaded) do
		if not luapacks[name] and type(pack) == "table" then
			self:package(name, pack)
		end
	end
end

if loaded then _M:getpackageinfo(loaded) end
