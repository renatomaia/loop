local oo = require "loop.multiple"
local class = oo.class
local hierarchy = require "loop.hierarchy"

shared = class{"E"}
start = class({"A"},
	class{"B"},
	class({"C"},
		class{"D"},
		shared),
	shared)

do
	local res = ""
	for class in hierarchy.topdown(start) do
		res = res..class[1]
	end
	print(res)
	assert(res == "BDECA")
end
