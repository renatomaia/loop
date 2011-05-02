local src2test = require "loop.tests.library.src2test"
local Queue = require "loop.collection.Queue"

local function create(spec)
	local instance = Queue()
	for item in spec:gmatch("([^, ]+)") do
		if item == "nil" then item = nil end
		instance:enqueue(item)
	end
	return instance
end

local autocases = {
	{ pat = "(%?+)", args = "(ID)",
		"",
		" x",
		" x y",
	},
}

return function()
	src2test("Queue", create, autocases, "blackbox")
end
