local oo = require "loop.base"

local Component = oo.class()

function Component:context(context)
	local checks = self.checks
	if not self.context then self.context = context end
	
	checks:assert(context.__component, checks.is(self, "invalid component implementation"))
	checks:assert(context.__factory,   checks.is(self.factory, "invalid factory"))
	for _, context in ipairs{ context, context.__reference } do
		checks:assert(context.facet.name,    checks.equals("facet"))
		checks:assert(context.recep.name,    checks.equals("recep"))
		checks:assert(context.list[1].name,  checks.equals("list"))
		checks:assert(context.hash.key.name, checks.equals("hash"))
		for _ in context.set:__all() do
			checks:fail("set receptacle is not empty")
		end
	end
end

function Component:check()
	Component.context(self, self.context)
end

return function(cpack, ppack)
	return function(checks)
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
		Component.checks = checks
		Component.factory = factory
		
		factory()                     -- context is set using method 'context'
		factory{context=true}:check() -- context is placed in field 'context'
	end
end
