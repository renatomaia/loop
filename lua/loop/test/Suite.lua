
local error = error
local pairs = pairs

local oo = require "loop.cached"

module("loop.test.Suite", oo.class)

function __call(self, results)
	local failed
	for name, test in pairs(self) do
		if not results:test(name, test, results) then
			failed = true
		end
	end
	if failed then error("FAILED", 2) end
end
