return function()
	newTest{ "A schedules B as next",
		tasks = {
			A = function(_ENV) assert(schedule(B, "next") == B) end,
			B = Yielder(2),
		},
	}
	-- A schedules B as next
	testCase{A="outer",B="none"    ,[[ B ... B ... B ...   ]]}
	testCase{A="outer",B="ready"   ,[[ B ... B ... B ...   ]]}
	testCase{A="none" ,B="none"    ,[[ A B ... B ... B ... ]]}
	testCase{A="none" ,B="ready"   ,[[ A B ... B ... B ... ]]}
	testCase{A="ready",B="none"    ,[[ A B ... B ... B ... ]]}
	testCase{A="ready",B="ready"   ,[[ A B ... B ... B ... ]]}
	-- A schedules itself as next
	testCase{A="none" ,B="A"       ,[[ A ... ]]}
	testCase{A="ready",B="A"       ,[[ A ... ]]}
	
	
	newTest{ "A yields to schedule B as next and then yields again",
		tasks = {
			A = function(_ENV)
				assert(yield("schedule", B, "next") == B)
				yield("yield")
			end,
			B = Yielder(2),
		},
	}
	-- A yields to schedule B and then yields again
	testCase{A="none" ,B="none"    ,[[ A A B ... B ... B ...   ]]}
	testCase{A="none" ,B="ready"   ,[[ A A B ... B ... B ...   ]]}
	testCase{A="ready",B="none"    ,[[ A A B ... A B ... B ... ]]}
	testCase{A="ready",B="ready"   ,[[ A A B ... A B ... B ... ]]}
	-- A yields to schedule itself and then yields again
	testCase{A="none" ,B="A"       ,[[ A A A ... ]]}
	testCase{A="ready",B="A"       ,[[ A A A ... ]]}
	
	
	newTest{ "A yields to schedule itself as next and resumes B",
		tasks = {
			A = function(_ENV) yield("last", B) end,
			B = Yielder(2),
		},
	}
	-- A schedules itself as last
	testCase{A="none" ,B=nil       ,[[ A ... A ... ]]}
	testCase{A="ready",B=nil       ,[[ A ... A ... ]]}
	-- A schedules itself as last and resumes B
	testCase{A="none" ,B="none"    ,[[ A B ... A ...         ]]}
	testCase{A="none" ,B="ready"   ,[[ A B ... B A ... B ... ]]}
	testCase{A="ready",B="none"    ,[[ A B ... A ...         ]]}
	testCase{A="ready",B="ready"   ,[[ A B ... B A ... B ... ]]}
	-- A schedules itself as last and resumes ifself
	testCase{A="none" ,B="A"       ,[[ A A ... ]]}
	testCase{A="ready",B="A"       ,[[ A A ... ]]}
	
	
	newTest{ "A yields to schedule itself as next and resumes B and then yields",
		tasks = {
			A = function(_ENV)
				yield("next", B)
				yield("yield")
			end,
			B = Yielder(2),
		},
	}
	-- A schedules itself as next
	testCase{A="none" ,B=nil       ,[[ A A ... A ... ]]}
	testCase{A="ready",B=nil       ,[[ A A ... A ... ]]}
	-- A schedules itself as next and resumes B
	testCase{A="none" ,B="none"    ,[[ A B A ... A ...         ]]}
	testCase{A="none" ,B="ready"   ,[[ A B A ... B A ... B ... ]]}
	testCase{A="ready",B="none"    ,[[ A B A ... A ...         ]]}
	testCase{A="ready",B="ready"   ,[[ A B A ... B A ... B ... ]]}
	-- A schedules itself as next and resumes ifself
	testCase{A="none" ,B="A"       ,[[ A A A ... ]]}
	testCase{A="ready",B="A"       ,[[ A A A ... ]]}
end
