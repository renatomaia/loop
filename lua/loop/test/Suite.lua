local _G = require "_G"
local error = _G.error
local pairs = _G.pairs

local oo = require "loop.cached"
local class = oo.class

local Suite = class()

function Suite:__call(runner, ...)
	local failed
	for name, test in pairs(self) do
		if not runner(name, test, runner, ...) then
			failed = true
		end
	end
	if failed then error("FAILED", 2) end
end

return Suite
