if oo == nil then oo = require "loop.base" end

function assertClassMembers(object)
	assert(oo.isinstanceof(object, Class) == true)
	assert(object.classAttrib == "classAttrib")
	assert(object:classMethod() == "classMethod")
	assert(object.classMethod == methods.classMethod)
	assert(rawget(object, "classAttrib") == nil)
	assert(rawget(object, "classMethod") == nil)
end
function assertNoObjectMembers(object)
	assert(object.attrib == nil)
	assert(object.method == nil)
end
function assertObjectMembers(object)
	assert(object.attrib == "attribute")
	assert(object:method() == "method")
	assert(object.method == methods.method)
	assert(rawget(object, "attrib") == "attribute")
	assert(rawget(object, "method") == methods.method)
end

local tabop = require "loop.table"
methods = tabop.memoize(function(name)
	return function(self)
		local class = assert(oo.getclass(self))
		assert(oo.isclass(class))
		return name
	end
end)

Class = oo.class{
	classAttrib = "classAttrib",
	classMethod = methods.classMethod,
}

do -- oo.getmember
	assert(Class.classAttrib == "classAttrib")
	assert(Class.classMethod == methods.classMethod)
	assert(oo.getmember(Class, "classAttrib") == "classAttrib")
	assert(oo.getmember(Class, "classMethod") == methods.classMethod)
end

do -- oo.members
	local expected = {
		classAttrib = "classAttrib",
		classMethod = methods.classMethod,
	}
	for name, value in oo.members(Class) do
		if name ~= "__index" then
			local expectedvalue = expected[name]
			expected[name] = nil
			assert(expectedvalue ~= nil)
			assert(value == expectedvalue)
		end
	end
	assert(next(expected) == nil)
end

do -- oo.isclass and oo.isinstanceof
	local Fake = setmetatable({
		classAttrib = "classAttrib",
		classMethod = methods.classMethod,
	}, { __call = oo.new })
	Fake.__index = Fake
	
	assert(oo.isclass() == false)
	assert(oo.isclass(Fake) == false)
	assert(oo.isclass(Class) == true)
	
	local object = Fake()
	assert(oo.isinstanceof(object, Class) == false)
end

do -- oo.getclass and oo.isinstanceof
	local values = {
		[false] = false,
		[true] = false,
		[0] = false,
		fake = getmetatable(""),
		[{}] = false,
		[function() end] = false,
		[coroutine.create(function() end)] = false,
		[io.stdout] = getmetatable(io.stdout),
	}
	for object, class in pairs(values) do
		if object == false then object = nil end
		if class == false then class = nil end
		assert(oo.getclass(object) == class)
		assert(oo.isinstanceof(object, Class) == false)
	end
end

do -- class members
	local object = Class()
	assertClassMembers(object)
	assertNoObjectMembers(object)
end

do -- object members
	local object = Class{ attrib = "attribute" }
	object.method = methods.method
	assertClassMembers(object)
	assertObjectMembers(object)
end

do -- overriden object members
	local object = Class{ classAttrib = "overridenAttrib" }
	object.classMethod = methods.overridenMethod
	assert(object.classAttrib == "overridenAttrib")
	assert(object.classMethod == methods.overridenMethod)
	assert(object:classMethod() == "overridenMethod")
	assertNoObjectMembers(object)
end

do -- __new metamethod
	function Class:__new()
		local object = oo.rawnew(self)
		object.initAttrib = "initAttrib"
		object.initMethod = methods.initMethod
		return object
	end
	
	local function assertInitialized(object)
		assert(object.initAttrib == "initAttrib")
		assert(object:initMethod() == "initMethod")
		assert(object.initMethod == methods.initMethod)
		assert(rawget(object, "initAttrib") == "initAttrib")
		assert(rawget(object, "initMethod") == methods.initMethod)
	end

	local function assertNoInitialized(object)
		assert(object.initAttrib == nil)
		assert(object.initMethod == nil)
		assert(rawget(object, "initAttrib") == nil)
		assert(rawget(object, "initMethod") == nil)
	end
	
	local object = Class()
	assertClassMembers(object)
	assertInitialized(object)
	
	local object = oo.new(Class)
	assertClassMembers(object)
	assertInitialized(object)
	
	local object = oo.rawnew(Class)
	assertClassMembers(object)
	assertNoInitialized(object)
	
	local object = oo.rawnew(Class, {
		attrib = "attribute",
		method = methods.method,
	})
	assertClassMembers(object)
	assertObjectMembers(object)
	assertNoInitialized(object)
	
	Class.__new = nil
end

do -- __new metamethod and oo.rawnew
	function Class:__new() return "fake instance" end
	
	assert(Class() == "fake instance")
	assert(oo.new(Class) == "fake instance")
	
	assertClassMembers(oo.rawnew(Class))
	
	local object = oo.rawnew(Class, {
		attrib = "attribute",
		method = methods.method,
	})
	assertClassMembers(object)
	assertObjectMembers(object)
	
	Class.__new = nil
end
