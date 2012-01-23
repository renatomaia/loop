return function()
	for _, e in ipairs{io.stdout, false} do
		newTest{ "S schedules T to wait E", "N unschedules T",
			tasks = {
				S = function(_ENV) assert(schedule(T, "wait", E) == T) end,
				N = function(_ENV) assert(unschedule(T) == (OK and T or nil)) end,
				T = Yielder(1),
			},
			E = e,
			O = {},
		}
		-- S schedules T to wait an event and N notifies this event
		testCase{S="outer",N="outer",T="none"     ,OK=true   ,[[ ...   ]],[[   ... ]]}
		testCase{S="outer",N="outer",T="ready"    ,OK=true   ,[[ ...   ]],[[   ... ]]}
		testCase{S="outer",N="outer",T="wait E"   ,OK=true   ,[[ ...   ]],[[   ... ]]}
		testCase{S="outer",N="outer",T="wait O"   ,OK=true   ,[[ ...   ]],[[   ... ]]}
		testCase{S="outer",N="none" ,T="none"     ,OK=true   ,[[ ...   ]],[[ N ... ]]}
		testCase{S="outer",N="none" ,T="ready"    ,OK=true   ,[[ ...   ]],[[ N ... ]]}
		testCase{S="outer",N="none" ,T="wait E"   ,OK=true   ,[[ ...   ]],[[ N ... ]]}
		testCase{S="outer",N="none" ,T="wait O"   ,OK=true   ,[[ ...   ]],[[ N ... ]]}
		testCase{S="outer",N="ready",T="none"     ,OK=true   ,[[ ...   ]],[[ N ... ]]}
		testCase{S="outer",N="ready",T="ready"    ,OK=true   ,[[ ...   ]],[[ N ... ]]}
		testCase{S="outer",N="ready",T="wait E"   ,OK=true   ,[[ ...   ]],[[ N ... ]]}
		testCase{S="outer",N="ready",T="wait O"   ,OK=true   ,[[ ...   ]],[[ N ... ]]}
		testCase{S="none" ,N="outer",T="none"     ,OK=true   ,[[ S ... ]],[[   ... ]]}
		testCase{S="none" ,N="outer",T="ready"    ,OK=true   ,[[ S ... ]],[[   ... ]]}
		testCase{S="none" ,N="outer",T="wait E"   ,OK=true   ,[[ S ... ]],[[   ... ]]}
		testCase{S="none" ,N="outer",T="wait O"   ,OK=true   ,[[ S ... ]],[[   ... ]]}
		testCase{S="none" ,N="none" ,T="none"     ,OK=true   ,[[ S ... ]],[[ N ... ]]}
		testCase{S="none" ,N="none" ,T="ready"    ,OK=true   ,[[ S ... ]],[[ N ... ]]}
		testCase{S="none" ,N="none" ,T="wait E"   ,OK=true   ,[[ S ... ]],[[ N ... ]]}
		testCase{S="none" ,N="none" ,T="wait O"   ,OK=true   ,[[ S ... ]],[[ N ... ]]}
		testCase{S="none" ,N="ready",T="none"     ,OK=true   ,[[ S ... ]],[[ N ... ]]}
		testCase{S="none" ,N="ready",T="ready"    ,OK=true   ,[[ S ... ]],[[ N ... ]]}
		testCase{S="none" ,N="ready",T="wait E"   ,OK=true   ,[[ S ... ]],[[ N ... ]]}
		testCase{S="none" ,N="ready",T="wait O"   ,OK=true   ,[[ S ... ]],[[ N ... ]]}
		testCase{S="ready",N="outer",T="none"     ,OK=true   ,[[ S ... ]],[[   ... ]]}
		testCase{S="ready",N="outer",T="ready"    ,OK=true   ,[[ S ... ]],[[   ... ]]}
		testCase{S="ready",N="outer",T="wait E"   ,OK=true   ,[[ S ... ]],[[   ... ]]}
		testCase{S="ready",N="outer",T="wait O"   ,OK=true   ,[[ S ... ]],[[   ... ]]}
		testCase{S="ready",N="none" ,T="none"     ,OK=true   ,[[ S ... ]],[[ N ... ]]}
		testCase{S="ready",N="none" ,T="ready"    ,OK=true   ,[[ S ... ]],[[ N ... ]]}
		testCase{S="ready",N="none" ,T="wait E"   ,OK=true   ,[[ S ... ]],[[ N ... ]]}
		testCase{S="ready",N="none" ,T="wait O"   ,OK=true   ,[[ S ... ]],[[ N ... ]]}
		testCase{S="ready",N="ready",T="none"     ,OK=true   ,[[ S ... ]],[[ N ... ]]}
		testCase{S="ready",N="ready",T="ready"    ,OK=true   ,[[ S ... ]],[[ N ... ]]}
		testCase{S="ready",N="ready",T="wait E"   ,OK=true   ,[[ S ... ]],[[ N ... ]]}
		testCase{S="ready",N="ready",T="wait O"   ,OK=true   ,[[ S ... ]],[[ N ... ]]}
		-- S schedules itself to wait an event and N notifies this event
		testCase{S="none" ,N="outer",T="S"        ,OK=nil    ,[[ S ... ]],[[   ... ]]}
		testCase{S="none" ,N="none" ,T="S"        ,OK=nil    ,[[ S ... ]],[[ N ... ]]}
		testCase{S="none" ,N="ready",T="S"        ,OK=nil    ,[[ S ... ]],[[ N ... ]]}
		testCase{S="ready",N="outer",T="S"        ,OK=nil    ,[[ S ... ]],[[   ... ]]}
		testCase{S="ready",N="none" ,T="S"        ,OK=nil    ,[[ S ... ]],[[ N ... ]]}
		testCase{S="ready",N="ready",T="S"        ,OK=nil    ,[[ S ... ]],[[ N ... ]]}
		
		
		newTest{ "S yields to schedule T to wait E and later yields", "N notifies NE",
			tasks = {
				S = function(_ENV)
					assert(yield("schedule", T, "wait", E) == T)
					yield("yield")
				end,
				N = function(_ENV) assert(unschedule(T) == (OK and T or nil)) end,
				T = Yielder(1),
			},
			E = e,
			O = {},
		}
		-- S schedules T to wait an event and N notifies this event
		testCase{S="none" ,N="outer",T="none"     ,OK=true   ,[[ S S ...       ]],[[   ... ]]}
		testCase{S="none" ,N="outer",T="ready"    ,OK=true   ,[[ S S ...       ]],[[   ... ]]}
		testCase{S="none" ,N="outer",T="wait E"   ,OK=true   ,[[ S S ...       ]],[[   ... ]]}
		testCase{S="none" ,N="outer",T="wait O"   ,OK=true   ,[[ S S ...       ]],[[   ... ]]}
		testCase{S="none" ,N="none" ,T="none"     ,OK=true   ,[[ S S ...       ]],[[ N ... ]]}
		testCase{S="none" ,N="none" ,T="ready"    ,OK=true   ,[[ S S ...       ]],[[ N ... ]]}
		testCase{S="none" ,N="none" ,T="wait E"   ,OK=true   ,[[ S S ...       ]],[[ N ... ]]}
		testCase{S="none" ,N="none" ,T="wait O"   ,OK=true   ,[[ S S ...       ]],[[ N ... ]]}
		testCase{S="none" ,N="ready",T="none"     ,OK=true   ,[[ S S ...       ]],[[ N ... ]]}
		testCase{S="none" ,N="ready",T="ready"    ,OK=true   ,[[ S S ...       ]],[[ N ... ]]}
		testCase{S="none" ,N="ready",T="wait E"   ,OK=true   ,[[ S S ...       ]],[[ N ... ]]}
		testCase{S="none" ,N="ready",T="wait O"   ,OK=true   ,[[ S S ...       ]],[[ N ... ]]}
		testCase{S="ready",N="outer",T="none"     ,OK=true   ,[[ S S ... S ... ]],[[   ... ]]}
		testCase{S="ready",N="outer",T="ready"    ,OK=true   ,[[ S S ... S ... ]],[[   ... ]]}
		testCase{S="ready",N="outer",T="wait E"   ,OK=true   ,[[ S S ... S ... ]],[[   ... ]]}
		testCase{S="ready",N="outer",T="wait O"   ,OK=true   ,[[ S S ... S ... ]],[[   ... ]]}
		testCase{S="ready",N="none" ,T="none"     ,OK=true   ,[[ S S ... S ... ]],[[ N ... ]]}
		testCase{S="ready",N="none" ,T="ready"    ,OK=true   ,[[ S S ... S ... ]],[[ N ... ]]}
		testCase{S="ready",N="none" ,T="wait E"   ,OK=true   ,[[ S S ... S ... ]],[[ N ... ]]}
		testCase{S="ready",N="none" ,T="wait O"   ,OK=true   ,[[ S S ... S ... ]],[[ N ... ]]}
		testCase{S="ready",N="ready",T="none"     ,OK=true   ,[[ S S ... S ... ]],[[ N ... ]]}
		testCase{S="ready",N="ready",T="ready"    ,OK=true   ,[[ S S ... S ... ]],[[ N ... ]]}
		testCase{S="ready",N="ready",T="wait E"   ,OK=true   ,[[ S S ... S ... ]],[[ N ... ]]}
		testCase{S="ready",N="ready",T="wait O"   ,OK=true   ,[[ S S ... S ... ]],[[ N ... ]]}
		-- S schedules itself to wait an event and N notifies this event
		testCase{S="none" ,N="outer",T="S"        ,OK=true   ,[[ S S ... ]],[[   ... ]]}
		testCase{S="none" ,N="none" ,T="S"        ,OK=true   ,[[ S S ... ]],[[ N ... ]]}
		testCase{S="none" ,N="ready",T="S"        ,OK=true   ,[[ S S ... ]],[[ N ... ]]}
		testCase{S="ready",N="outer",T="S"        ,OK=true   ,[[ S S ... ]],[[   ... ]]}
		testCase{S="ready",N="none" ,T="S"        ,OK=true   ,[[ S S ... ]],[[ N ... ]]}
		testCase{S="ready",N="ready",T="S"        ,OK=true   ,[[ S S ... ]],[[ N ... ]]}
	end
end
