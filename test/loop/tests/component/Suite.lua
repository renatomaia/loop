local base        = require "loop.component.base"
local wrapped     = require "loop.component.wrapped"
local contained   = require "loop.component.contained"
local dynamic     = require "loop.component.dynamic"
local intercepted = require "loop.component.intercepted"

local Suite = require "loop.test.Suite"

local Tests = {
	AddPorts = require "loop.tests.component.AddPorts",
	Context  = require "loop.tests.component.Context",
}

local FullSuite = Suite()
for name, test in pairs(Tests) do
	FullSuite[name] = Suite{
		BasePortsOnBaseComps             = function() return test(base     , base       ) end,
		BasePortsOnWrappedComps          = function() return test(wrapped  , base       ) end,
		BasePortsOnContainedComps        = function() return test(contained, base       ) end,
		BasePortsOnDynamicComps          = function() return test(dynamic  , base       ) end,
		InterceptedPortsOnBaseComps      = function() return test(base     , intercepted) end,
		InterceptedPortsOnWrappedComps   = function() return test(wrapped  , intercepted) end,
		InterceptedPortsOnContainedComps = function() return test(contained, intercepted) end,
		InterceptedPortsOnDynamicComps   = function() return test(dynamic  , intercepted) end,
	}
end
return FullSuite
