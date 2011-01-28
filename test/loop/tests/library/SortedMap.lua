local table     = require "loop.table"
local SortedMap = require "loop.collection.SortedMap"

local freenode = {
	false, false, false, false, false,
	false, false, false, false, false,
	false, false, false, false, false,
	false, false, false, false, false,
	false, false, false, false, false,
	false, false, false, false, false,
	false, false, false, false, false,
	false, false, false, false, false,
	false, false, false, false, false,
	false, false, false, false, false,
}
local nodepool = {}
for i = 1, 200 do
	local node = table.copy(freenode)
	node[1] = nodepool.freenodes
	nodepool.freenodes = node
end

map = SortedMap{ nodepool = nodepool }

assert(map:put(12, "12") == "12")
assert(map:put(6 , "6" ) == "6" )
assert(map:put(3 , "3" ) == "3" )
assert(map:put(26, "26") == "26")
assert(map:put(25, "25") == "25")
assert(map:put(19, "19") == "19")
assert(map:put(7 , "7" ) == "7" )
assert(map:put(21, "21") == "21")
assert(map:put(17, "17") == "17")
assert(map:put(9 , "9" ) == "9" )

assert(map:get(12) == "12")
assert(map:get(6 ) == "6")
assert(map:get(3 ) == "3")
assert(map:get(26) == "26")
assert(map:get(25) == "25")
assert(map:get(19) == "19")
assert(map:get(7 ) == "7")
assert(map:get(21) == "21")
assert(map:get(17) == "17")
assert(map:get(9 ) == "9")

print "items added and consulted"; map:debug()

map:cropuntil(0, true)

print "cropped upto 0 and iterated"; map:debug()

map:cropuntil(14, true)

print(map)
for key, value in map:pairs() do
	print(key, value)
end

print "cropped upto 14 and iterated"; map:debug()

map:remove(12, true)
map:remove(6)
map:remove(3)

print "removed >12, 6, 3"; map:debug()

map:cropuntil(100000, true)

print "cropped upto 100000"; map:debug()

for _=1, 100 do
	map:put(math.random() * 100, "random", true)
end

print "1000 items added"; map:debug()

map:cropuntil(90, true)

print "cropped upto 90"; map:debug()

print "freenodes:"
local node = map.nodepool.freenodes
while node do
	print(string.format("[%s] = %s (->%d)", node.key or 'nil', node.value or 'nil', #node))
	node = node[1]
end