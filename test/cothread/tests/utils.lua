local function see(...)
	require("loop.debug.Viewer"):write(...)
	print()
end

local newcoro = coroutine.create
local yield = coroutine.yield
local concat = table.concat
local sort = table.sort

local obj = {}
function getparams()
	return obj, false, nil
end
function chkresults(...)
	assert(select("#", ...) == 3)
	assert(select(1, ...) == obj)
	assert(select(2, ...) == false)
	assert(select(3, ...) == nil)
	return ...
end

local function defaultbody(count, _ENV, ...)
	if count > 0 then
		return defaultbody(count-1, _ENV, _ENV.yield("yield", nil, ...))
	end
	return ...
end
function Yielder(count)
	return function(_ENV, ...) return defaultbody(count, _ENV, ...) end
end

local logmeta = {
	__tostring = function(log) return "["..concat(log, " ").."]" end
}
local log = setmetatable({}, logmeta)
local function logname(name, ...)
	log[#log+1] = name
	return ...
end

local function newtask(name, env, action)
	local env = setmetatable({}, env)
	function env.yield(...) return logname(name, yield(...)) end
	if _ENV == nil then setfenv(action, env) end
	local task = newcoro(function(...) return action(env,logname(name, ...)) end)
	if env.verbose ~= nil then
		env.verbose.viewer.labels[task] = name
	end
	return task
end

local function addextratasks(cothread, envmeta, count)
	local threads = {}
	local continue = true
	local function body(_ENV, ...)
		if continue then return body(_ENV, _ENV.yield("yield", nil, ...)) end
		return ...
	end
	local function checker(_ENV, ...)
		continue = false
		local i = 1
		for thread in _ENV.allready() do
			if threads[i%count+1] ~= thread then
				continue = true
				break
			end
			i = i+1
		end
		if continue then return checker(_ENV, _ENV.yield("yield", nil, ...)) end
		return ...
	end
	for i=1, count do
		threads[i] = newtask(i, envmeta, i==1 and checker or body)
		assert(cothread.schedule(threads[i]) == threads[i])
	end
end

do
	local count = 0
	local backup = assert
	function assert(...)
		count = count+1
		if count%100 == 0 then
			io.stdout:write(".")
			io.stdout:flush()
		end
		return backup(...)
	end
	function assertCount()
		local result = count
		count = 0
		return result
	end
end

local extracount = 3
local cothread
function setTarget(val)
	cothread = val
end
local test
function newTest(val)
	test = val
end
function testCase(case)
	local extratasks = true
	repeat
		extratasks = not extratasks
		
		local seq = {}
		local tsk = {}
		local sch = {}
		local envmeta = {
			__index = function(_, name)
				local val = tsk[name]
				if val == nil then
					val = case[name]
					if val == nil then
						val = test[name]
						if val == nil then
							val = cothread[name]
							if val == nil then
								val = coroutine[name]
								if val == nil then
									val = _G[name]
								end
							end
						end
					end
				end
				return val
			end
		}
		-- add extra tasks if necessary
		if extratasks then
			addextratasks(cothread, envmeta, extracount)
		end
		-- find out main threads are mentioned in the title
		for idx, title in ipairs(test) do
			local name = title:match("^([%a_][%w_]*)")
			seq[idx] = name
			seq[name] = idx
		end
		-- create threads
		for name, kind in pairs(case) do
			local task = test.tasks[name]
			if task ~= nil then
				local kind = case[name]
				if case[kind] ~= nil then
					tsk[name] = kind -- reference to other thread
				elseif kind == "outer" then
					tsk[name] = task
				else
					tsk[name] = newtask(name, envmeta, task)
					if seq[name] == nil then
						tsk[#tsk+1] = name
					end -- non main thread
				end
			end
		end
		-- resolve threads references
		for name, task in pairs(tsk) do
			if type(name) ~= "number" and type(task) == "string" then
				tsk[name] = assert(tsk[task], "missing thread reference: "..name)
			end
		end
		-- register non-main threads in order of their alphabetic name
		sort(tsk)
		for _, name in ipairs(tsk) do
			local task = tsk[name]
			local kind = case[name]
			if kind == "ready" then
				assert(cothread.schedule(task) == task)
			elseif kind ~= "none" then
				local op, arg = string.match(kind, "^(%l+)%s+([^%s]-)$")
				if op ~= nil then
					assert(cothread.schedule(task, op, case[arg] or test[arg]) == task)
				else
					assert(cothread.schedule(task, kind) == task)
				end
			end
		end
		-- execute main threads
		for phase, expectedlog in ipairs(case) do
			if extratasks and cothread.hasready() == false then
				addextratasks(cothread, envmeta, extracount)
			end
			local name = seq[phase]
			if name ~= nil then
				local task = tsk[name]
				local kind = case[name]
				if kind == "outer" then
					local env = setmetatable({}, envmeta)
					if _ENV == nil then setfenv(task, env) end
					task(env)
					cothread.run()
				elseif kind == "none" then
					cothread.run(cothread.step(task))
				elseif kind == "ready" then
					assert(cothread.schedule(task, "next") == task)
					cothread.run()
				else
					error("invalid scheduling for task "..name..", got "..kind)
				end
			else
				cothread.run()
			end
			local pos = 1
			for expected in expectedlog:gmatch("[^%s]+") do
				if expected:find("...", 1, true) then
					if extratasks then
						repeat
							for i=1, extracount do
								if log[pos+i-1] ~= i then
									error("wrong event at phase "..phase.." at "..pos..": "..tostring(log))
								end
							end
							pos = pos+extracount
						until expected == "..." or log[pos] ~= 1
					end
				else
					if log[pos] ~= expected then
						error("wrong event at phase "..phase.." at "..pos..": "..tostring(log))
					end
					pos = pos+1
				end
			end
			if log[pos] ~= nil then error("extra events at phase "..phase.." at "..pos..": "..tostring(log)) end
			log = setmetatable({}, logmeta)
		end
		for i=1, extracount do
			assert(cothread.hasready() == false)
			cothread.run()
			assert(next(log) == nil)
		end
		-- unschedule all threads currently scheduled
		for _, iter in ipairs{cothread.allready,cothread.alldeferred} do
			while true do
				local f,s,i = iter()
				local thread = f(s,i)
				if thread == nil then break end
				cothread.unschedule(thread)
			end
		end
		if cothread.allsignals then
			for signal in cothread.allsignals() do
				while true do
					local f,s,i = cothread.allwaiting(signal)
					local thread = f(s,i)
					if thread == nil then break end
					cothread.unschedule(thread)
				end
			end
		end
		for _, iter in ipairs{
			cothread.allready,
			cothread.alldeferred,
			cothread.allsignals,
		} do
			for _ in iter() do
				error("unable to reset scheduler")
			end
		end
	until extratasks == true
end
