return function()
	newTest{ "A suspends to B",
		tasks = {
			A = function(_ENV) yield("suspend", B) end,
			B = Yielder(2),
		},
	}
	-- A suspends
	testCase{A="none" ,B=nil       ,[[ A ... ]]}
	testCase{A="ready",B=nil       ,[[ A ... ]]}
	-- A suspends to B
	testCase{A="none" ,B="none"    ,[[ A B ...             ]]}
	testCase{A="none" ,B="ready"   ,[[ A B ... B ... B ... ]]}
	testCase{A="ready",B="none"    ,[[ A B ...             ]]}
	testCase{A="ready",B="ready"   ,[[ A B ... B ... B ... ]]}
	-- A suspends to itself
	testCase{A="none" ,B="A"       ,[[ A A ... ]]}
	testCase{A="ready",B="A"       ,[[ A A ... ]]}
end
