return function()
	newTest{ "A unschedules B",
		tasks = {
			A = function(_ENV) assert(unschedule(B) == (OK and B or nil)) end,
			B = Yielder(2),
		},
	}
	-- A unschedules B
	testCase{A="outer",B="none"    ,OK=false    ,[[ ...   ]]}
	testCase{A="outer",B="ready"   ,OK=true     ,[[ ...   ]]}
	testCase{A="none" ,B="none"    ,OK=false    ,[[ A ... ]]}
	testCase{A="none" ,B="ready"   ,OK=true     ,[[ A ... ]]}
	testCase{A="ready",B="none"    ,OK=false    ,[[ A ... ]]}
	testCase{A="ready",B="ready"   ,OK=true     ,[[ A ... ]]}
	-- A unschedules itself
	testCase{A="none" ,B="A"       ,OK=false    ,[[ A ... ]]}
	testCase{A="ready",B="A"       ,OK=true     ,[[ A ... ]]}
	
	
	newTest{ "A yields to unschedule B and then yields again",
		tasks = {
			A = function(_ENV)
				assert(yield("unschedule", B) == (OK and B or nil))
				yield("yield")
			end,
			B = Yielder(2),
		},
	}
	-- A yields to unschedule B and then yields again
	testCase{A="none" ,B="none"    ,OK=false    ,[[ A A ...       ]]}
	testCase{A="none" ,B="ready"   ,OK=true     ,[[ A A ...       ]]}
	testCase{A="ready",B="none"    ,OK=false    ,[[ A A ... A ... ]]}
	testCase{A="ready",B="ready"   ,OK=true     ,[[ A A ... A ... ]]}
	-- A yields to unschedule itself and then yields again
	testCase{A="none" ,B="A"       ,OK=false    ,[[ A A ... ]]}
	testCase{A="ready",B="A"       ,OK=true     ,[[ A A ... ]]}
end
