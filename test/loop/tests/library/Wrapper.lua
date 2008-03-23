local Wrapper = require "loop.object.Wrapper"

local function newsub()
	local data = {}
	return function(...)
		local prev = data
		data = { n = select("#", ...), ... }
		return unpack(prev, 1, prev.n)
	end
end

return function(checks)
	local object = {}
	function object:echo(...)
		self.data = { n = select("#", ...)+1, self, ... }
	end
	function object:get1() return 1 end
	function object:get2() return 2 end
	function object:get3() return 3 end
	function object:get4() return 4 end
	
	local wrapper = Wrapper{ __object = object }
	function wrapper:get3() return -3 end
	function wrapper:get4() return -4 end
	
	wrapper:echo(1, "first", object, wrapper)
	
	checks:assert(wrapper.data.n, checks.is(5))
	checks:assert(wrapper.data[1], checks.is(object))
	checks:assert(wrapper.data[2], checks.is(1))
	checks:assert(wrapper.data[3], checks.is("first"))
	checks:assert(wrapper.data[4], checks.is(object))
	checks:assert(wrapper.data[5], checks.is(wrapper))
	
	checks:assert(wrapper:get1(), checks.is(1))
	checks:assert(wrapper:get2(), checks.is(2))
	checks:assert(wrapper:get3(), checks.is(-3))
	checks:assert(wrapper:get4(), checks.is(-4))
	
	checks:assert(wrapper:get1(wrapper:get2()), checks.is(1))
	checks:assert(wrapper:get2(wrapper:get1()), checks.is(2))
	
	local fake3, fake4 = wrapper.get3, wrapper.get4
	
	object.get1 = nil
	object.get2 = false
	object.get3 = nil
	object.get4 = nil
	
	checks:assert(wrapper.get1, checks.is(nil))
	checks:assert(wrapper.get2, checks.is(false))
	checks:assert(wrapper.get3, checks.is(fake3))
	checks:assert(wrapper.get4, checks.is(fake4))
end