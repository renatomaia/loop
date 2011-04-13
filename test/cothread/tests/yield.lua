return function()
	newTest{ "A yields to B",
		tasks = {
			A = function(_ENV) yield("yield", B) end,
			B = Yielder(2),
		},
	}
	-- A yields
	testCase{A="none" ,B=nil        ,[[ A ...                 ]]}
	testCase{A="ready",B=nil        ,[[ A ... A ...           ]]}
	-- A yields to B
	testCase{A="none" ,B="none"     ,[[ A B ...               ]]}
	testCase{A="none" ,B="ready"    ,[[ A B ... B ... B ...   ]]}
	testCase{A="ready",B="none"     ,[[ A B ... A ...         ]]}
	testCase{A="ready",B="ready"    ,[[ A B ... B A ... B ... ]]}
	-- A yields to itself
	testCase{A="none" ,B="A"        ,[[ A A ...               ]]}
	testCase{A="ready",B="A"        ,[[ A A ...               ]]}
	
	
	newTest{ "A yields to B and then yield two more times",
		tasks = {
			A = function(_ENV)
				yield("yield", B)
				yield("yield")
				yield("yield")
			end,
			B = Yielder(2),
		},
	}
	-- A yields
	testCase{A="none" ,B=nil        ,[[ A ...                         ]]}
	testCase{A="ready",B=nil        ,[[ A ... A ... A ... A ...       ]]}
	-- A yields to B
	testCase{A="none" ,B="none"     ,[[ A B ...                       ]]}
	testCase{A="none" ,B="ready"    ,[[ A B ... B ... B ...           ]]}
	testCase{A="ready",B="none"     ,[[ A B ... A ... A ... A ...     ]]}
	testCase{A="ready",B="ready"    ,[[ A B ... B A ... B A ... A ... ]]}
	-- A yields to itself
	testCase{A="none" ,B="A"        ,[[ A A ...                       ]]}
	testCase{A="ready",B="A"        ,[[ A A ... A ... A ...           ]]}
	
	
	newTest{ "A yields some values to B",
		tasks = {
			A = function(_ENV) return chkresults(yield("yield", B, getparams())) end,
			B = function(_ENV, ...) return chkresults(...) end,
		},
	}
	-- A yields some values to B
	testCase{A="none" ,B="none"     ,[[ A B ...       ]]}
	testCase{A="none" ,B="ready"    ,[[ A B ...       ]]}
	testCase{A="ready",B="none"     ,[[ A B ... A ... ]]}
	testCase{A="ready",B="ready"    ,[[ A B ... A ... ]]}
	-- A yields some values to itself
	testCase{A="none" ,B="A"        ,[[ A A ... ]]}
	testCase{A="ready",B="A"        ,[[ A A ... ]]}
end
