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
		checks:assert(val1, checks.is(1))
		checks:assert(val2, checks.is("first"))
		checks:assert(val3, checks.is("event"))
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
		checks:assert(self, checks.is(sub))
		checks:assert(val1, checks.is(2))
		checks:assert(val2, checks.is("second"))
		checks:assert(val3, checks.is("event"))
	end
	
	pub.third = 3
	
	checks:assert(sub1.third, checks.is(3))
	checks:assert(sub2.third, checks.is(3))
	checks:assert(sub3.third, checks.is(3))
	
	checks:assert(not pcall(function()
		pub:fake(pub:push(4, "forth", "event"))
	end), "fake method did not raise an error.")
	
	for _, sub in ipairs{ sub1, sub2, sub3 } do
		local self, val1, val2, val3 = sub:push()
		checks:assert(self, checks.is(sub))
		checks:assert(val1, checks.is(4))
		checks:assert(val2, checks.is("forth"))
		checks:assert(val3, checks.is("event"))
	end
end