local _G = require "_G"
local error = _G.error
local ipairs = _G.ipairs

local oo = require "loop.cached"
local class = oo.class

local Fixture = class()

function Fixture:__call(...)
	local runner = self.runner
	self.runner = nil
	local setup = self.setup
	local teardown = self.teardown
	local failed = false
	local iterfunc, state, initvar
	local tests = self.tests
	if tests == nil then
		iterfunc, state, initvar = ipairs(self)
	else
		iterfunc, state, initvar = pairs(tests)
	end
	for name, test in iterfunc, state, initvar do
		local setupname = "setup"
		local teardownname = "teardown"
		if tests == nil and #self == 1 then
			name = nil
		else
			setupname = name.."."..setupname
			teardownname = name.."."..teardownname
		end
		if setup ~= nil and not runner(setupname, setup, self, ...) then
			failed = true
		elseif not runner(name, test, self, ...) then
			failed = true
		end
		if teardown ~= nil and not runner(teardownname, teardown, self, ...) then
			failed = true
			break
		end

--_G.io.write("Press any key to continue ... "); _G.io.flush(); _G.io.read()

	end
	if failed then error("FAILED", 2) end
end

return Fixture
