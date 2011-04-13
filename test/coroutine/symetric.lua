local luacoro = require "coroutine"
local coroutine = require "coroutine.symetric"

local function checkstate(running, ...)
	assert(coroutine.status(running) == "running")
	for i = 1, select("#", ...) do
		assert(coroutine.status((select(i, ...))) == "suspended")
	end
end

local function pingpongtest(desc)
	if desc == nil then
		desc = ""
	else
		desc = ", "..desc
	end
	print("resuming thread that resumes the original thread back"..desc)
	local yielder = coroutine.create(function(thread, ...)
		checkstate(coroutine.running(), thread)
		coroutine.resume(thread, ...)
	end)
	local main = coroutine.running()
	checkstate(main, yielder)
	local a,b,c = coroutine.resume(yielder, main, 1,2,3)
	checkstate(main, yielder)
	assert(a==1 and b==2 and c==3)
end

do
	pingpongtest()
end

do
	assert(coroutine.resume(coroutine.create(function()
		pingpongtest("inside a coroutine")
		return "OK"
	end)) == "OK")
end

do
	assert(luacoro.resume(luacoro.create(function()
		pingpongtest("inside a plain coroutine")
	end)))
end

do
	print("resuming thread that is replaced by others")
	local M = coroutine.running()
	local A,B,C
	A = coroutine.create(function(msg)
		while true do
			checkstate(A, M,B,C)
			msg = coroutine.resume(M, "A: "..msg)
		end
	end)
	B = coroutine.create(function(msg)
		checkstate(B, M,A,C)
		msg = coroutine.resume(A, msg)
		checkstate(B, M,A,C)
		coroutine.resume(A, "B: "..msg)
		error("Oops!")
	end)
	C = coroutine.create(function(msg)
		checkstate(C, M,A,B)
		msg = coroutine.resume(B, msg)
		checkstate(C, M,A,B)
		coroutine.resume(A, "C: "..msg)
		error("Oops!")
	end)
	checkstate(M, A,B,C)
	assert(coroutine.resume(C, "hi!") == "A: hi!")
	checkstate(M, A,B,C)
	assert(coroutine.resume(C, "hello!") == "A: C: hello!")
	checkstate(M, A,B,C)
	assert(coroutine.resume(B, "bye!") == "A: B: bye!")
	checkstate(M, A,B,C)
end

do
	print("resuming thread that is replaced by one that raises an error")
	local M = coroutine.running()
	local C = coroutine.create(function(...) coroutine.resume(...) end)
	local E = coroutine.create(function() error("oops!") end)
	checkstate(M, C,E)
	local ok, err = pcall(coroutine.resume, C, E)
	assert(ok == false)
	assert(err:find(": oops!\n"))
	checkstate(M, C)
	assert(coroutine.status(E) == "dead")
end
