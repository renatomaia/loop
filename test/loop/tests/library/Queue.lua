local src2test = require "loop.tests.library.src2test"
local Queue = require "loop.collection.Queue"

local function newcreate(count)
	return function (spec)
		local instance = Queue()
		for i=1, count do assert(instance:enqueue(i) == i) end
		for i=1, count do assert(instance:dequeue() == i) end
		for item in spec:gmatch("([^, ]+)") do
			if item == "nil" then item = nil end
			instance:enqueue(item)
		end
		return instance
	end
end

local autocases = {
	{ pat = "(%?+)", args = "(ID)",
		"",
		" x",
		" x y",
		" nil",
		" x nil",
		" nil y",
		" x nil y",
	},
}

return function()
	src2test("Queue", newcreate(0), autocases, "blackbox")
	src2test("Queue", newcreate(1), autocases, "blackbox")
	src2test("Queue", newcreate(2), autocases, "blackbox")
	src2test("Queue", newcreate(10^3), autocases, "blackbox")
end
