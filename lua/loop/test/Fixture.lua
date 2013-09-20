
local error = error
local ipairs = ipairs

local oo = require "loop.cached"

local module = oo.class()

function module.__call(self, results)
	local failed
	if self.setup ~= nil and not results:test("setup", self.setup, self, results) then
		failed = true
	elseif #self > 0 then
		for index, test in ipairs(self) do
			if not results:test(nil, test, results) then
				failed = true
				break
			end
		end
	elseif self.test and not results:test(nil, self.test, self, results) then
		failed = true
	end
	if self.teardown ~= nil and not results:test("teardown", self.teardown, self, results) then
		failed = true
	end
	if failed then error("FAILED", 2) end
end

return module
