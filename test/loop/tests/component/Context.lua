local ContextFuncCompleted

local oo = require "loop.base"
local Component = oo.class()
function Component:context(context)
	assert(context.__component == self, "invalid component implementation")
	assert(context.__factory == self.factory, "invalid factory")
	for _, context in ipairs{ context, context.__reference } do
		assert(context.facet.name == "facet")
		assert(context.recep.name == "recep")
		assert(context.list[1].name == "list")
		assert(context.hash.key.name == "hash")
		for _ in context.set:__all() do
			error("set receptacle is not empty")
		end
	end
	ContextFuncCompleted = true
end
function Component:check()
	Component.context(self, self.context)
end

return function(cpack, ppack)
	local template = cpack.Template{
		facet = ppack.Facet,
		recep = ppack.Receptacle,
		list  = ppack.ListReceptacle,
		hash  = ppack.HashReceptacle,
		set   = ppack.SetReceptacle,
	}
	local factory = template{ Component,
		facet = function() return {name="facet"} end,
		recep = function() return {name="recep"} end,
		list  = function() return {{name="list"}} end,
		hash  = function() return {key={name="hash"}} end,
	}
	Component.factory = factory
	
	factory()                     -- context is set using method 'context'
	assert(ContextFuncCompleted == true)
	ContextFuncCompleted = nil
	
	factory{context=false}:check() -- context is placed in field 'context'
	assert(ContextFuncCompleted == true)
end
