return function()
	for _, e in ipairs{io.stdout, false} do
		newTest{ "S schedules T to wait SE", "N notifies NE",
			tasks = {
				S = function(_ENV) assert(schedule(T, "wait", SE) == T) end,
				N = function(_ENV) assert(notify(NE) == OK) end,
				T = Yielder(1),
			},
			SE = e,
			NE = e,
			OE = {},
		}
		-- S schedules T to wait an event and N notifies this event
		testCase{S="outer",N="outer",T="none"      ,OK=true        ,[[ ...   ]],[[   ... T ... T ... ]]}
		testCase{S="outer",N="outer",T="ready"     ,OK=true        ,[[ ...   ]],[[   ... T ... T ... ]]}
		testCase{S="outer",N="outer",T="wait SE"   ,OK=true        ,[[ ...   ]],[[   ... T ... T ... ]]}
		testCase{S="outer",N="outer",T="wait OE"   ,OK=true        ,[[ ...   ]],[[   ... T ... T ... ]]}
		testCase{S="outer",N="none" ,T="none"      ,OK=true        ,[[ ...   ]],[[ N ... T ... T ... ]]}
		testCase{S="outer",N="none" ,T="ready"     ,OK=true        ,[[ ...   ]],[[ N ... T ... T ... ]]}
		testCase{S="outer",N="none" ,T="wait SE"   ,OK=true        ,[[ ...   ]],[[ N ... T ... T ... ]]}
		testCase{S="outer",N="none" ,T="wait OE"   ,OK=true        ,[[ ...   ]],[[ N ... T ... T ... ]]}
		testCase{S="outer",N="ready",T="none"      ,OK=true        ,[[ ...   ]],[[ N ... T ... T ... ]]}
		testCase{S="outer",N="ready",T="ready"     ,OK=true        ,[[ ...   ]],[[ N ... T ... T ... ]]}
		testCase{S="outer",N="ready",T="wait SE"   ,OK=true        ,[[ ...   ]],[[ N ... T ... T ... ]]}
		testCase{S="outer",N="ready",T="wait OE"   ,OK=true        ,[[ ...   ]],[[ N ... T ... T ... ]]}
		testCase{S="none" ,N="outer",T="none"      ,OK=true        ,[[ S ... ]],[[   ... T ... T ... ]]}
		testCase{S="none" ,N="outer",T="ready"     ,OK=true        ,[[ S ... ]],[[   ... T ... T ... ]]}
		testCase{S="none" ,N="outer",T="wait SE"   ,OK=true        ,[[ S ... ]],[[   ... T ... T ... ]]}
		testCase{S="none" ,N="outer",T="wait OE"   ,OK=true        ,[[ S ... ]],[[   ... T ... T ... ]]}
		testCase{S="none" ,N="none" ,T="none"      ,OK=true        ,[[ S ... ]],[[ N ... T ... T ... ]]}
		testCase{S="none" ,N="none" ,T="ready"     ,OK=true        ,[[ S ... ]],[[ N ... T ... T ... ]]}
		testCase{S="none" ,N="none" ,T="wait SE"   ,OK=true        ,[[ S ... ]],[[ N ... T ... T ... ]]}
		testCase{S="none" ,N="none" ,T="wait OE"   ,OK=true        ,[[ S ... ]],[[ N ... T ... T ... ]]}
		testCase{S="none" ,N="ready",T="none"      ,OK=true        ,[[ S ... ]],[[ N ... T ... T ... ]]}
		testCase{S="none" ,N="ready",T="ready"     ,OK=true        ,[[ S ... ]],[[ N ... T ... T ... ]]}
		testCase{S="none" ,N="ready",T="wait SE"   ,OK=true        ,[[ S ... ]],[[ N ... T ... T ... ]]}
		testCase{S="none" ,N="ready",T="wait OE"   ,OK=true        ,[[ S ... ]],[[ N ... T ... T ... ]]}
		testCase{S="ready",N="outer",T="none"      ,OK=true        ,[[ S ... ]],[[   ... T ... T ... ]]}
		testCase{S="ready",N="outer",T="ready"     ,OK=true        ,[[ S ... ]],[[   ... T ... T ... ]]}
		testCase{S="ready",N="outer",T="wait SE"   ,OK=true        ,[[ S ... ]],[[   ... T ... T ... ]]}
		testCase{S="ready",N="outer",T="wait OE"   ,OK=true        ,[[ S ... ]],[[   ... T ... T ... ]]}
		testCase{S="ready",N="none" ,T="none"      ,OK=true        ,[[ S ... ]],[[ N ... T ... T ... ]]}
		testCase{S="ready",N="none" ,T="ready"     ,OK=true        ,[[ S ... ]],[[ N ... T ... T ... ]]}
		testCase{S="ready",N="none" ,T="wait SE"   ,OK=true        ,[[ S ... ]],[[ N ... T ... T ... ]]}
		testCase{S="ready",N="none" ,T="wait OE"   ,OK=true        ,[[ S ... ]],[[ N ... T ... T ... ]]}
		testCase{S="ready",N="ready",T="none"      ,OK=true        ,[[ S ... ]],[[ N ... T ... T ... ]]}
		testCase{S="ready",N="ready",T="ready"     ,OK=true        ,[[ S ... ]],[[ N ... T ... T ... ]]}
		testCase{S="ready",N="ready",T="wait SE"   ,OK=true        ,[[ S ... ]],[[ N ... T ... T ... ]]}
		testCase{S="ready",N="ready",T="wait OE"   ,OK=true        ,[[ S ... ]],[[ N ... T ... T ... ]]}
		-- S schedules itself to wait an event and N notifies this event
		testCase{S="none" ,N="outer",T="S"         ,OK=nil         ,[[ S ... ]],[[   ... ]]}
		testCase{S="none" ,N="none" ,T="S"         ,OK=nil         ,[[ S ... ]],[[ N ... ]]}
		testCase{S="none" ,N="ready",T="S"         ,OK=nil         ,[[ S ... ]],[[ N ... ]]}
		testCase{S="ready",N="outer",T="S"         ,OK=nil         ,[[ S ... ]],[[   ... ]]}
		testCase{S="ready",N="none" ,T="S"         ,OK=nil         ,[[ S ... ]],[[ N ... ]]}
		testCase{S="ready",N="ready",T="S"         ,OK=nil         ,[[ S ... ]],[[ N ... ]]}
		-- S schedules T to wait an event and N notifies another event
		testCase{S="outer",N="outer",T="none"      ,OK=nil,SE={}   ,[[ ...   ]],[[   ... ]]}
		testCase{S="outer",N="outer",T="ready"     ,OK=nil,SE={}   ,[[ ...   ]],[[   ... ]]}
		testCase{S="outer",N="outer",T="wait SE"   ,OK=nil,SE={}   ,[[ ...   ]],[[   ... ]]}
		testCase{S="outer",N="outer",T="wait OE"   ,OK=nil,SE={}   ,[[ ...   ]],[[   ... ]]}
		testCase{S="outer",N="none" ,T="none"      ,OK=nil,SE={}   ,[[ ...   ]],[[ N ... ]]}
		testCase{S="outer",N="none" ,T="ready"     ,OK=nil,SE={}   ,[[ ...   ]],[[ N ... ]]}
		testCase{S="outer",N="none" ,T="wait SE"   ,OK=nil,SE={}   ,[[ ...   ]],[[ N ... ]]}
		testCase{S="outer",N="none" ,T="wait OE"   ,OK=nil,SE={}   ,[[ ...   ]],[[ N ... ]]}
		testCase{S="outer",N="ready",T="none"      ,OK=nil,SE={}   ,[[ ...   ]],[[ N ... ]]}
		testCase{S="outer",N="ready",T="ready"     ,OK=nil,SE={}   ,[[ ...   ]],[[ N ... ]]}
		testCase{S="outer",N="ready",T="wait SE"   ,OK=nil,SE={}   ,[[ ...   ]],[[ N ... ]]}
		testCase{S="outer",N="ready",T="wait OE"   ,OK=nil,SE={}   ,[[ ...   ]],[[ N ... ]]}
		testCase{S="none" ,N="outer",T="none"      ,OK=nil,SE={}   ,[[ S ... ]],[[   ... ]]}
		testCase{S="none" ,N="outer",T="ready"     ,OK=nil,SE={}   ,[[ S ... ]],[[   ... ]]}
		testCase{S="none" ,N="outer",T="wait SE"   ,OK=nil,SE={}   ,[[ S ... ]],[[   ... ]]}
		testCase{S="none" ,N="outer",T="wait OE"   ,OK=nil,SE={}   ,[[ S ... ]],[[   ... ]]}
		testCase{S="none" ,N="none" ,T="none"      ,OK=nil,SE={}   ,[[ S ... ]],[[ N ... ]]}
		testCase{S="none" ,N="none" ,T="ready"     ,OK=nil,SE={}   ,[[ S ... ]],[[ N ... ]]}
		testCase{S="none" ,N="none" ,T="wait SE"   ,OK=nil,SE={}   ,[[ S ... ]],[[ N ... ]]}
		testCase{S="none" ,N="none" ,T="wait OE"   ,OK=nil,SE={}   ,[[ S ... ]],[[ N ... ]]}
		testCase{S="none" ,N="ready",T="none"      ,OK=nil,SE={}   ,[[ S ... ]],[[ N ... ]]}
		testCase{S="none" ,N="ready",T="ready"     ,OK=nil,SE={}   ,[[ S ... ]],[[ N ... ]]}
		testCase{S="none" ,N="ready",T="wait SE"   ,OK=nil,SE={}   ,[[ S ... ]],[[ N ... ]]}
		testCase{S="none" ,N="ready",T="wait OE"   ,OK=nil,SE={}   ,[[ S ... ]],[[ N ... ]]}
		testCase{S="ready",N="outer",T="none"      ,OK=nil,SE={}   ,[[ S ... ]],[[   ... ]]}
		testCase{S="ready",N="outer",T="ready"     ,OK=nil,SE={}   ,[[ S ... ]],[[   ... ]]}
		testCase{S="ready",N="outer",T="wait SE"   ,OK=nil,SE={}   ,[[ S ... ]],[[   ... ]]}
		testCase{S="ready",N="outer",T="wait OE"   ,OK=nil,SE={}   ,[[ S ... ]],[[   ... ]]}
		testCase{S="ready",N="none" ,T="none"      ,OK=nil,SE={}   ,[[ S ... ]],[[ N ... ]]}
		testCase{S="ready",N="none" ,T="ready"     ,OK=nil,SE={}   ,[[ S ... ]],[[ N ... ]]}
		testCase{S="ready",N="none" ,T="wait SE"   ,OK=nil,SE={}   ,[[ S ... ]],[[ N ... ]]}
		testCase{S="ready",N="none" ,T="wait OE"   ,OK=nil,SE={}   ,[[ S ... ]],[[ N ... ]]}
		testCase{S="ready",N="ready",T="none"      ,OK=nil,SE={}   ,[[ S ... ]],[[ N ... ]]}
		testCase{S="ready",N="ready",T="ready"     ,OK=nil,SE={}   ,[[ S ... ]],[[ N ... ]]}
		testCase{S="ready",N="ready",T="wait SE"   ,OK=nil,SE={}   ,[[ S ... ]],[[ N ... ]]}
		testCase{S="ready",N="ready",T="wait OE"   ,OK=nil,SE={}   ,[[ S ... ]],[[ N ... ]]}
		
		
		newTest{ "S yields to schedule T to wait SE and later yields twice", "N notifies NE",
			tasks = {
				S = function(_ENV)
					assert(yield("schedule", T, "wait", SE) == T)
					yield("yield")
					yield("yield")
				end,
				N = function(_ENV) assert(notify(NE) == OK) end,
				T = Yielder(1),
			},
			SE = e,
			NE = e,
			OE = {},
		}
		-- S schedules T to wait an event and N notifies this event
		testCase{S="none" ,N="outer",T="none"      ,OK=true        ,[[ S S ...             ]],[[   ... T ... T ... ]]}
		testCase{S="none" ,N="outer",T="ready"     ,OK=true        ,[[ S S ...             ]],[[   ... T ... T ... ]]}
		testCase{S="none" ,N="outer",T="wait SE"   ,OK=true        ,[[ S S ...             ]],[[   ... T ... T ... ]]}
		testCase{S="none" ,N="outer",T="wait OE"   ,OK=true        ,[[ S S ...             ]],[[   ... T ... T ... ]]}
		testCase{S="none" ,N="none" ,T="none"      ,OK=true        ,[[ S S ...             ]],[[ N ... T ... T ... ]]}
		testCase{S="none" ,N="none" ,T="ready"     ,OK=true        ,[[ S S ...             ]],[[ N ... T ... T ... ]]}
		testCase{S="none" ,N="none" ,T="wait SE"   ,OK=true        ,[[ S S ...             ]],[[ N ... T ... T ... ]]}
		testCase{S="none" ,N="none" ,T="wait OE"   ,OK=true        ,[[ S S ...             ]],[[ N ... T ... T ... ]]}
		testCase{S="none" ,N="ready",T="none"      ,OK=true        ,[[ S S ...             ]],[[ N ... T ... T ... ]]}
		testCase{S="none" ,N="ready",T="ready"     ,OK=true        ,[[ S S ...             ]],[[ N ... T ... T ... ]]}
		testCase{S="none" ,N="ready",T="wait SE"   ,OK=true        ,[[ S S ...             ]],[[ N ... T ... T ... ]]}
		testCase{S="none" ,N="ready",T="wait OE"   ,OK=true        ,[[ S S ...             ]],[[ N ... T ... T ... ]]}
		testCase{S="ready",N="outer",T="none"      ,OK=true        ,[[ S S ... S ... S ... ]],[[   ... T ... T ... ]]}
		testCase{S="ready",N="outer",T="ready"     ,OK=true        ,[[ S S ... S ... S ... ]],[[   ... T ... T ... ]]}
		testCase{S="ready",N="outer",T="wait SE"   ,OK=true        ,[[ S S ... S ... S ... ]],[[   ... T ... T ... ]]}
		testCase{S="ready",N="outer",T="wait OE"   ,OK=true        ,[[ S S ... S ... S ... ]],[[   ... T ... T ... ]]}
		testCase{S="ready",N="none" ,T="none"      ,OK=true        ,[[ S S ... S ... S ... ]],[[ N ... T ... T ... ]]}
		testCase{S="ready",N="none" ,T="ready"     ,OK=true        ,[[ S S ... S ... S ... ]],[[ N ... T ... T ... ]]}
		testCase{S="ready",N="none" ,T="wait SE"   ,OK=true        ,[[ S S ... S ... S ... ]],[[ N ... T ... T ... ]]}
		testCase{S="ready",N="none" ,T="wait OE"   ,OK=true        ,[[ S S ... S ... S ... ]],[[ N ... T ... T ... ]]}
		testCase{S="ready",N="ready",T="none"      ,OK=true        ,[[ S S ... S ... S ... ]],[[ N ... T ... T ... ]]}
		testCase{S="ready",N="ready",T="ready"     ,OK=true        ,[[ S S ... S ... S ... ]],[[ N ... T ... T ... ]]}
		testCase{S="ready",N="ready",T="wait SE"   ,OK=true        ,[[ S S ... S ... S ... ]],[[ N ... T ... T ... ]]}
		testCase{S="ready",N="ready",T="wait OE"   ,OK=true        ,[[ S S ... S ... S ... ]],[[ N ... T ... T ... ]]}
		-- S schedules itself to wait an event and N notifies this event
		testCase{S="none" ,N="outer",T="S"         ,OK=true        ,[[ S S ... ]],[[   ... S ... S ... ]]}
		testCase{S="none" ,N="none" ,T="S"         ,OK=true        ,[[ S S ... ]],[[ N ... S ... S ... ]]}
		testCase{S="none" ,N="ready",T="S"         ,OK=true        ,[[ S S ... ]],[[ N ... S ... S ... ]]}
		testCase{S="ready",N="outer",T="S"         ,OK=true        ,[[ S S ... ]],[[   ... S ... S ... ]]}
		testCase{S="ready",N="none" ,T="S"         ,OK=true        ,[[ S S ... ]],[[ N ... S ... S ... ]]}
		testCase{S="ready",N="ready",T="S"         ,OK=true        ,[[ S S ... ]],[[ N ... S ... S ... ]]}
		-- S schedules T to wait an event and N notifies another event
		testCase{S="none" ,N="outer",T="none"      ,OK=nil,SE={}   ,[[ S S ...             ]],[[   ... ]]}
		testCase{S="none" ,N="outer",T="ready"     ,OK=nil,SE={}   ,[[ S S ...             ]],[[   ... ]]}
		testCase{S="none" ,N="outer",T="wait SE"   ,OK=nil,SE={}   ,[[ S S ...             ]],[[   ... ]]}
		testCase{S="none" ,N="outer",T="wait OE"   ,OK=nil,SE={}   ,[[ S S ...             ]],[[   ... ]]}
		testCase{S="none" ,N="none" ,T="none"      ,OK=nil,SE={}   ,[[ S S ...             ]],[[ N ... ]]}
		testCase{S="none" ,N="none" ,T="ready"     ,OK=nil,SE={}   ,[[ S S ...             ]],[[ N ... ]]}
		testCase{S="none" ,N="none" ,T="wait SE"   ,OK=nil,SE={}   ,[[ S S ...             ]],[[ N ... ]]}
		testCase{S="none" ,N="none" ,T="wait OE"   ,OK=nil,SE={}   ,[[ S S ...             ]],[[ N ... ]]}
		testCase{S="none" ,N="ready",T="none"      ,OK=nil,SE={}   ,[[ S S ...             ]],[[ N ... ]]}
		testCase{S="none" ,N="ready",T="ready"     ,OK=nil,SE={}   ,[[ S S ...             ]],[[ N ... ]]}
		testCase{S="none" ,N="ready",T="wait SE"   ,OK=nil,SE={}   ,[[ S S ...             ]],[[ N ... ]]}
		testCase{S="none" ,N="ready",T="wait OE"   ,OK=nil,SE={}   ,[[ S S ...             ]],[[ N ... ]]}
		testCase{S="ready",N="outer",T="none"      ,OK=nil,SE={}   ,[[ S S ... S ... S ... ]],[[   ... ]]}
		testCase{S="ready",N="outer",T="ready"     ,OK=nil,SE={}   ,[[ S S ... S ... S ... ]],[[   ... ]]}
		testCase{S="ready",N="outer",T="wait SE"   ,OK=nil,SE={}   ,[[ S S ... S ... S ... ]],[[   ... ]]}
		testCase{S="ready",N="outer",T="wait OE"   ,OK=nil,SE={}   ,[[ S S ... S ... S ... ]],[[   ... ]]}
		testCase{S="ready",N="none" ,T="none"      ,OK=nil,SE={}   ,[[ S S ... S ... S ... ]],[[ N ... ]]}
		testCase{S="ready",N="none" ,T="ready"     ,OK=nil,SE={}   ,[[ S S ... S ... S ... ]],[[ N ... ]]}
		testCase{S="ready",N="none" ,T="wait SE"   ,OK=nil,SE={}   ,[[ S S ... S ... S ... ]],[[ N ... ]]}
		testCase{S="ready",N="none" ,T="wait OE"   ,OK=nil,SE={}   ,[[ S S ... S ... S ... ]],[[ N ... ]]}
		testCase{S="ready",N="ready",T="none"      ,OK=nil,SE={}   ,[[ S S ... S ... S ... ]],[[ N ... ]]}
		testCase{S="ready",N="ready",T="ready"     ,OK=nil,SE={}   ,[[ S S ... S ... S ... ]],[[ N ... ]]}
		testCase{S="ready",N="ready",T="wait SE"   ,OK=nil,SE={}   ,[[ S S ... S ... S ... ]],[[ N ... ]]}
		testCase{S="ready",N="ready",T="wait OE"   ,OK=nil,SE={}   ,[[ S S ... S ... S ... ]],[[ N ... ]]}
		-- S schedules itself to wait an event and N notifies this event
		testCase{S="none" ,N="outer",T="S"         ,OK=nil,SE={}   ,[[ S S ... ]],[[   ... ]]}
		testCase{S="none" ,N="none" ,T="S"         ,OK=nil,SE={}   ,[[ S S ... ]],[[ N ... ]]}
		testCase{S="none" ,N="ready",T="S"         ,OK=nil,SE={}   ,[[ S S ... ]],[[ N ... ]]}
		testCase{S="ready",N="outer",T="S"         ,OK=nil,SE={}   ,[[ S S ... ]],[[   ... ]]}
		testCase{S="ready",N="none" ,T="S"         ,OK=nil,SE={}   ,[[ S S ... ]],[[ N ... ]]}
		testCase{S="ready",N="ready",T="S"         ,OK=nil,SE={}   ,[[ S S ... ]],[[ N ... ]]}
		
		
		newTest{ "S yields to wait SE and later yields", "N notifies NE",
			tasks = {
				S = function(_ENV)
					yield("wait", SE)
					yield("yield")
				end,
				N = function(_ENV) assert(notify(NE) == OK) end,
			},
			SE = e,
			NE = e,
			OE = {},
		}
		-- S schedules itself to wait an event and N notifies this event
		testCase{S="none" ,N="outer"   ,OK=true        ,[[ S ... ]],[[   ... S ... S ... ]]}
		testCase{S="none" ,N="none"    ,OK=true        ,[[ S ... ]],[[ N ... S ... S ... ]]}
		testCase{S="none" ,N="ready"   ,OK=true        ,[[ S ... ]],[[ N ... S ... S ... ]]}
		testCase{S="ready",N="outer"   ,OK=true        ,[[ S ... ]],[[   ... S ... S ... ]]}
		testCase{S="ready",N="none"    ,OK=true        ,[[ S ... ]],[[ N ... S ... S ... ]]}
		testCase{S="ready",N="ready"   ,OK=true        ,[[ S ... ]],[[ N ... S ... S ... ]]}
		-- S schedules itself to wait an event and N notifies this event
		testCase{S="none" ,N="outer"   ,OK=nil,SE={}   ,[[ S ... ]],[[   ... ]]}
		testCase{S="none" ,N="none"    ,OK=nil,SE={}   ,[[ S ... ]],[[ N ... ]]}
		testCase{S="none" ,N="ready"   ,OK=nil,SE={}   ,[[ S ... ]],[[ N ... ]]}
		testCase{S="ready",N="outer"   ,OK=nil,SE={}   ,[[ S ... ]],[[   ... ]]}
		testCase{S="ready",N="none"    ,OK=nil,SE={}   ,[[ S ... ]],[[ N ... ]]}
		testCase{S="ready",N="ready"   ,OK=nil,SE={}   ,[[ S ... ]],[[ N ... ]]}
	end
end
