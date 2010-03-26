-- Project: Lua Code Inspector
-- Release: 1.0 beta
-- Title  : Interactive Application State Inspector
-- Author : Renato Maia <maia@inf.puc-rio.br>

--[===[TODO]
command 'diff' using Matcher
command 'find' using Crawler and Dikstra shortest path algorithm
registration of command processors that are invoked in the debug hook
	command processor that reads commands from a socket whenever data is available
--]===]

local _G = require "_G"
local assert = _G.assert
local error = _G.error
local getfenv = _G.getfenv
local ipairs = _G.ipairs
local loadstring = _G.loadstring
local module = _G.module
local next = _G.next
local pairs = _G.pairs
local rawget = _G.rawget
local rawset = _G.rawset
local require = _G.require
local select = _G.select
local setfenv = _G.setfenv
local setmetatable = _G.setmetatable
local type = _G.type
local xpcall = _G.xpcall

local coroutine = require "coroutine"
local newcoro = coroutine.create
local running = coroutine.running

local package = require "package"
local loaded = package.loaded

local math = require "math"
local inf = math.huge
local min = math.min

local string = require "string"
local format = string.format

local table = require "table"
local sort = table.sort
local unpack = table.unpack

local io = require "io"
local stdin = io.stdin

local debug = require "debug"
local stacktrace = debug.traceback
local getfuncinfo = debug.getinfo
local getlocal = debug.getlocal
local setlocal = debug.setlocal
local getupvalue = debug.getupvalue
local setupvalue = debug.setupvalue
local getenv = debug.getfenv
local gethook = debug.gethook
local sethook = debug.sethook

local loop_table = require "loop.table"
local memoize = loop_table.memoize

local Crawler = require "loop.debug.Crawler"
local Viewer = require "loop.debug.Viewer"

module "inspector"

input = stdin
viewer = Viewer{ maxdepth = 2 }

local infoflags = "Slnuf"

local history = {} -- browsing history
local currentfunc -- current function being inspected
local currentlevel = false -- current stack level being inspected
local currentthread = false -- current thread being inspected

local outoffunc -- function that user requested a step out
local breaklevel
local breaks = memoize(function() return {} end) -- breaks[line][filename]

