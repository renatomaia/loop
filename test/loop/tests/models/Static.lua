local _G = require "_G"
local setmetatable = _G.setmetatable

local oo = require "loop.static"
local Suite = require "loop.test.Suite"

local Tests = Suite()

function Tests.NoInheritance(checks)
	local Base = oo.class(function(name)
		local prvAttrib = "private"
		pubAttrib = "public"

		local function prvMethod()
			return "I'm a private method in "..name
		end

		function pubMethod()
			prvMethod()
			return "I'm a public method in "..name
		end
	end)
	
	local obj = Base("John Doe")
	checks:assert(obj.prvAttrib, checks.is(nil))
	checks:assert(obj.prvMethod, checks.is(nil))
	checks:assert(obj.pubAttrib, checks.is("public"))
	checks:assert(obj.pubMethod(), checks.is("I'm a public method in John Doe"))
end

function Tests.SimpleInheritance(checks)
	local Base = oo.class(function(name)
		local prvAttrib = "private"
		pubAttrib = "public"

		local function prvMethod()
			return "I'm a private method in "..name
		end

		function pubMethod()
			return "I'm a public method in "..name,
			       prvMethod()
		end
	end)
	
	local Sub = oo.class(function(name, age) oo.inherit(Base, name)
		local prvAttrib = "redefined private"
		pubAttrib = "redefined public"

		local function prvMethod()
			return "I'm a redefined private method in "..name..":"..age
		end
		
		local super_pubMethod = pubMethod
		function pubMethod()
			local prv = prvMethod()
			local spub, sprv = super_pubMethod()
			return "I'm a redefined public method in "..name..":"..age,
			       spub,
			       prv,
			       sprv
		end
	end)
	
	local obj = Sub("Jane Doe", 23)
	checks:assert(obj.prvAttrib, checks.is(nil))
	checks:assert(obj.prvMethod, checks.is(nil))
	checks:assert(obj.pubAttrib, checks.is("redefined public"))
	local pub1, pub2, prv1, prv2 = obj.pubMethod()
	checks:assert(pub1, checks.is("I'm a redefined public method in Jane Doe:23"))
	checks:assert(pub2, checks.is("I'm a public method in Jane Doe"))
	checks:assert(prv1, checks.is("I'm a redefined private method in Jane Doe:23"))
	checks:assert(prv2, checks.is("I'm a private method in Jane Doe"))
end

function Tests.Mutant(checks)
	local Mutant = oo.class(function(self) oo.become(self)
		function whoAmI()
			return "I'm "..name.."!"
		end
	end)

	local xman = Mutant{ name = "Wolverine" }
	checks:assert(xman.whoAmI(), checks.is("I'm Wolverine!"))
end

function Tests.SeeAll(checks)
	local HelloWorld = oo.class(function()
		setmetatable(oo.self(), {__index=_G})
		
		function getPrintFunc()
			return print
		end
	end)
	
	local hello = HelloWorld()
	checks:assert(hello.getPrintFunc(), checks.is(_G.print))
	checks:assert(hello._G, checks.is(_G))
end

return Tests
