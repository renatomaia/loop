--------------------------------------------------------------------------------
-- Project: LOOP Debugging Utilities for Lua                                  --
-- Release: 2.0 alpha                                                         --
-- Title  : Visualization of Lua Values                                       --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
-- Date   : 24/02/2006 19:42                                                  --
--------------------------------------------------------------------------------

local require = require

local select       = select
local type         = type
local next         = next
local pairs        = pairs
local ipairs       = ipairs
local unpack       = unpack
local rawget       = rawget
local rawset       = rawset
local getmetatable = getmetatable
local luatostring  = tostring

local string = require "string"
local table  = require "table"
local io     = require "io"
local oo     = require "loop.base"

module("loop.debug.Viewer", oo.class)

maxdepth = 2
identation = "  "
prefix = ""
output = io.output()

function rawtostring(value)
	local meta = getmetatable(value)
	if meta then
		local custom = rawget(meta, "__tostring")
		if custom then
			rawset(meta, "__tostring", nil)
			local raw = luatostring(value)
			rawset(meta, "__tostring", custom)
			custom = luatostring(value)
			if raw == custom
				then return raw
				else return raw.." ("..custom..")"
			end
		end
	end
	return luatostring(value)
end

local function writetable(buffer, table, history, identation, prefix, maxdepth)
	if history[table] then
		buffer:write(rawtostring(table))
	else
		buffer:write("{ ")
		buffer:write(rawtostring(table))
		history[table] = true
		local key, value = next(table)
		if key then
			if maxdepth == 0 then
				buffer:write(" ... ")
			else
				maxdepth = maxdepth - 1
				repeat
					local prefix = prefix..identation
					buffer:write("\n")
					buffer:write(prefix)
					
					local luatype = type(key)
					if luatype == "string" and key:match("^[%a_][%w_]*$") then
						buffer:write(key)
					else
						buffer:write("[")
						if luatype == "table" then
							writetable(buffer, key, history, identation, prefix, maxdepth)
						elseif luatype == "string" then
							buffer:write(string.format("%q", key))
						else
							buffer:write(rawtostring(key))
						end
						buffer:write("]")
					end
					
					buffer:write(" = ")

					luatype = type(value)
					if luatype == "table" then
						writetable(buffer, value, history, identation, prefix, maxdepth)
					elseif luatype == "string" then
						buffer:write(string.format("%q", value))
					else
						buffer:write(rawtostring(value))
					end
					buffer:write(",")
					
					key, value = next(table, key)
				until not key
				buffer:write("\n")
				buffer:write(prefix)
			end
		else
			buffer:write(" ")
		end
		buffer:write("}")
	end
end

function writeto(self, buffer, value)
	local luatype = type(value)
	if luatype == "table" then
		writetable(buffer, value, {}, self.identation, self.prefix, self.maxdepth)
	elseif luatype == "string" then
		buffer:write(string.format("%q", value))
	else
		buffer:write(rawtostring(value))
	end
	return buffer:flush()
end


function tostring(self, value)
	local buffer = {
		write = table.insert,
		flush = table.concat,
	}
	return self:writeto(buffer, value)
end

function write(self, ...)
	local output = self.output
	for i = 1, select("#", ...) do
		self:writeto(output, select(i, ...))
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function equivalent(value, other, history)
	if not history then history = {} end
	if value == other then
		return true
	elseif type(value) == type(other) then
		if history[value] == other then
			return true
		elseif not history[value] and type(value) == "table" then
			history[value] = other
			local keysfound = {}
			for key, field in pairs(value) do
				local otherfield = other[key]
				if otherfield == nil then
					local success = false
					for otherkey, otherfield in pairs(other) do
						if
							equals(key, otherkey, history) and
							equals(field, otherfield, history)
						then
							keysfound[otherkey] = true
							success = true
							break
						end
					end
					if not success then
						return false
					end
				elseif equals(field, otherfield, history) then
					keysfound[key] = true
				else
					return false
				end
			end
			for otherkey, otherfield in pairs(other) do
				if not keysfound[otherkey] then
					return false
				end
			end
			return true
		end
	end
	return false
end
