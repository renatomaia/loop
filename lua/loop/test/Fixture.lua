local _G = require "_G"
local error = _G.error
local ipairs = _G.ipairs

local oo = require "loop.cached"
local class = oo.class

local Fixture = class()

function Fixture:__call(runner, ...)
	local failed
	local setup = self.setup
	if setup ~= nil and not runner("setup", setup, self, runner, ...) then
		failed = true
	elseif #self > 0 then
		for index, test in ipairs(self) do
			if not runner(nil, test, runner, ...) then
				failed = true
				break
			end
		end
	else
		local test = self.test
		if test ~= nil and not runner(nil, test, self, runner, ...) then
			failed = true
		end
	end
	local teardown = self.teardown
	if teardown ~= nil and not runner("teardown", teardown, self, runner, ...) then
		failed = true
	end
	if failed then error("FAILED", 2) end
end

return Fixture
