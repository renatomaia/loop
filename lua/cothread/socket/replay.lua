--------------------------------------------------------------------------------
-- Project: LuaCooperative                                                    --
-- Release: 2.0 beta                                                          --
-- Title  :                                                                   --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------

local socket = require "socket.core"
local tabop = require "loop.table"

local lastcode = string.byte("Z")
local function nextstr(text)
	for i = #text, 1, -1 do
		local code = text:byte(i)
		if code < lastcode then
			return text:sub(1,i-1)..string.char(code+1)..string.rep("A", #text-i)
		end
	end
	return string.rep("A", #text+1)
end

local lastused = ""
nameof = tabop.memoize(function(value)
	lastused = nextstr(lastused)
	return lastused
end)

local output = assert(io.open("socketreplay.lua", "w"))
output:write[[
local socket = require "socket.core"
local methods = getmetatable(socket.tcp()).__index
local Viewer = require "loop.debug.Viewer"
local function show(id, ...)
	Viewer:print(id,": ", ...)
	return ...
end
]]

local now = socket.gettime
local timestamp = now()

local function wrap(call, name, func)
	local function funcend(params, ...)
		local count = select("#", ...)
		for i = 1, count do
			local val = select(i, ...)
			if type(val) == "userdata" then
				output:write(nameof[val])
			else
				output:write("_")
			end
			if i == count then
				output:write("=")
			else
				output:write(",")
			end
		end
		output:write(call:format(name, params, name, params))
		output:flush()
		return ...
	end
	return function(...)
		local now = now()
		output:write("socket.sleep(",now-timestamp,")\n")
		timestamp = now
		local params = {}
		local count = select("#", ...)
		for i = 1, count do
			local val = select(i, ...)
			local valtype = type(val)
			if valtype == "userdata" then
				params[#params+1] = nameof[val]
			elseif valtype == "table" then
				params[#params+1] = "{"
				for _, value in ipairs(val) do
					params[#params+1] = nameof[value]
					params[#params+1] = ","
				end
				params[#params+1] = "}"
			elseif valtype == "string" then
				params[#params+1] = string.format("%q", val)
			else
				params[#params+1] = tostring(val)
			end
			if i < count then
				params[#params+1] = ","
			end
		end
		return funcend(table.concat(params), func(...))
	end
end

local object = assert(socket.tcp())
for name, func in pairs(socket) do
	if type(func) == "function" then
		socket[name] = wrap("show('socket.%s(%s)', socket.%s(%s))\n", name, func)
	end
end
local methods = getmetatable(object).__index
for name, func in pairs(methods) do
	if type(func) == "function" then
		methods[name] = wrap("show('methods.%s(%s)', methods.%s(%s))\n", name, func)
	end
end