local lastfunc = {} -- lastfunc[thread] = func
local lastline = {} -- lastline[thread] = line
local source = memoize(function(path)
	local file = io.open(path)
	if file then
		local lines = {}
		for line in file:lines() do
			lines[#lines+1] = line
		end
		file:close()
		return lines
	end
end)

local function call(op, ...)
	if currentthread
		then return op(currentthread, ...)
		else return op(...)
	end
end

local help = {
	{
		title = "Execution",
		"step","over","out","go",
	},
	{
		title = "Break points",
		"mkbp","rmbp","lsbp",
	},
	{
		title = "Context change",
		"up","to","back","hist",
	},
	{
		title = "Inspection",
		"now","src","loc","upv","env","gbl","see",
	},
	
	step = ": executes until next line, stepping into functions",
	over = ": executes until next line, stepping over functions",
	out = ": executes until next line after the current function returns",
	go = ": executes until next break point",
	
	mkbp = "(file, line): adds a break point at line 'line' of all files which paths ends with 'file'",
	rmbp = "(file, line): removes break point",
	lsbp = ": shows all current break points",
	
	up = ": changes the inspection context to the function one level above in the call stack",
	to = "(function|thread): changes the inspection context to a function or thread",
	back = ": goes back to the previous inspection context",
	hist = ": shows all previous inspection context changes",
	
	now = ": shows information about the current inspection context",
	src = "([function|path [, firstline [, lastline]]]): shows the source of the current inspection context, a Lua function, or a file path, if available",
	loc = "([name [, value]]): function that allows to read, write or print local variables of the current inspection context",
	upv = "([name [, value]]): function that allows to read, write or print upvalue variables of the current inspection context",
	env = "([name [, value]]): function that allows to read, write or print environment variables of the current inspection context",
	gbl = "([name [, value]]): function that allows to read, write or print global variables of the current inspection context",
	see = "(...): function that prints all its parameters in a human-readable form using current 'viewer'",
}

local commands
commands = {
	help = function(command)
		local output = viewer.output
		if command then
			output:write(command,help[command],"\n")
		else
			for _, section in ipairs(help) do
				output:write("\n",section.title,":\n")
				for _, command in ipairs(section) do
					output:write("  ",command,help[command],"\n")
				end
			end
		end
	end,
	
	over = function()
		history = {}
		currentfunc = nil
		currentlevel = false
		currentthread = running() or false
	end,

	step = function()
		commands.over()
		breaklevel = inf
	end,

	out = function()
		commands.over()
		outoffunc = call(getfuncinfo, 7, "f").func -- getfuncinfo,call,out,inspection,xpcall,openconsole,breakhook
	end,

	go = function()
		assert(next(breaks) ~= nil,
			"no more break points defined, deativate the inspector before proceeding")
		commands.over()
		breaklevel = nil
	end,
	
	now = function()
		if currentlevel then
			if currentthread
				then viewer:write(currentthread)
				else viewer.output:write("main thread")
			end
			viewer:print(", level ", call(stacktrace, currentlevel,
				currentlevel))
		else
			viewer:print("inactive function ",currentfunc.func)
		end
	end,
	
	to = function(where)
		local kind = type(where)
		if kind ~= "thread" and kind ~= "function" then
			error("invalid inspection value, got `"..kind.."' (`function' or `thread' expected)")
		end
	
		if currentlevel then
			history[#history+1] = currentlevel
			history[#history+1] = currentthread
		else
			history[#history+1] = currentfunc.func
		end
	
		if kind == "thread" then
			currentlevel = 1
			currentthread = where
			currentfunc = call(getfuncinfo, currentlevel, infoflags)
		else
			currentlevel = false
			currentthread = false
			currentfunc = call(getfuncinfo, where, infoflags)
		end
	end,
	
	up = function()
		if currentlevel then
			local next = call(getfuncinfo, currentlevel+1, infoflags)
			if next then
				history[#history+1] = -1
				currentlevel = currentlevel+1
				currentfunc = next
			else
				error("top level reached")
			end
		else
			error("unable to go up in inactive functions")
		end
	end,
	
	back = function()
		if #history > 0 then
			local value = history[#history]
			history[#history] = nil
			local kind = type(value)
			if kind == "number" then
				currentlevel = currentlevel + value
				currentfunc = call(getfuncinfo, currentlevel, infoflags)
			elseif kind == "function" then
				currentlevel = false
				currentthread = false
				currentfunc = call(getfuncinfo, value, infoflags)
			else -- kind == "thread"
				currentthread = value
				currentlevel, history[#history] = history[#history], nil
				currentfunc = call(getfuncinfo, currentlevel, infoflags)
			end
		else
			error("no more backs avaliable")
		end
	end,
	
	hist = function()
		local index = #history
		while history[index] ~= nil do
			local value = history[index]
			local kind = type(value)
			if kind == "number" then
				viewer:print("  up one level")
				index = index-1
			elseif kind == "function" then
				viewer:print("  left inactive ",value)
				index = index-1
			else
				viewer:print("  left ",value or "main thread"," at level ",history[index-1])
				index = index-2
			end
		end
	end,
	
	src = function(path, first, last)
		first = first or 1
		local pathtype = type(path)
		if pathtype ~= "string" then
			local info
			if path == nil and currentfunc then
				info = currentfunc
			elseif pathtype == "function" then
				info = getinfo(path, "S")
			end
			path = info.source
			if path then
				path = path and path:sub(2)
				if info.linedefined > 0 then
					first = info.linedefined+first-1
					if last then
						last = info.linedefined+last
					elseif info.lastlinedefined > 0 then
						last = info.lastlinedefined
					end
				end
			end
		end
		local output = viewer.output
		local lines = source[path]
		if lines then
			for line = first, #lines do
				if not last or line <= last then
					output:write(format("%-5d ", line), lines[line] or "missing line","\n")
				end
			end
		else
			output:write(path,":",first,"-",last,"\n")
		end
	end,
	
	mkbp = function(file, line)
		assert(type(file) == "string", "usage: mkbp(<file>, <line>)")
		assert(type(line) == "number", "usage: mkbp(<file>, <line>)")
		breaks[line][file] = true
	end,
	
	rmbp = function(file, line)
		assert(type(file) == "string", "usage: rmbp(<file>, <line>)")
		assert(type(line) == "number", "usage: rmbp(<file>, <line>)")
		local files = rawget(breaks, line)
		if files then
			files[file] = nil
			if next(files) == nil then
				breaks[line] = nil
			end
		end
	end,
	
	lsbp = function()
		local list = {}
		for line, files in pairs(breaks) do
			for file in pairs(files) do
				list[#list+1] = file..":"..line
			end
		end
		sort(list)
		for _, bp in ipairs(list) do
			viewer:print(bp)
		end
	end,
}

local function results(success, ...)
	if not success then
		io.stderr:write(..., "\n")
	elseif select("#", ...) > 0 then
		viewer:write(...)
		viewer.output:write("\n")
	end
end

local environment = {}

local function openconsole()
	local output = viewer.output
	currentlevel = 7 -- getfuncinfo,call,<cmd>,xpcall,openconsole,breakhook
	local line = currentfunc.currentline
	if showsource and line ~= -1 then
		local func = currentfunc.func
		local path = currentfunc.source:sub(2)
		local source = source[path]
		if source then
			local prevfunc = lastfunc[currentthread]
			local prevline
			if prevfunc == func then
				prevline = min(line,lastline[currentthread])
			else
				lastfunc[currentthread] = func
				prevline = line
			end
			lastline[currentthread] = line+1
			
			for line = prevline, line do
				local sourceline = source[line]
				if sourceline == nil then
					output:write("WARN: '",path,"' does not have line ",line,"\n")
				else
					output:write(format("%-5d", line)," ",sourceline,"\n")
				end
			end
		end
	end
	
	local cmd, errmsg
	repeat
		output:write(
			currentfunc.short_src or currentfunc.what,
			":",
			(currentfunc.currentline ~= -1 and currentfunc.currentline) or
			(currentfunc.linedefined ~= -1 and currentfunc.linedefined) or "?",
			" ",
			currentfunc.namewhat,
			currentfunc.namewhat == "" and "" or " ",
			currentfunc.name or viewer:tostring(currentfunc.func),
			"> "
		)
		cmd = assert(input:read())
		local short = cmd:match("^%s*([%a_][%w_]*)%s*$")
		if short and commands[short]
			then cmd = short.."()"
			else cmd = cmd:gsub("^%s*=", "return ")
		end
		cmd, errmsg = loadstring(cmd, "inspection")
		if cmd then
			setfenv(cmd, environment)
			results(xpcall(cmd, stacktrace))
		else
			output:write(errmsg, "\n")
		end
	until currentfunc == nil
end

local hookbackup = setmetatable({}, {__mode = "k"})

local function removehook(thread)
	local backup = hookbackup[thread]
	if backup then
		sethook(unpack(backup, 1, 3))
		hookbackup[thread] = nil
	else
		sethook()
	end
end

local function setuphook(thread)
	local level = 1
	while true do
		local ended
		if thread
			then ended = not getfuncinfo(thread, level)
			else ended = not getfuncinfo(level)
		end
		if ended then break end
		level = level+1
	end
	
	local hook, mask, count
	if thread
		then hook, mask, count = gethook(thread)
		else hook, mask, count = gethook()
	end
	if hook then
		hookbackup[thread] = {hook, mask, count}
	end
	
	local function breakhook(event, line)
		if hook then hook(event, line) end
		if event == "line" then
			if breaklevel and currentthread ~= thread then
				breaklevel = level
			end
			currentthread = thread
			currentfunc = call(getfuncinfo, 3, infoflags) -- getfuncinfo,call,breakhook
			-- check for break points
			local files = rawget(breaks, line)
			if files then
				local path = currentfunc.source
				for file in pairs(files) do
					if path:find(file, #path-#file+1, true) then
						breaklevel = level
						break
					end
				end
			end
			if breaklevel and breaklevel >= level
			and currentfunc.func ~= outoffunc then
				breaklevel = level
				outoffunc = nil
				return openconsole()
			end
		elseif event == "call" then
			level = level + 1
		elseif event ~= "count" then
			level = level - 1
		end
	end
	
	if thread
		then sethook(thread, breakhook, "crl", count)
		else sethook(breakhook, "crl", count)
	end
	return thread, level
end

--------------------------------------------------------------------------------

function loc(_, which, ...)
	local level = currentlevel -- backup
	if not currentfunc then level = 2 end
	if level then
		local output = viewer.output
		for index = 1, inf do
			local name, value = call(getlocal, level, index)
			if name == nil then break end
			if not which and name then
				output:write(name)
				output:write(" = ")
				viewer:write(value)
				output:write("\n")
			elseif name == which then
				if select("#", ...) == 0
					then return value
					else return call(setlocal, level, index, (...))
				end
			end
		end
	end
end

function upv(_, which, ...)
	local stack = currentfunc -- backup
	if stack == nil then stack = getfuncinfo(2) end
	if stack and stack.func then
		local func = stack.func
		local output = viewer.output
		for index = 1, inf do
			local name, value = getupvalue(func, index)
			if name == nil then break end
			if not which and name then
				output:write(name," = ")
				viewer:write(value)
				output:write("\n")
			elseif name == which then
				if select("#", ...) == 0
					then return value
					else return setupvalue(func, index, (...))
				end
			end
		end
	end
end

function env(_, which, ...)
	local stack = currentfunc -- backup
	if stack == nil then stack = getfuncinfo(2) end
	if stack then
		local env = getfenv(stack.func)
		if which then
			if select("#", ...) == 0
				then return env[which]
				else env[which] = (...)
			end
		else
			viewer:print(env)
		end
	end
end

function gbl(_, which, ...)
	local _G = currentthread and getenv(currentthread) or getfenv(0)
	if which then
		if select("#", ...) == 0
			then return _G[which]
			else _G[which] = (...)
		end
	else
		viewer:print(_G)
	end
end

for name, func in pairs{loc=loc,upv=upv,env=env,gbl=gbl} do
	_M[name] = setmetatable({}, {
		__index = func,
		__newindex = func,
		__call = func,
	})
end

--------------------------------------------------------------------------------

local envmeta = {}

local IndexScopes = { commands, _M, loc, upv, env, gbl }
function envmeta:__index(field)
	local value
	if currentlevel then currentlevel = currentlevel+1 end
	for _, scope in ipairs(IndexScopes) do
		value = scope[field]
		if value ~= nil then break end
	end
	if currentlevel then currentlevel = currentlevel-1 end
	return value
end

local NewIndexScopes = { loc, upv }
function envmeta:__newindex(field, value)
	for _, scope in ipairs(NewIndexScopes) do
		if scope(field, value) then return end
	end
	rawset(self, field, value)
end

setmetatable(environment, envmeta)

--------------------------------------------------------------------------------

function see(...)
	viewer:write(...)
	viewer.output:write("\n")
end

local function ibreaks(breaks, file, line)
	local files = rawget(breaks, line)
	while files do
		file = next(files, file)
		if file then
			return file, line
		end
		line, files = next(breaks, line)
	end
end
function allbreaks()
	return ibreaks, breaks, nil, next(breaks)
end

setbreak = commands.mkbp
removebreak = commands.rmbp

--------------------------------------------------------------------------------

local function hookedcoro(func)
	return (setuphook(newcoro(func)))
end

local function newcrawler()
	local visited = {
		[_M] = true,
		[hookedcoro] = true, -- it is found when two functions share the same
		                     -- upvalue with 'coroutine.create', then during
		                     -- 'activate' when the first function is found its
		                     -- upvalue is replaced with 'hookedcoro'. Later when
		                     -- the crawler reaches the second function it will
		                     -- find 'hookedcoro' in the upvalue.
	}
	for name, value in pairs(_M) do
		visited[value] = true
	end
	return Crawler{ visited = visited }
end

local function replacevalue(old, new, from, how, ...)
	if how == "key" then
		local entry = ...
		from[old] = nil
		from[new] = entry
	elseif how == "entry" then
		local key = ...
		from[key] = new
	elseif how == "upvalue" then
		local name, upvidx = ...
		setupvalue(from, upvidx, new)
	elseif how == "local" then
		local name, locidx, level = ...
		if from
			then setlocal(from, level, locidx, new)
			else setlocal(level, locidx, new)
		end
	end
end

function activate(level)
	local crawler = newcrawler()
	function crawler:foundthread(thread, visited)
		if not visited then
			setuphook(thread)
		end
	end
	function crawler:foundfunction(func, visited, from, how, ...)
		if func == newcoro then
			replacevalue(newcoro, hookedcoro, from, how, ...)
		end
	end
	crawler:crawl()
	viewer:getpackageinfo(loaded)
	local thread, setuphooklevel = setuphook(false)
	currentthread = running() or false
	breaklevel = (level or 1)+setuphooklevel-1
end

function deactivate()
	local crawler = newcrawler()
	function crawler:foundthread(thread, visited)
		if not visited then
			removehook(thread)
		end
	end
	function crawler:foundfunction(func, visited, from, how, ...)
		if func == hookedcoro then
			replacevalue(hookedcoro, newcoro, from, how, ...)
		end
	end
	crawler:crawl()
	local thread, level = removehook(false)
	history = {}
	currentthread = nil
	currentlevel = nil
	currentfunc = nil
	breaklevel = nil
	outoffunc = nil
end
