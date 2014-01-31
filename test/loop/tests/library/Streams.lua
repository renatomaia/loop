return function()
	local tests = {}
	do
		local allchars = {}
		for i = 0, 255 do
			allchars[#allchars+1] = string.char(i)
		end
		allchars = table.concat(allchars)
		local table = {
			0/0,1/0,-1/0,
			allchars = allchars,
			[false] = false,
			[{}] = {},
			[function() end] = function() end,
		}
		tests[table] = function(recovered)
			for key, value in pairs(recovered) do
				if key == 1 then assert(value ~= value)
				elseif key == 2 then assert(value == 1/0)
				elseif key == 3 then assert(value == -1/0)
				elseif key == false then assert(value == false)
				elseif key == "allchars" then
					assert(value == allchars)
				elseif type(key) == "table" then
					assert(next(key) == nil)
					assert(next(value) == nil)
					assert(key ~= value)
				else
					assert(type(key) == "function")
					assert(type(value) == "function")
					assert(key~=value or (key==function()end and value==function()end))
				end
			end
		end
		
		local function dummy() return dummy, table end
		local shared = {
			[table] = table,
			[dummy] = dummy,
		}
		tests[shared] = function(recovered)
			local tabbak
			local fncbak
			for key, value in pairs(recovered) do
				assert(key == value)
				if type(key) == "table" then
					assert(tabbak == nil)
					tabbak = value
				else
					assert(type(key) == "function")
					assert(fncbak == nil)
					fncbak = value
				end
			end
			local r1, r2 = fncbak()
			assert(r1 == fncbak)
			assert(r2 == tabbak)
		end
	end
	do
		local obj = {}
		do
			local count = 0
			function obj.inc()
				count = count+1
				return count
			end
			function obj.dec()
				count = count-1
				return count
			end
		end
		
		tests[obj] = function(recovered)
			assert(recovered.inc() == 1)
			assert(recovered.inc() == 2)
			assert(recovered.inc() == 3)
			if _VERSION == "Lua 5.1" then
				assert(recovered.dec() == -1)
				assert(recovered.dec() == -2)
				assert(recovered.dec() == -3)
			else
				assert(recovered.dec() == 2)
				assert(recovered.dec() == 1)
				assert(recovered.dec() == 0)
			end
		end
	end
	
	local streams = {
		[require "loop.serial.StringStream"] = {
			args = function() end,
			reset = function() end,
		},
		[require "loop.serial.FileStream"] = {
			args = function()
				return { file=assert(io.tmpfile()) }
			end,
			reset = function(stream)
				stream.file:seek("set")
			end,
		},
	}
	for class, info in pairs(streams) do
		for value, checker in pairs(tests) do
			local stream = class(info.args())
			stream:register(package.loaded)
			stream:put(value)
			info.reset(stream)
			checker(stream:get())
		end

		local stream = class(info.args())
		stream:register(package.loaded)
		for value, checker in pairs(tests) do
			stream:put(value)
		end
		info.reset(stream)
		for value, checker in pairs(tests) do
			checker(stream:get())
		end
	end
end
