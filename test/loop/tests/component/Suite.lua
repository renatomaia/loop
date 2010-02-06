local base        = require "loop.component.base"
local wrapped     = require "loop.component.wrapped"
local contained   = require "loop.component.contained"
local dynamic     = require "loop.component.dynamic"
local intercepted = require "loop.component.intercepted"

local Suite = require "loop.test.Suite"

local Tests = {
	AddPorts = require "loop.tests.component.AddPorts",
	--Context  = require "loop.tests.component.Context",
}

local FullSuite = Suite()
for name, maketest in pairs(Tests) do
	FullSuite[name] = Suite{
		BasePortsOnBaseComps             = maketest(base     , base       ),
		BasePortsOnWrappedComps          = maketest(wrapped  , base       ),
		BasePortsOnContainedComps        = maketest(contained, base       ),
		BasePortsOnDynamicComps          = maketest(dynamic  , base       ),
		InterceptedPortsOnBaseComps      = maketest(base     , intercepted),
		InterceptedPortsOnWrappedComps   = maketest(wrapped  , intercepted),
		InterceptedPortsOnContainedComps = maketest(contained, intercepted),
		InterceptedPortsOnDynamicComps   = maketest(dynamic  , intercepted),
	}
end
return FullSuite
