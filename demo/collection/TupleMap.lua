local inspector = require "inspector"
local TupleMap = require "loop.collection.TupleMap"
local WeakTupleMap = require "loop.collection.WeakTupleMap"
local vararg = require "vararg"
local pack = vararg.pack

local function newvalue(label)
	---[[
	local value = newproxy(true)
	getmetatable(value).__tostring = function() return label end
	return value
	--[=[]]
	return label
	--]=]
end

local function collectall()
	local after = collectgarbage("count")
	repeat
		local before = after
		collectgarbage()
		after = collectgarbage("count")
	until after >= before
end

do
	print("\n--- Strong Map -------------------------------------------------\n")
	local map = TupleMap()
	assert(map:nointernalstate())
	map:set("1,2,3", 1,2,3)
	map:set("A,B,C", "A","B","C")
	map:set("{},{},{}", {},{},{})
	map:set("true,{},false", true,{},false)
	collectall()
	assert(map:get(1,2,3) == "1,2,3")
	assert(map:get("A","B","C") == "A,B,C")
	for value, k1,k2,k3 in map:entries() do
		print(value, k1,k2,k3)
		map:set(nil, k1,k2,k3)
	end
	collectall()
	assert(map:nointernalstate())
end

do
	print("\n--- Weak Values Map --------------------------------------------\n")
	local map = TupleMap{ map = setmetatable({}, {__mode="v"}) }
	assert(map:nointernalstate())
	local A,B,C = newvalue("a"), newvalue("b"), newvalue("c")
	local strong = newvalue("strong")
	map:set("strong", 1,2,3)
	map:set("strong", A,B,C)
	map:set("strong", {},{},{})
	map:set("strong", true,{},false)
	map:set(strong, 3,2,1)
	map:set(strong, C,B,A)
	map:set(strong, false,{},true)
	map:set({}, "A","B","C")
	map:set({}, {},{},{})
	map:set({}, true,{},false)
	collectall()
	assert(map:get(1,2,3) == "strong")
	assert(map:get(A,B,C) == "strong")
	assert(map:get(3,2,1) == strong)
	assert(map:get(C,B,A) == strong)
	for value, k1,k2,k3 in map:entries() do
		print(value, k1,k2,k3)
		assert(tostring(value) == "strong")
		if type(k2) == "table" then
			map:set(nil, k1,k2,k3)
		end
	end
	map:set(nil, 1,2,3)
	map:set(nil, 3,2,1)
	map:set(nil, A,B,C)
	map:set(nil, C,B,A)
	collectall()
	assert(map:nointernalstate())
end

do
	print("\n--- Weak Keys Map ----------------------------------------------\n")
	local map = WeakTupleMap{ map = setmetatable({}, {__mode="k"}) }
	assert(map:nointernalstate())
	map:set("1,2,3", 1,2,3)
	map:set("{},{},{}", {},{},{})
	map:set("true,{},false", true,{},false)
	collectall()
	assert(map:get(1,2,3) == "1,2,3")
	for value, k1,k2,k3 in map:entries() do
		print(value, k1,k2,k3)
		assert(value == "1,2,3")
		assert(k1 == 1)
		assert(k2 == 2)
		assert(k3 == 3)
	end
	map:set(nil, 1,2,3)
	collectall()
	assert(map:nointernalstate())
end

do
	print("\n--- Weak Map ---------------------------------------------------\n")
	local map = WeakTupleMap{ map = setmetatable({}, {__mode="kv"}) }
	assert(map:nointernalstate())
	local A,B,C = newvalue("a"), newvalue("b"), newvalue("c")
	local strong = newvalue("strong")
	map:set("strong", 1,2,3)
	map:set("strong", A,B,C)
	map:set("strong", {},{},{})
	map:set("strong", true,{},false)
	map:set(strong, 3,2,1)
	map:set(strong, C,B,A)
	map:set(strong, false,{},true)
	map:set({}, "A","B","C")
	map:set({}, {},{},{})
	map:set({}, true,{},false)
	collectall()
	assert(map:get(1,2,3) == "strong")
	assert(map:get(A,B,C) == "strong")
	assert(map:get(3,2,1) == strong)
	assert(map:get(C,B,A) == strong)
	for value, k1,k2,k3 in map:entries() do
		print(value, k1,k2,k3)
		assert(tostring(value) == "strong")
		assert(type(k2) ~= "table")
	end
	map:set(nil, 1,2,3)
	map:set(nil, 3,2,1)
	map:set(nil, A,B,C)
	map:set(nil, C,B,A)
	collectall()
	assert(map:nointernalstate())
end

--do return end

do
	print("\n--- Tuples -----------------------------------------------------\n")
	local map = TupleMap{ map = setmetatable({}, {__mode="v"}) }

	function tuple(...)
		local tuple = map:get(...)
		if tuple == nil then
			tuple = pack(...)
			map:set(tuple, ...)
		end
		return tuple
	end

	assert(map:nointernalstate())
	do
		local A,B,C = newvalue("A"), newvalue("B"), newvalue("C")
		t1 = tuple(A,B,C)
		print(t1())   --> A	B	C
		print(t1(2))  --> B
		assert(t1("#") == 3)
		assert(select("#", t1()) == 3)
	end
	collectall()
	do
		local A,B,C = t1()
		t2 = tuple(A,B,C)
		assert(rawequal(t1, t2))
	end
	collectall()
	do
		local A,B = t1()
		t3 = tuple(A,B)
		assert(not rawequal(t1, t3))
	end
	collectall()
	do
		local A,B = t1()
		t4 = tuple(A,B,false)
		print(t4(2))  --> B
		assert(t4("#") == 3)
		assert(select("#", t4()) == 3)
		assert(not rawequal(t1, t4))
		assert(not rawequal(t3, t4))
	end
	collectall()
	do
		local A,B = t1()
		t5 = tuple(A,B,false)
		assert(rawequal(t4, t5))
	end
	t1str = tostring(t1)
	t3str = tostring(t3)
	t4str = tostring(t4)
	A,B,C = t1()
	t1,t2,t3,t4,t5 = nil,nil,nil,nil,nil
	collectall()
	assert(map:nointernalstate())
	do
		--local A,B,C = newvalue("A"), newvalue("B"), newvalue("C")
		local t1 = tuple(A,B,C)
		local t3 = tuple(A,B)
		local t4 = tuple(A,B,false)
		assert(t1str ~= tostring(t1)) -- most of the time!
		assert(t3str ~= tostring(t3)) -- most of the time!
		assert(t4str ~= tostring(t4)) -- most of the time!
		--A,B,C = nil,nil,nil
	end
end

