if oo == nil then oo = require "loop.multiple" end

require "loop.tests.models.simple"

function assertDerivedMembers(object)
	assertClassMembers(object)
	assert(oo.isinstanceof(object, Derived) == true)
	assert(object.derivedAttrib == "derivedAttrib")
	assert(object:derivedMethod() == "derivedMethod")
	assert(object.derivedMethod == methods.derivedMethod)
	assert(object.extraAttrib == "extraAttrib")
	assert(object:extraMethod() == "extraMethod")
	assert(object.extraMethod == methods.extraMethod)
	assert(rawget(object, "derivedAttrib") == nil)
	assert(rawget(object, "derivedMethod") == nil)
end

Extra = oo.class{
	classAttrib = "hiddenAttrib",
	classMethod = methods.hiddenMethod,
	extraAttrib = "extraAttrib",
	extraMethod = methods.extraMethod,
}

Derived = oo.class({
	derivedAttrib = "derivedAttrib",
	derivedMethod = methods.derivedMethod,
}, Class, Extra)

do -- oo.getmember
	assert(Derived.classAttrib == "classAttrib")
	assert(Derived.classMethod == methods.classMethod)
	assert(Derived.extraAttrib == "extraAttrib")
	assert(Derived.extraMethod == methods.extraMethod)
	assert(Derived.derivedAttrib == "derivedAttrib")
	assert(Derived.derivedMethod == methods.derivedMethod)
	assert(oo.getmember(Derived, "classAttrib") == nil)
	assert(oo.getmember(Derived, "classMethod") == nil)
	assert(oo.getmember(Derived, "extraAttrib") == nil)
	assert(oo.getmember(Derived, "extraMethod") == nil)
	assert(oo.getmember(Derived, "derivedAttrib") == "derivedAttrib")
	assert(oo.getmember(Derived, "derivedMethod") == methods.derivedMethod)
end

do -- oo.members
	local expected = {
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
