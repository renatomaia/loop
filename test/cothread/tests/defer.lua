return function()
	newTest{ "A schedules B deferred by T seconds",
		tasks = {
			A = function(_ENV) assert(schedule(B, "defer", now()+T) == B) end,
			B = Yielder(2),
		},
		T = 1,
	}
	-- A schedules B deferred
	testCase{A="outer",B="none"    ,[[   ...+ B ... B ... B ... ]]}
	testCase{A="outer",B="ready"   ,[[   ...+ B ... B ... B ... ]]}
	testCase{A="none" ,B="none"    ,[[ A ...+ B ... B ... B ... ]]}
	testCase{A="none" ,B="ready"   ,[[ A ...+ B ... B ... B ... ]]}
	testCase{A="ready",B="none"    ,[[ A ...+ B ... B ... B ... ]]}
	testCase{A="ready",B="ready"   ,[[ A ...+ B ... B ... B ... ]]}
	-- A schedules itself deferred
	testCase{A="none" ,B="A"       ,[[ A ... ]]}
	testCase{A="ready",B="A"       ,[[ A ... ]]}
	
	
	newTest{ "A yields to schedule B deferred by T seconds and then yields again",
		tasks = {
			A = function(_ENV)
				assert(yield("schedule", B, "defer", now()+T) == B)
				yield("yield")
			end,
			B = Yielder(2),
		},
		T = 1,
	}
	-- A yields to schedule B and then yields again
	testCase{A="none" ,B="none"    ,[[ A A       ...+ B ... B ... B ... ]]}
	testCase{A="none" ,B="ready"   ,[[ A A       ...+ B ... B ... B ... ]]}
	testCase{A="ready",B="none"    ,[[ A A ... A ...+ B ... B ... B ... ]]}
	testCase{A="ready",B="ready"   ,[[ A A ... A ...+ B ... B ... B ... ]]}
	-- A yields to schedule itself and then yields again
	testCase{A="none" ,B="A"       ,[[ A A ...+ A ... ]]}
	testCase{A="ready",B="A"       ,[[ A A ...+ A ... ]]}
	
	
	newTest{ "A defers itself by T seconds and resumes B",
		tasks = {
			A = function(_ENV) yield("defer", now()+T, B) end,
			B = Yielder(2),
		},
		T = 1,
	}
	-- A defers itself
	testCase{A="none" ,B=nil        ,[[ A ...+ A ... ]]}
	testCase{A="ready",B=nil        ,[[ A ...+ A ... ]]}
	-- A defers itself and resumes B
	testCase{A="none" ,B="none"     ,[[ A B             ...+ A ... ]]}
	testCase{A="none" ,B="ready"    ,[[ A B ... B ... B ...+ A ... ]]}
	testCase{A="ready",B="none"     ,[[ A B             ...+ A ... ]]}
	testCase{A="ready",B="ready"    ,[[ A B ... B ... B ...+ A ... ]]}
	-- A defers itself and resumes itself
	testCase{A="none" ,B="A"        ,[[ A A ... ]]}
	testCase{A="ready",B="A"        ,[[ A A ... ]]}
	
	
	newTest{ "A defers itself by T seconds and resumes B then later yields",
		tasks = {
			A = function(_ENV)
				yield("defer", now()+T, B)
				yield("yield")
			end,
			B = Yielder(2),
		},
		T = 1,
	}
	-- A defers itself
	testCase{A="none" ,B=nil        ,[[ A ...+ A ... A ... ]]}
	testCase{A="ready",B=nil        ,[[ A ...+ A ... A ... ]]}
	-- A defers itself and resumes B
	testCase{A="none" ,B="none"     ,[[ A B             ...+ A ... A ... ]]}
	testCase{A="none" ,B="ready"    ,[[ A B ... B ... B ...+ A ... A ... ]]}
	testCase{A="ready",B="none"     ,[[ A B             ...+ A ... A ... ]]}
	testCase{A="ready",B="ready"    ,[[ A B ... B ... B ...+ A ... A ... ]]}
	-- A defers itself and resumes itself
	testCase{A="none" ,B="A"        ,[[ A A ...+ A ... ]]}
	testCase{A="ready",B="A"        ,[[ A A ...+ A ... ]]}
end
