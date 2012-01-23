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
	
	
	local T
	newTest{ "A schedules B deferred by infinite seconds twice",
		tasks = {
			A = function(_ENV)
				T = now()+1
				assert(schedule(C, "defer", T) == C)
			end,
			B = function(_ENV)
				assert(schedule(C, "defer", T) == C)
			end,
			C = Yielder(2),
		},
	}
	-- A and B schedules D deferred and C unchedules it
	testCase{A="outer",B="ready",C="none" ,   [[ ... B ...+ C ... C ... C ... ]]}
	testCase{A="outer",B="ready",C="ready",   [[ ... B ...+ C ... C ... C ... ]]}
	testCase{A="none" ,B="ready",C="none" ,   [[ A ... B ...+ C ... C ... C ... ]]}
	testCase{A="none" ,B="ready",C="ready",   [[ A ... B ...+ C ... C ... C ... ]]}
	testCase{A="ready",B="ready",C="none" ,   [[ A ... B ...+ C ... C ... C ... ]]}
	testCase{A="ready",B="ready",C="ready",   [[ A ... B ...+ C ... C ... C ... ]]}


	newTest{ "A schedules B deferred by infinite seconds",
		tasks = {
			A = function(_ENV)
				assert(schedule(B, "defer", math.huge) == B)
				assert(unschedule(B) == B)
			end,
			B = Yielder(2),
		},
		T = 1,
	}
	-- A schedules C deferred
	testCase{A="outer",B="outer",   [[ ... ]]}
	testCase{A="outer",B="none" ,   [[ ... ]]}
	testCase{A="outer",B="ready",   [[ ... ]]}
	testCase{A="none" ,B="outer",   [[ A ... ]]}
	testCase{A="none" ,B="none" ,   [[ A ... ]]}
	testCase{A="none" ,B="ready",   [[ A ... ]]}
	testCase{A="ready",B="outer",   [[ A ... ]]}
	testCase{A="ready",B="none" ,   [[ A ... ]]}
	testCase{A="ready",B="ready",   [[ A ... ]]}
	-- A schedules itself deferred
	testCase{A="outer",B="A",   [[ ... ]]}
	testCase{A="none" ,B="A",   [[ A ... ]]}
	testCase{A="ready",B="A",   [[ A ... ]]}
	
	
	newTest{ "A schedules B deferred by infinite seconds twice",
		tasks = {
			A = function(_ENV)
				assert(schedule(D, "defer", math.huge) == D)
			end,
			B = function(_ENV)
				assert(schedule(D, "defer", math.huge) == D)
			end,
			C = function(_ENV)
				assert(unschedule(D) == D)
			end,
			D = Yielder(2),
		},
		T = 1,
	}
	-- A and B schedules D deferred and C unchedules it
	testCase{A="outer",B="ready",C="ready",D="outer",   [[ ... B C ... ]]}
	testCase{A="outer",B="ready",C="ready",D="none" ,   [[ ... B C ... ]]}
	testCase{A="outer",B="ready",C="ready",D="ready",   [[ ... B C ... ]]}
	testCase{A="none" ,B="ready",C="ready",D="outer",   [[ A ... B C ... ]]}
	testCase{A="none" ,B="ready",C="ready",D="none" ,   [[ A ... B C ... ]]}
	testCase{A="none" ,B="ready",C="ready",D="ready",   [[ A ... B C ... ]]}
	testCase{A="ready",B="ready",C="ready",D="outer",   [[ A ... B C ... ]]}
	testCase{A="ready",B="ready",C="ready",D="none" ,   [[ A ... B C ... ]]}
	testCase{A="ready",B="ready",C="ready",D="ready",   [[ A ... B C ... ]]}
	
	
	newTest{ "A schedules B deferred by infinite seconds twice",
		tasks = {
			A = function(_ENV)
				assert(schedule(D, "defer", math.huge) == D)
			end,
			B = function(_ENV)
				assert(schedule(E, "defer", math.huge) == E)
			end,
			C = function(_ENV)
				assert(unschedule(D) == D)
				assert(unschedule(E) == E)
			end,
			D = Yielder(2),
			E = Yielder(2),
		},
		T = 1,
	}
	-- A and B schedules D deferred and C unchedules it
	testCase{A="outer",B="ready",C="ready",D="outer",E="outer",   [[ ... B C ... ]]}
	testCase{A="outer",B="ready",C="ready",D="outer",E="none" ,   [[ ... B C ... ]]}
	testCase{A="outer",B="ready",C="ready",D="outer",E="ready",   [[ ... B C ... ]]}
	testCase{A="outer",B="ready",C="ready",D="none" ,E="outer",   [[ ... B C ... ]]}
	testCase{A="outer",B="ready",C="ready",D="none" ,E="none" ,   [[ ... B C ... ]]}
	testCase{A="outer",B="ready",C="ready",D="none" ,E="ready",   [[ ... B C ... ]]}
	testCase{A="outer",B="ready",C="ready",D="ready",E="outer",   [[ ... B C ... ]]}
	testCase{A="outer",B="ready",C="ready",D="ready",E="none" ,   [[ ... B C ... ]]}
	testCase{A="outer",B="ready",C="ready",D="ready",E="ready",   [[ ... B C ... ]]}
	
	testCase{A="none" ,B="ready",C="ready",D="outer",E="outer",   [[ A ... B C ... ]]}
	testCase{A="none" ,B="ready",C="ready",D="outer",E="none" ,   [[ A ... B C ... ]]}
	testCase{A="none" ,B="ready",C="ready",D="outer",E="ready",   [[ A ... B C ... ]]}
	testCase{A="none" ,B="ready",C="ready",D="none" ,E="outer",   [[ A ... B C ... ]]}
	testCase{A="none" ,B="ready",C="ready",D="none" ,E="none" ,   [[ A ... B C ... ]]}
	testCase{A="none" ,B="ready",C="ready",D="none" ,E="ready",   [[ A ... B C ... ]]}
	testCase{A="none" ,B="ready",C="ready",D="ready",E="outer",   [[ A ... B C ... ]]}
	testCase{A="none" ,B="ready",C="ready",D="ready",E="none" ,   [[ A ... B C ... ]]}
	testCase{A="none" ,B="ready",C="ready",D="ready",E="ready",   [[ A ... B C ... ]]}
	
	testCase{A="ready",B="ready",C="ready",D="outer",E="outer",   [[ A ... B C ... ]]}
	testCase{A="ready",B="ready",C="ready",D="outer",E="none" ,   [[ A ... B C ... ]]}
	testCase{A="ready",B="ready",C="ready",D="outer",E="ready",   [[ A ... B C ... ]]}
	testCase{A="ready",B="ready",C="ready",D="none" ,E="outer",   [[ A ... B C ... ]]}
	testCase{A="ready",B="ready",C="ready",D="none" ,E="none" ,   [[ A ... B C ... ]]}
	testCase{A="ready",B="ready",C="ready",D="none" ,E="ready",   [[ A ... B C ... ]]}
	testCase{A="ready",B="ready",C="ready",D="ready",E="outer",   [[ A ... B C ... ]]}
	testCase{A="ready",B="ready",C="ready",D="ready",E="none" ,   [[ A ... B C ... ]]}
	testCase{A="ready",B="ready",C="ready",D="ready",E="ready",   [[ A ... B C ... ]]}
end
