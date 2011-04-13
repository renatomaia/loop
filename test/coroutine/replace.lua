local coroutine = require "coroutine.replace"

do
	print("resuming thread that terminates successfully")
	local co
	co = coroutine.create(function(...)
		assert(coroutine.running(co) == co)
		assert(coroutine.status(co) == "running")
		return ...
	end)
	assert(coroutine.status(co) == "suspended")
	local ok, a,b,c = coroutine.resume(co, 1,2,3)
	assert(ok)
	assert(a==1 and b==2 and c==3)
	assert(coroutine.status(co) == "dead")
end

do
	print("resuming thread that terminates with error")
	local co = coroutine.create(function() error("oops!") end)
	assert(coroutine.status(co) == "suspended")
	local ok, err = coroutine.resume(co)
	assert(ok == false)
	assert(err:find(": oops!$"))
	assert(coroutine.status(co) == "dead")
end

do
	print("resuming thread that yields execution once")
	local co = coroutine.create(function(...)
		local a,b,c = coroutine.yield(...)
		assert(a==4 and b==5 and c==6)
		return a,b,c
	end)
	assert(coroutine.status(co) == "suspended")
	local ok, a,b,c = coroutine.resume(co, 1,2,3)
	assert(ok)
	assert(a==1 and b==2 and c==3)
	assert(coroutine.status(co) == "suspended")
	local ok, a,b,c = coroutine.resume(co, 4,5,6)
	assert(ok)
	assert(a==4 and b==5 and c==6)
	assert(coroutine.status(co) == "dead")
end

do
	print("resuming thread that is replaced by others")
	local c3 = coroutine.create(function(msg)
		while true do msg = coroutine.yield("c3: "..msg) end
	end)
	local c2 = coroutine.create(function(msg)
		msg = coroutine.replace(c3, msg)
		coroutine.replace(c3, "c2: "..msg)
		error("Oops!")
	end)
	local c1 = coroutine.create(function(msg)
		msg = coroutine.replace(c2, msg)
		coroutine.replace(c3, "c1: "..msg)
		error("Oops!")
	end)
	assert(coroutine.status(c1) == "suspended")
	assert(coroutine.status(c2) == "suspended")
	assert(coroutine.status(c3) == "suspended")
	local ok, msg = coroutine.resume(c1, "hi!")
	assert(ok)
	assert(msg == "c3: hi!")
	assert(coroutine.status(c1) == "suspended")
	assert(coroutine.status(c2) == "suspended")
	assert(coroutine.status(c3) == "suspended")
	local ok, msg = coroutine.resume(c1, "hello!")
	assert(ok)
	assert(msg == "c3: c1: hello!")
	assert(coroutine.status(c1) == "suspended")
	assert(coroutine.status(c2) == "suspended")
	assert(coroutine.status(c3) == "suspended")
	local ok, msg = coroutine.resume(c2, "bye!")
	assert(ok)
	assert(msg == "c3: c2: bye!")
	assert(coroutine.status(c1) == "suspended")
	assert(coroutine.status(c2) == "suspended")
	assert(coroutine.status(c3) == "suspended")
end

do
	print("resuming thread that is replaced by one that raises an error")
	local er = coroutine.create(function() error("oops!") end)
	local co = coroutine.create(function(...) coroutine.replace(...) end)
	assert(coroutine.status(co) == "suspended")
	assert(coroutine.status(er) == "suspended")
	local ok, err = coroutine.resume(co, er)
	assert(ok == false)
	assert(err:find(": oops!$"))
	assert(coroutine.status(co) == "suspended")
	assert(coroutine.status(er) == "dead")
end
