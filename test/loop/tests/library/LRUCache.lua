local LRUCache = require "loop.collection.LRUCache"

local function usage(cache, ...)
	local i = 0
	for k in cache:usedkeys() do
		i = i + 1
		assert(k == select(i, ...))
	end
	assert(i == select("#", ...))
	assert(i == cache.size)
	for k in cache:usedkeys("least") do
		assert(k == select(i, ...))
		i = i - 1
	end
	assert(i == 0)
end

local function results(...)
	local count = select("#", ...)/2
	assert(count%1 == 0)
	for i=1, count do
		assert(select(i, ...) == select(count+i, ...))
	end
end

local function identity(...) return ... end
local function constant() return false end
local function nulify() end

return function()
	for _, retrieve in ipairs{ identity, constant, false } do
		do 
			local cache = LRUCache{ maxsize = 4, retrieve = retrieve or nil }
			retrieve = retrieve or nulify

			assert(cache:get("A") == retrieve("A"))
			assert(cache:get("B") == retrieve("B"))
			assert(cache:get("C") == retrieve("C"))
			usage(cache, "C","B","A")

			assert(cache:get("C") == retrieve("C"))
			usage(cache, "C","B","A")

			assert(cache:get("A") == retrieve("A"))
			usage(cache, "A","C","B")

			assert(cache:rawget("A") == retrieve("A"))
			assert(cache:rawget("B") == retrieve("B"))
			assert(cache:rawget("C") == retrieve("C"))
			assert(cache:rawget("D") == nil)
			assert(cache:rawget("E") == nil)
			assert(cache:rawget("F") == nil)
			usage(cache, "A","C","B")

			results("A",retrieve("A"),cache:put("A",1)) usage(cache, "A","C","B")
			results("B",retrieve("B"),cache:put("B",2)) usage(cache, "B","A","C")
			results("C",retrieve("C"),cache:put("C",3)) usage(cache, "C","B","A")
			results("D",nil          ,cache:put("D",4)) usage(cache, "D","C","B","A")
			results("A",1            ,cache:put("E",5)) usage(cache, "E","D","C","B")
			results("B",2            ,cache:put("F",6)) usage(cache, "F","E","D","C")

			assert(cache:get("C") == 3)
			usage(cache, "C","F","E","D")

			assert(cache:rawget("A") == nil)
			assert(cache:rawget("B") == nil)
			assert(cache:rawget("C") == 3)
			assert(cache:rawget("D") == 4)
			assert(cache:rawget("E") == 5)
			assert(cache:rawget("F") == 6)
			usage(cache, "C","F","E","D")

			assert(cache:get("A") == retrieve("A"))
			assert(cache:get("B") == retrieve("B"))
			assert(cache:get("C") == 3)
			assert(cache:get("F") == 6)
			usage(cache, "F","C","B","A")

			results("B", retrieve("B"), cache:remove("B")) usage(cache, "F","C","A")
			results("F", 6            , cache:remove("F")) usage(cache, "C","A")
			assert(select("#", cache:remove("Z")) == 0) usage(cache, "C","A")
		end
		do
			local cache = LRUCache{ maxsize = 1, retrieve = retrieve or nil }
			retrieve = retrieve or nulify

			assert(cache:get("A") == retrieve("A")) usage(cache, "A")
			assert(cache:get("B") == retrieve("B")) usage(cache, "B")
			assert(cache:get("C") == retrieve("C")) usage(cache, "C")
			assert(cache:get("C") == retrieve("C")) usage(cache, "C")
			assert(cache:get("A") == retrieve("A")) usage(cache, "A")

			assert(cache:rawget("A") == retrieve("A"))
			assert(cache:rawget("B") == nil)
			assert(cache:rawget("C") == nil)
			usage(cache, "A")

			results("A", retrieve("A"), cache:put("A", 1)) usage(cache, "A")
			results("A", 1            , cache:put("B", 2)) usage(cache, "B")
			results("B", 2            , cache:put("C", 3)) usage(cache, "C")
			results("C", 3            , cache:put("D", 4)) usage(cache, "D")
			results("D", 4            , cache:put("E", 5)) usage(cache, "E")
			results("E", 5            , cache:put("F", 6)) usage(cache, "F")

			assert(cache:get("F") == 6)
			usage(cache, "F")

			assert(cache:rawget("A") == nil)
			assert(cache:rawget("B") == nil)
			assert(cache:rawget("C") == nil)
			assert(cache:rawget("D") == nil)
			assert(cache:rawget("E") == nil)
			assert(cache:rawget("F") == 6)
			usage(cache, "F")

			assert(cache:get("A") == retrieve("A"))
			assert(cache:get("B") == retrieve("B"))
			usage(cache, "B")

			results("B", retrieve("B"), cache:remove("B")) usage(cache)
			assert(select("#", cache:remove("A")) == 0) usage(cache)
		end
		do
			local cache = LRUCache{ maxsize = 0, retrieve = retrieve or nil }
			retrieve = retrieve or nulify

			assert(cache:get("A") == retrieve("A")) usage(cache)
			assert(cache:get("B") == retrieve("B")) usage(cache)
			assert(cache:get("C") == retrieve("C")) usage(cache)
			assert(cache:get("C") == retrieve("C")) usage(cache)
			assert(cache:get("A") == retrieve("A")) usage(cache)

			assert(cache:rawget("A") == nil)
			assert(cache:rawget("B") == nil)
			assert(cache:rawget("C") == nil)
			usage(cache)

			assert(select("#", cache:put("A", 1)) == 0) usage(cache)
			assert(select("#", cache:put("B", 2)) == 0) usage(cache)
			assert(select("#", cache:put("C", 3)) == 0) usage(cache)
			assert(select("#", cache:put("D", 4)) == 0) usage(cache)
			assert(select("#", cache:put("E", 5)) == 0) usage(cache)
			assert(select("#", cache:put("F", 6)) == 0) usage(cache)

			assert(cache:get("F") == retrieve("F"))
			usage(cache)

			assert(cache:rawget("A") == nil)
			assert(cache:rawget("B") == nil)
			assert(cache:rawget("C") == nil)
			assert(cache:rawget("D") == nil)
			assert(cache:rawget("E") == nil)
			assert(cache:rawget("F") == nil)
			usage(cache)

			assert(cache:get("A") == retrieve("A"))
			assert(cache:get("B") == retrieve("B"))
			usage(cache)

			assert(select("#", cache:remove("B")) == 0)
			usage(cache)
		end
	end
end
