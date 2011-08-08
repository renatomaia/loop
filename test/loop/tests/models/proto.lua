local tabop = require "loop.table"
local oo = require "loop.proto"

local Proto = { protoAttrib = "protoAttrib" }

local function assertClone(value)
	assert(oo.getproto(value) == Proto)
	assert(oo.iscloneof(value, Proto) == true)
end
local methods = tabop.memoize(function(name)
	return function(self)
		assertClone(self)
		return name
	end
end)
local function assertProtoMembers(object)
	assertClone(object)
	assert(object.protoAttrib == "protoAttrib")
	assert(object:protoMethod() == "protoMethod")
	assert(object.protoMethod == methods.protoMethod)
	assert(rawget(object, "protoAttrib") == nil)
	assert(rawget(object, "protoMethod") == nil)
end
local function assertNoCloneMembers(object)
	assertClone(object)
	assert(object.attrib == nil)
	assert(object.method == nil)
end
local function assertCloneMembers(object)
	assertClone(object)
	assert(object.attrib == "attribute")
	assert(object:method() == "method")
	assert(object.method == methods.method)
	assert(rawget(object, "attrib") == "attribute")
	assert(rawget(object, "method") == methods.method)
end

Proto.protoMethod = methods.protoMethod

do -- oo.getclass and oo.isinstanceof
	local values = {
		false, -- simulate 'nil'
		true,
		0,
		"fake",
		{},
		function() end,
		coroutine.create(function() end),
		io.stdout,
	}
	for _, object in ipairs(values) do
		if object == false then object = nil end
		assert(oo.getproto(object) == nil)
		assert(oo.iscloneof(object, Proto) == false)
	end
end

do -- proto members
	local object = oo.clone(Proto)
	assertProtoMembers(object)
	assertNoCloneMembers(object)
end

do -- object members
	local object = oo.clone(Proto, {
		attrib = "attribute",
		method = methods.method,
	})
	assertProtoMembers(object)
	assertCloneMembers(object)
end

do -- overriden object members
	local object = oo.clone(Proto, {
		protoAttrib = "overridenAttrib",
		protoMethod = methods.overridenMethod
	})
	assert(object.protoAttrib == "overridenAttrib")
	assert(object.protoMethod == methods.overridenMethod)
	assert(object:protoMethod() == "overridenMethod")
	assertNoCloneMembers(object)
end
