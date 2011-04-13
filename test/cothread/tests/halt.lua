return function(cothread)
	newTest{ "A halts",
		tasks = {
			A = function(_ENV) requesthalt() end,
		},
	}
	testCase{A="outer"   ,[[   ]],[[ ... ]]}
	testCase{A="none"    ,[[ A ]],[[ ... ]]}
	testCase{A="ready"   ,[[ A ]],[[ ... ]]}
	
	
	newTest{ "A halts and then cancels it",
		tasks = {
			A = function(_ENV)
				requesthalt()
				cancelhalt()
			end,
		},
	}
	testCase{A="outer"   ,[[ ...   ]]}
	testCase{A="none"    ,[[ A ... ]]}
	testCase{A="ready"   ,[[ A ... ]]}
	
	
	newTest{ "A halts and yields to B",
		tasks = {
			A = function(_ENV)
				requesthalt()
				yield("yield", B)
			end,
			B = Yielder(2),
		},
	}
	testCase{A="none" ,B="none"    ,[[ A B ]],[[ ...               ]]}
	testCase{A="none" ,B="ready"   ,[[ A B ]],[[ ... B ... B ...   ]]}
	testCase{A="ready",B="none"    ,[[ A B ]],[[ ... A ...         ]]}
	testCase{A="ready",B="ready"   ,[[ A B ]],[[ ... B A ... B ... ]]}
	
	
	newTest{ "A halts and yields to B that cancels the halt and yields",
		tasks = {
			A = function(_ENV)
				requesthalt()
				yield("yield", B)
			end,
			B = function(_ENV)
				cancelhalt()
				yield("yield")
			end,
		},
	}
	testCase{A="none" ,B="none"    ,[[ A B ...         ]]}
	testCase{A="none" ,B="ready"   ,[[ A B ... B ...   ]]}
	testCase{A="ready",B="none"    ,[[ A B ... A ...   ]]}
	testCase{A="ready",B="ready"   ,[[ A B ... B A ... ]]}
end
