return function()
	newTest{ "A does nothing",
		tasks = {
			A = function() end,
			B = function() end,
			C = function() end,
		},
	}
	testCase{A="outer",B=nil    ,C=nil       ,[[ ...           ]]}
	testCase{A="outer",B=nil    ,C="none"    ,[[ ...           ]]}
	testCase{A="outer",B=nil    ,C="ready"   ,[[ ... C ...     ]]}
	testCase{A="outer",B="none" ,C=nil       ,[[ ...           ]]}
	testCase{A="outer",B="none" ,C="none"    ,[[ ...           ]]}
	testCase{A="outer",B="none" ,C="ready"   ,[[ ... C ...     ]]}
	testCase{A="outer",B="ready",C=nil       ,[[ ... B ...     ]]}
	testCase{A="outer",B="ready",C="none"    ,[[ ... B ...     ]]}
	testCase{A="outer",B="ready",C="ready"   ,[[ ... B C ...   ]]}
	testCase{A="none" ,B=nil    ,C=nil       ,[[ A ...         ]]}
	testCase{A="none" ,B=nil    ,C="none"    ,[[ A ...         ]]}
	testCase{A="none" ,B=nil    ,C="ready"   ,[[ A ... C ...   ]]}
	testCase{A="none" ,B="none" ,C=nil       ,[[ A ...         ]]}
	testCase{A="none" ,B="none" ,C="none"    ,[[ A ...         ]]}
	testCase{A="none" ,B="none" ,C="ready"   ,[[ A ... C ...   ]]}
	testCase{A="none" ,B="ready",C=nil       ,[[ A ... B ...   ]]}
	testCase{A="none" ,B="ready",C="none"    ,[[ A ... B ...   ]]}
	testCase{A="none" ,B="ready",C="ready"   ,[[ A ... B C ... ]]}
	testCase{A="ready",B=nil    ,C=nil       ,[[ A ...         ]]}
	testCase{A="ready",B=nil    ,C="none"    ,[[ A ...         ]]}
	testCase{A="ready",B=nil    ,C="ready"   ,[[ A ... C ...   ]]}
	testCase{A="ready",B="none" ,C=nil       ,[[ A ...         ]]}
	testCase{A="ready",B="none" ,C="none"    ,[[ A ...         ]]}
	testCase{A="ready",B="none" ,C="ready"   ,[[ A ... C ...   ]]}
	testCase{A="ready",B="ready",C=nil       ,[[ A ... B ...   ]]}
	testCase{A="ready",B="ready",C="none"    ,[[ A ... B ...   ]]}
	testCase{A="ready",B="ready",C="ready"   ,[[ A ... B C ... ]]}
end
