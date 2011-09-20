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

local idpat = "^[%a_][%w_]*$"
local keywords = {
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
local codefmt = "\\%.3d"
local function escapecode(char)
	return escapecodes[char] or codefmt:format(byte(char))
end
local function escapechar(char)
	return "\\"..char
end

local Viewer = class{
	maxdepth = -1,
	indentation = "  ",
	linebreak = "\n",
	prefix = "",
	output = defaultoutput(),
}

function Viewer:writeplain(value, buffer)
	buffer:write(luatostring(value))
end

function Viewer:writestring(value, buffer)
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
end

function Viewer:writetable(value, buffer, history, prefix, maxdepth)
	buffer:write("{")
	if not self.nolabels then 
		buffer:write(" --[[",history[value],"]]")
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
					self:writevalue(value[i], buffer, history, newprefix, maxdepth)
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
					if not self.nofields
					and keytype == "string"
					and not keywords[key]
					and key:match(idpat)
					then
						buffer:write(key)
					else
						buffer:write("[")
						self:writevalue(key, buffer, history, newprefix, maxdepth)
						buffer:write("]")
					end
					buffer:write(" = ")
					self:writevalue(field, buffer, history, newprefix, maxdepth)
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
end

Viewer["string"] = Viewer.writestring
Viewer["table"] = Viewer.writetable

function Viewer:label(value)
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

function Viewer:writevalue(value, buffer, history, prefix, maxdepth)
	local luatype = type(value)
	if luatype == "nil" or luatype == "boolean" or luatype == "number" then
		self:writeplain(value, buffer)
	elseif luatype == "string" then
		self:string(value, buffer)
	else
		local label = history[value]
		if label == nil then
			if self.nolabels
				then label = luatype
				else label = self.labels[value] or self:label(value)
			end
			history[value] = label
			local writer = self[luatype]
			if writer then
				return writer(self, value, buffer, history, prefix, maxdepth)
			end
		end
		buffer:write(label)
	end
end

function Viewer:writeto(buffer, ...)
	local prefix   = self.prefix
	local maxdepth = self.maxdepth
	local history  = self.history or {}
	for i = 1, select("#", ...) do
		if i ~= 1 then buffer:write(", ") end
		self:writevalue(select(i, ...), buffer, history, prefix, maxdepth)
	end
end

function Viewer:write(...)
	self:writeto(self.output, ...)
end

local function add(self, ...)
	for i = 1, select("#", ...) do self[#self+1] = select(i, ...) end
end
function Viewer:tostring(...)
	local buffer = { write = add }
	self:writeto(buffer, ...)
	return concat(buffer)
end

function Viewer:packnames(packages)
	if packages == nil then packages = loaded end
	-- create new table for labeled values
	local labels = { __mode = "k" }
	setmetatable(labels, labels)
	self.labels = labels
	-- label currently loaded packages
	for name, pack in pairs(packages) do
		if labels[pack] == nil then
			labels[pack] = name
			if type(pack) == "table" then
				-- label members of the package
				for field, member in pairs(pack) do
					local kind = type(member)
					if labels[member] == nil
					and (kind == "function" or kind == "userdata")
					and field:match(idpat)
					then
						labels[member] = name.."."..field
					end
				end
			end
		end
	end
end

if loaded then Viewer:packnames(loaded) end

return Viewer
