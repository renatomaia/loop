local _G = require "_G"
local ipairs = _G.ipairs
local select = _G.select
local assert = _G.assert
local pcall = _G.pcall

local table = require "table"
local unpack = table.unpack or _G.unpack

local Publisher = require "loop.object.Publisher"

local function newsub()
	local data = {}
	return function(...)
		local prev = data
		data = { n = select("#", ...), ... }
		return unpack(prev, 1, prev.n)
	end
end

return function(checks)
	local sub1 = newsub()
	local sub2 = newsub()
	local sub3 = newsub()
	
	local pub = Publisher{
		sub1,
		sub2,
		sub3,
	}
	
	pub(1, "first", "event")
	
	for _, sub in ipairs{ sub1, sub2, sub3 } do
		local val1, val2, val3 = sub()
		assert(val1 == 1)
		assert(val2 == "first")
		assert(val3 == "event")
	end
	
	sub1 = { push = sub1 }
	sub2 = { push = sub2 }
	sub3 = { push = sub3 }
	
	pub[1] = sub1
	pub[2] = sub2
	pub[3] = sub3
	
	pub:push(2, "second", "event")
	
	for _, sub in ipairs{ sub1, sub2, sub3 } do
		local self, val1, val2, val3 = sub:push()
		assert(self == sub)
		assert(val1 == 2)
		assert(val2 == "second")
		assert(val3 == "event")
	end
	
	pub.third = 3
	
	assert(sub1.third == 3)
	assert(sub2.third == 3)
	assert(sub3.third == 3)
	
	assert(not pcall(function()
		pub:fake(pub:push(4, "forth", "event"))
	end), "fake method did not raise an error.")
	
	for _, sub in ipairs{ sub1, sub2, sub3 } do
		local self, val1, val2, val3 = sub:push()
		assert(self == sub)
		assert(val1 == 4)
		assert(val2 == "forth")
		assert(val3 == "event")
	end
end
