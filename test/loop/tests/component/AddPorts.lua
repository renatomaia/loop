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
	local template = cpack.Template()
	local factory = template()
	local comp = factory() -- template, factory, component
	
	cpack.addport(comp, "facet", ppack.Facet         , constructor("facet"))
	cpack.addport(comp, "recep", ppack.Receptacle    , constructor("recep"))
	cpack.addport(comp, "list" , ppack.ListReceptacle, constructor("list", 1))
	cpack.addport(comp, "hash" , ppack.HashReceptacle, constructor("hash", "key"))
	cpack.addport(comp, "set"  , ppack.SetReceptacle)

	assert(comp.facet ~= nil)
	assert(comp.recep ~= nil)
	assert(comp.list ~= nil)
	assert(comp.hash ~= nil)
	assert(comp.set ~= nil)
	
	assert(comp.list[1] ~= nil)
	assert(comp.hash.key ~= nil)
	
	assert(comp.facet:getname() == "facet")
	assert(comp.recep:getname() == "recep")
	assert(comp.list[1]:getname() == "list")
	assert(comp.hash.key:getname() == "hash")
	for port in comp.set:__all() do
		error("set receptacle is not empty")
	end
end
