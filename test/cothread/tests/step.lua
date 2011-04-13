return function()
	newTest{ "A steps B",
		tasks = {
			A = function(_ENV) step(B) end,
			B = Yielder(1),
		},
	}
	testCase{A = "outer",B=nil       ,[[ ...         ]]}
	testCase{A = "outer",B="none"    ,[[ B ...       ]]}
	testCase{A = "outer",B="ready"   ,[[ B ... B ... ]]}
	
	newTest{ "A steps B that yields to C that yields back to B",
		tasks = {
			A = function(_ENV) chkresults(step(B, getparams())) end,
			B = function(_ENV, ...) return yield("yield", C, ...) end,
			C = function(_ENV, ...) return yield("yield", B, ...) end,
		},
	}
	testCase{A = "outer",B="none" ,C="none"    ,[[ B C B ...       ]]}
	testCase{A = "outer",B="none" ,C="none"    ,[[ B C B ...       ]]}
	testCase{A = "outer",B="ready",C="none"    ,[[ B C B ...       ]]}
	testCase{A = "outer",B="ready",C="none"    ,[[ B C B ...       ]]}
	testCase{A = "outer",B="none" ,C="ready"   ,[[ B C B ... C ... ]]}
	testCase{A = "outer",B="none" ,C="ready"   ,[[ B C B ... C ... ]]}
	testCase{A = "outer",B="ready",C="ready"   ,[[ B C B ... C ... ]]}
	testCase{A = "outer",B="ready",C="ready"   ,[[ B C B ... C ... ]]}
end
