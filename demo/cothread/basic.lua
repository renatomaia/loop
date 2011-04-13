cothread = require "cothread"
--cothread.verbose:level(3)

function thread(name, limit, next)
	_G[name] = coroutine.create(function(x, from)
		while true do
			print(name..": got "..x.." from "..from)
			if x < limit then
				x, from = coroutine.yield("yield", _G[next], x+1, name)
			else
				x, from = coroutine.yield("suspend", nil, x+1, name)
			end
		end
	end)
end

thread("A", 5, "B")
thread("B", 5, "A")
print("step results: ", cothread.step(A, 1, "main"))

print("\n\n")

thread("C", 10, "D")
thread("D", 10, "C")
cothread.schedule(C)
thread("E", 15, "F")
thread("F", 15, "E")
cothread.schedule(E)
print("step results: ", cothread.run(cothread.step(A, 1, "main")))

print("\n\n")

cothread.schedule(coroutine.create(function()
	coroutine.yield("schedule", coroutine.create(function()
		print("I'm one thread")
	end))
	coroutine.yield("schedule", coroutine.create(function()
		print("I'm other thread")
	end))
	coroutine.yield("last", coroutine.create(function() print("Hello!") end))
	print("How are you?")
	coroutine.yield("suspend", coroutine.create(function() print("Bye!") end))
	print("Oops! This should never execute!")
end))
cothread.run()

--[[
TEST CASES

-- schedule a non-scheduled thread after itself
A = thread("A")
assert(cothread.schedule(A, "after", A) == nil)
cothread.run()

-- non-scheduled thread reschedule itsef after ifself
A = coroutine.create(function()
	assert(cothread.schedule(A, "after", A) == A)
end)
cothread.schedule(thread("1"))
cothread.run(A)

-- scheduled thread reschedule itsef after ifself
A = coroutine.create(function()
	assert(cothread.schedule(A, "after", A) == A)
end)
cothread.schedule(thread("1"))
cothread.schedule(A)
cothread.schedule(thread("2"))
cothread.run()

--]]