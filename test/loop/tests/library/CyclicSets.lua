UnorderedArray = require "loop.collection.UnorderedArray"
BiCyclicSets   = require "loop.collection.BiCyclicSets"
Viewer         = require "loop.debug.Viewer"

--return function(checks)
	
	sets = BiCyclicSets()
	
	print(UnorderedArray(sets:disjoint()))
	print(sets)
	
	sets:add(nil, "single")
	
	print(UnorderedArray(sets:disjoint()))
	print(sets)
	
	sets:add(1,2)
	sets:add(1,3)
	sets:add(1,4)

	print(UnorderedArray(sets:disjoint()))
	print(sets)
	
	sets:add("A","B")
	sets:add("B","C")
	sets:add("C","D")
	sets:add("D","E")
	sets:add("E","F")
	
	print(UnorderedArray(sets:disjoint()))
	print(sets)
	
	sets:add("Renato","Figueiro")
	sets:add("Figueiro","Maia")
	
	sets:add("Kylme","Ikegami")
	sets:add("Ikegami","Sakiyama")
	
	print(UnorderedArray(sets:disjoint()))
	print(sets)
	
	sets:moveto("D", 1, 4)
	
	print(UnorderedArray(sets:disjoint()))
	print(sets)
	
	sets:moveto("Renato", "Ikegami")
	sets:moveto("Kylme", "Figueiro")
	
	print(UnorderedArray(sets:disjoint()))
	print(sets)
	
	sets:remove(1)
	sets:remove(2)
	sets:remove(3)
	sets:remove(4)
	
	print(UnorderedArray(sets:disjoint()))
	print(sets)
	
	sets:remove("A")
	sets:remove("B")
	sets:remove("C")
	sets:remove("D")
	sets:remove("E")
	sets:remove("F")
	
	print(UnorderedArray(sets:disjoint()))
	print(sets)
	
	sets:remove("Renato")
	sets:remove("Figueiro")
	sets:remove("Maia")
	
	print(UnorderedArray(sets:disjoint()))
	print(sets)
	
	sets:remove("Kylme")
	sets:remove("Ikegami")
	sets:remove("Sakiyama")
	
	print(UnorderedArray(sets:disjoint()))
	print(sets)
	
	sets:remove("single")
	
	print(UnorderedArray(sets:disjoint()))
	print(sets)
	
--end