if oo == nil then oo = require "loop.cached" end

require "loop.tests.models.multiple"

function Class:__len()
	return 1000
end
function Extra:__call()
	return "called"
end

do -- class members
	local object = Derived()
	assert(#object == 1000)
	assert(object() == "called")
end
