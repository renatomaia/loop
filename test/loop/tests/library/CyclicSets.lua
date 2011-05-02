local src2test = require "loop.tests.library.src2test"
local CyclicSets = require "loop.collection.CyclicSets"

local function create(spec)
	local instance = CyclicSets()
	for set in spec:gmatch("([^|]+)") do
		local last
		for item in set:gmatch("([^, ]+)") do
			instance:add(item, last)
			last = item
		end
	end
	return instance
end

local autocases = {
	{ pat = "(%.%.+)", args = "(%w+)(ID)(%w+)",
		"%1 %3",
		"%1 a %3",
		"%1 a b %3",
		"%1 a b c %3",
	},
	{ pat = "(%?+)", args = "(ID)",
		"",
		" x",
		" x y",
		"| x",
		"| x y",
		" x | y",
		" x y | z",
		" x | y z",
		" x y | w z",
	},
}

return function()
	src2test("CyclicSets", create, autocases)
end
