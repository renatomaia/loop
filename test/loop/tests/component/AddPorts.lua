local function constructor(name, index)
	return function()
		local result = { getname = function() return name end }
		if index ~= nil then
			 result = { [index] = result }
		end
		return result
	end
end

return function(cpack, ppack)
	return function(checks)
		local template = cpack.Template()
		local factory = template()
		local comp = factory() -- template, factory, component
		
		cpack.addport(comp, "facet", ppack.Facet         , constructor("facet"))
		cpack.addport(comp, "recep", ppack.Receptacle    , constructor("recep"))
		cpack.addport(comp, "list" , ppack.ListReceptacle, constructor("list", 1))
		cpack.addport(comp, "hash" , ppack.HashReceptacle, constructor("hash", "key"))
		cpack.addport(comp, "set"  , ppack.SetReceptacle)
	
		checks:assert(comp.facet, checks.isnot(nil))
		checks:assert(comp.recep, checks.isnot(nil))
		checks:assert(comp.list , checks.isnot(nil))
		checks:assert(comp.hash , checks.isnot(nil))
		checks:assert(comp.set  , checks.isnot(nil))
		
		checks:assert(comp.list[1] , checks.isnot(nil))
		checks:assert(comp.hash.key, checks.isnot(nil))
		
		checks:assert(comp.facet:getname()   , checks.equals("facet"))
		checks:assert(comp.recep:getname()   , checks.equals("recep"))
		checks:assert(comp.list[1]:getname() , checks.equals("list"))
		checks:assert(comp.hash.key:getname(), checks.equals("hash"))
		for port in comp.set:__all() do
			checks:fail("set receptacle is not empty")
		end
	end
end
