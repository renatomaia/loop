local _G = require "_G"
local Suite = require "loop.test.Suite"
local Fixture = require "loop.test.Fixture"

local function setup()
	self.Class = oo.class{ classAttrib = "classAttrib" }
	function self.Class:classMethod()
		return "classMethod"
	end
	self.default = self.Class()
	self.custom = self.Class{
		attrib = "attribute",
		method = "method",
	}
	self.override = self.Class{
		classAttrib = "overridenAttrib",
	}
	function self.override:classMethod()
		return "overridenMethod"
	end
end

local Tests = Suite()

Tests.SharedBehavior = Fixture{
	setup = setup,
	test = function(self, checks)
		checks:assert(self.default, checks.isnot(self.custom))
		checks:assert(self.default.classAttrib, checks.is("classAttrib"))
		checks:assert(self.default:classMethod(), checks.is("classMethod"))
		checks:assert(self.custom.classAttrib, checks.is("classAttrib"))
		checks:assert(self.custom:classMethod(), checks.is("classMethod"))
	end,
}

Tests.SpecificBehavior = Fixture{
	setup = setup,
	test = function(self, checks)
		checks:assert(self.default, checks.isnot(self.custom))
		checks:assert(self.default.attrib, checks.is(nil))
		checks:assert(self.default:method, checks.is(nil))
		checks:assert(self.custom.attrib, checks.is("attribute"))
		checks:assert(self.custom:method(), checks.is("method"))
	end,
}

return Tests
