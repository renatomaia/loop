if oo == nil then oo = require "loop.simple" end

require "loop.tests.models.base"

function assertDerivedMembers(object)
	assert(oo.isinstanceof(object, Derived) == true)
	assertClassMembers(object)
	assert(object.inheritedAttrib == "overridenAttrib")
	assert(object:inheritedMethod() == "overridenMethod")
	assert(object.inheritedMethod == methods.overridenMethod)
	assert(object.derivedAttrib == "derivedAttrib")
	assert(object:derivedMethod() == "derivedMethod")
	assert(object.derivedMethod == methods.derivedMethod)
	assert(rawget(object, "derivedAttrib") == nil)
	assert(rawget(object, "derivedMethod") == nil)
end

Class.inheritedAttrib = "inheritedAttrib"
Class.inheritedMethod = methods.inheritedMethod

Derived = oo.class({
	inheritedAttrib = "overridenAttrib",
	inheritedMethod = methods.overridenMethod,
	derivedAttrib = "derivedAttrib",
	derivedMethod = methods.derivedMethod,
}, Class)

do -- oo.getmember
	assert(Derived.classAttrib == "classAttrib")
	assert(Derived.classMethod == methods.classMethod)
	assert(Derived.inheritedAttrib == "overridenAttrib")
	assert(Derived.inheritedMethod == methods.overridenMethod)
	assert(Derived.derivedAttrib == "derivedAttrib")
	assert(Derived.derivedMethod == methods.derivedMethod)
	assert(oo.getmember(Derived, "classAttrib") == nil)
	assert(oo.getmember(Derived, "classMethod") == nil)
	assert(oo.getmember(Derived, "inheritedAttrib") == "overridenAttrib")
	assert(oo.getmember(Derived, "inheritedMethod") == methods.overridenMethod)
	assert(oo.getmember(Derived, "derivedAttrib") == "derivedAttrib")
	assert(oo.getmember(Derived, "derivedMethod") == methods.derivedMethod)
end

do -- oo.members
	local expected = {
		inheritedAttrib = "overridenAttrib",
		inheritedMethod = methods.overridenMethod,
		derivedAttrib = "derivedAttrib",
		derivedMethod = methods.derivedMethod,
	}
	for name, value in oo.members(Derived) do
		if name ~= "__index" then
			local expectedvalue = expected[name]
			expected[name] = nil
			assert(expectedvalue ~= nil)
			assert(value == expectedvalue)
		end
	end
	assert(next(expected) == nil)
end

do -- class members
	local object = Derived()
	assertClassMembers(object)
	assertDerivedMembers(object)
	assertNoObjectMembers(object)
end

do -- object members
	local object = Derived{
		attrib = "attribute",
		method = methods.method
	}
	assertClassMembers(object)
	assertDerivedMembers(object)
	assertObjectMembers(object)
end

do -- overriden object members
	local object = Derived{
		derivedAttrib = "overridenAttrib",
		derivedMethod = methods.overridenMethod,
	}
	assertClassMembers(object)
	assert(object.derivedAttrib == "overridenAttrib")
	assert(object.derivedMethod == methods.overridenMethod)
	assert(object:derivedMethod() == "overridenMethod")
	assertNoObjectMembers(object)
end
