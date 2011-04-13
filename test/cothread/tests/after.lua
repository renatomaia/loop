return function()
	newTest{ "A schedules B after C",
		tasks = {
			A = function(_ENV) assert(schedule(B, "after", C) == (OK and B or nil)) end,
			B = Yielder(2),
			C = Yielder(2),
		},
	}
	-- A schedules B after C
	testCase{A="outer",B="none" ,C="none"    ,OK=false   ,[[ ...                           ]]}
	testCase{A="outer",B="none" ,C="ready"   ,OK=true    ,[[ ... C B ... C B ... C B ...   ]]}
	testCase{A="outer",B="ready",C="none"    ,OK=false   ,[[ ... B ... B ... B ...         ]]}
	testCase{A="outer",B="ready",C="ready"   ,OK=true    ,[[ ... C B ... C B ... C B ...   ]]}
	testCase{A="none" ,B="none" ,C="none"    ,OK=false   ,[[ A ...                         ]]}
	testCase{A="none" ,B="none" ,C="ready"   ,OK=true    ,[[ A ... C B ... C B ... C B ... ]]}
	testCase{A="none" ,B="ready",C="none"    ,OK=false   ,[[ A ... B ... B ... B ...       ]]}
	testCase{A="none" ,B="ready",C="ready"   ,OK=true    ,[[ A ... C B ... C B ... C B ... ]]}
	testCase{A="ready",B="none" ,C="none"    ,OK=false   ,[[ A ...                         ]]}
	testCase{A="ready",B="none" ,C="ready"   ,OK=true    ,[[ A ... C B ... C B ... C B ... ]]}
	testCase{A="ready",B="ready",C="none"    ,OK=false   ,[[ A ... B ... B ... B ...       ]]}
	testCase{A="ready",B="ready",C="ready"   ,OK=true    ,[[ A ... C B ... C B ... C B ... ]]}
	-- A schedules B after B
	testCase{A="outer",B="none" ,C="B"       ,OK=false   ,[[ ...                     ]]}
	testCase{A="outer",B="ready",C="B"       ,OK=true    ,[[ ... B ... B ... B ...   ]]}
	testCase{A="none" ,B="none" ,C="B"       ,OK=false   ,[[ A ...                   ]]}
	testCase{A="none" ,B="ready",C="B"       ,OK=true    ,[[ A ... B ... B ... B ... ]]}
	testCase{A="ready",B="none" ,C="B"       ,OK=false   ,[[ A ...                   ]]}
	testCase{A="ready",B="ready",C="B"       ,OK=true    ,[[ A ... B ... B ... B ... ]]}
	-- A schedules itself after C
	testCase{A="none" ,B="A"    ,C="none"    ,OK=false   ,[[ A ...                   ]]}
	testCase{A="none" ,B="A"    ,C="ready"   ,OK=true    ,[[ A ... C ... C ... C ... ]]}
	testCase{A="ready",B="A"    ,C="none"    ,OK=false   ,[[ A ...                   ]]}
	testCase{A="ready",B="A"    ,C="ready"   ,OK=true    ,[[ A ... C ... C ... C ... ]]}
	-- A schedules B after itself
	testCase{A="none" ,B="none" ,C="A"       ,OK=false   ,[[ A ...                   ]]}
	testCase{A="none" ,B="ready",C="A"       ,OK=false   ,[[ A ... B ... B ... B ... ]]}
	testCase{A="ready",B="none" ,C="A"       ,OK=true    ,[[ A ... B ... B ... B ... ]]}
	testCase{A="ready",B="ready",C="A"       ,OK=true    ,[[ A ... B ... B ... B ... ]]}
	-- A schedules itself after itself
	testCase{A="none" ,B="A"    ,C="A"       ,OK=false   ,[[ A ... ]]}
	testCase{A="ready",B="A"    ,C="A"       ,OK=true    ,[[ A ... ]]}
	
	
	newTest{ "A schedules B after C and yields twice",
		tasks = {
			A = function(_ENV)
				assert(yield("schedule", B, "after", C) == (OK and B or nil))
				yield("yield")
				yield("yield")
			end,
			B = Yielder(2),
			C = Yielder(2),
		},
	}
	-- A schedules B after C
	testCase{A="none" ,B="none" ,C="none"    ,OK=false   ,[[ A A ...                             ]]}
	testCase{A="none" ,B="none" ,C="ready"   ,OK=true    ,[[ A A ... C B ... C B ... C B ...     ]]}
	testCase{A="none" ,B="ready",C="none"    ,OK=false   ,[[ A A ... B ... B ... B ...           ]]}
	testCase{A="none" ,B="ready",C="ready"   ,OK=true    ,[[ A A ... C B ... C B ... C B ...     ]]}
	testCase{A="ready",B="none" ,C="none"    ,OK=false   ,[[ A A ... A ... A ...                 ]]}
	testCase{A="ready",B="none" ,C="ready"   ,OK=true    ,[[ A A ... C B A ... C B A ... C B ... ]]}
	testCase{A="ready",B="ready",C="none"    ,OK=false   ,[[ A A ... B A ... B A ... B ...       ]]}
	testCase{A="ready",B="ready",C="ready"   ,OK=true    ,[[ A A ... C B A ... C B A ... C B ... ]]}
	-- A schedules B after B
	testCase{A="none" ,B="none" ,C="B"       ,OK=false   ,[[ A A ...                       ]]}
	testCase{A="none" ,B="ready",C="B"       ,OK=true    ,[[ A A ... B ... B ... B ...     ]]}
	testCase{A="ready",B="none" ,C="B"       ,OK=false   ,[[ A A ... A ... A ...           ]]}
	testCase{A="ready",B="ready",C="B"       ,OK=true    ,[[ A A ... B A ... B A ... B ... ]]}
	-- A schedules itself after C
	testCase{A="none" ,B="A"    ,C="none"    ,OK=false   ,[[ A A ...                       ]]}
	testCase{A="none" ,B="A"    ,C="ready"   ,OK=true    ,[[ A A ... C A ... C A ... C ... ]]}
	testCase{A="ready",B="A"    ,C="none"    ,OK=false   ,[[ A A ... A ... A ...           ]]}
	testCase{A="ready",B="A"    ,C="ready"   ,OK=true    ,[[ A A ... C A ... C A ... C ... ]]}
	-- A schedules B after itself
	testCase{A="none" ,B="none" ,C="A"       ,OK=false   ,[[ A A ...                       ]]}
	testCase{A="none" ,B="ready",C="A"       ,OK=false   ,[[ A A ... B ... B ... B ...     ]]}
	testCase{A="ready",B="none" ,C="A"       ,OK=true    ,[[ A A ... A B ... A B ... B ... ]]}
	testCase{A="ready",B="ready",C="A"       ,OK=true    ,[[ A A ... A B ... A B ... B ... ]]}
	-- A schedules itself after itself
	testCase{A="none" ,B="A"    ,C="A"       ,OK=false   ,[[ A A ...             ]]}
	testCase{A="ready",B="A"    ,C="A"       ,OK=true    ,[[ A A ... A ... A ... ]]}
	
	
	newTest{ "A yields to reschedule itself after B and resume C",
		tasks = {
			A = function(_ENV) yield("after", B, C) end,
			B = Yielder(2),
			C = Yielder(2),
		},
	}
	-- A schedules itself after B
	testCase{A="none" ,B="none" ,C=nil       ,[[ A ...                     ]]}
	testCase{A="none" ,B="ready",C=nil       ,[[ A ... B A ... B ... B ... ]]}
	testCase{A="ready",B="none" ,C=nil       ,[[ A ... A ...               ]]}
	testCase{A="ready",B="ready",C=nil       ,[[ A ... B A ... B ... B ... ]]}
	-- A schedules itself after itself
	testCase{A="none" ,B="A"    ,C=nil       ,[[ A ...       ]]}
	testCase{A="ready",B="A"    ,C=nil       ,[[ A ... A ... ]]}
	-- A schedules itself after B and resume C
	testCase{A="none" ,B="none" ,C="none"    ,[[ A C ...                         ]]}
	testCase{A="none" ,B="none" ,C="ready"   ,[[ A C ... C ... C ...             ]]}
	testCase{A="none" ,B="ready",C="none"    ,[[ A C ... B A ... B ... B ...     ]]}
	testCase{A="none" ,B="ready",C="ready"   ,[[ A C ... B A C ... B C ... B ... ]]}
	testCase{A="ready",B="none" ,C="none"    ,[[ A C ... A ...                   ]]}
	testCase{A="ready",B="none" ,C="ready"   ,[[ A C ... C A ... C ...           ]]}
	testCase{A="ready",B="ready",C="none"    ,[[ A C ... B A ... B ... B ...     ]]}
	testCase{A="ready",B="ready",C="ready"   ,[[ A C ... B A C ... B C ... B ... ]]}
	-- A schedules itself after itself and resume C
	testCase{A="none" ,B="A"    ,C="none"    ,[[ A C ...               ]]}
	testCase{A="none" ,B="A"    ,C="ready"   ,[[ A C ... C ... C ...   ]]}
	testCase{A="ready",B="A"    ,C="none"    ,[[ A C ... A ...         ]]}
	testCase{A="ready",B="A"    ,C="ready"   ,[[ A C ... C A ... C ... ]]}
	-- A schedules itself after itself and resume itself
	testCase{A="none" ,B="A"    ,C="A"       ,[[ A A ... ]]}
	testCase{A="ready",B="A"    ,C="A"       ,[[ A A ... ]]}
	
	
	newTest{ "A yields to reschedule itself after B and resumes C and then yields once",
		tasks = {
			A = function(_ENV)
				yield("after", B, C)
				yield("yield")
			end,
			B = Yielder(2),
			C = Yielder(2),
		},
	}
	-- A schedules itself after C
	testCase{A="none" ,B="none" ,C=nil       ,[[ A ...                       ]]}
	testCase{A="none" ,B="ready",C=nil       ,[[ A ... B A ... B A ... B ... ]]}
	testCase{A="ready",B="none" ,C=nil       ,[[ A ... A ... A ...           ]]}
	testCase{A="ready",B="ready",C=nil       ,[[ A ... B A ... B A ... B ... ]]}
	-- A schedules itself after itself
	testCase{A="none" ,B="A"    ,C=nil       ,[[ A ...             ]]}
	testCase{A="ready",B="A"    ,C=nil       ,[[ A ... A ... A ... ]]}
	-- A schedules itself after B and resume C
	testCase{A="none" ,B="none" ,C="none"    ,[[ A C ...                           ]]}
	testCase{A="none" ,B="none" ,C="ready"   ,[[ A C ... C ... C ...               ]]}
	testCase{A="none" ,B="ready",C="none"    ,[[ A C ... B A ... B A ... B ...     ]]}
	testCase{A="none" ,B="ready",C="ready"   ,[[ A C ... B A C ... B A C ... B ... ]]}
	testCase{A="ready",B="none" ,C="none"    ,[[ A C ... A ... A ...               ]]}
	testCase{A="ready",B="none" ,C="ready"   ,[[ A C ... C A ... C A ...           ]]}
	testCase{A="ready",B="ready",C="none"    ,[[ A C ... B A ... B A ... B ...     ]]}
	testCase{A="ready",B="ready",C="ready"   ,[[ A C ... B A C ... B A C ... B ... ]]}
	-- A schedules itself after itself and resume C
	testCase{A="none" ,B="A"    ,C="none"    ,[[ A C ...                 ]]}
	testCase{A="none" ,B="A"    ,C="ready"   ,[[ A C ... C ... C ...     ]]}
	testCase{A="ready",B="A"    ,C="none"    ,[[ A C ... A ... A ...     ]]}
	testCase{A="ready",B="A"    ,C="ready"   ,[[ A C ... C A ... C A ... ]]}
	-- A schedules itself after itself and resume itself
	testCase{A="none" ,B="A"    ,C="A"       ,[[ A A ...       ]]}
	testCase{A="ready",B="A"    ,C="A"       ,[[ A A ... A ... ]]}
end
