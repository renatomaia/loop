local Wrapper = require "loop.object.Wrapper"

return function()
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
	
	assert(wrapper.data.n == 5)
	assert(wrapper.data[1] == object)
	assert(wrapper.data[2] == 1)
	assert(wrapper.data[3] == "first")
	assert(wrapper.data[4] == object)
	assert(wrapper.data[5] == wrapper)
	
	assert(wrapper:get1() == 1)
	assert(wrapper:get2() == 2)
	assert(wrapper:get3() == -3)
	assert(wrapper:get4() == -4)
	
	assert(wrapper:get1(wrapper:get2()) == 1)
	assert(wrapper:get2(wrapper:get1()) == 2)
	
	local fake3, fake4 = wrapper.get3, wrapper.get4
	
	object.get1 = nil
	object.get2 = false
	object.get3 = nil
	object.get4 = nil
	
	assert(wrapper.get1 == nil)
	assert(wrapper.get2 == false)
	assert(wrapper.get3 == fake3)
	assert(wrapper.get4 == fake4)
end