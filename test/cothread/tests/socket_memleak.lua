return function(cothread)
	local function memusage()
		local usage = collectgarbage("count")
		repeat
			local before = usage
			collectgarbage("collect")
			usage = collectgarbage("count")
		until before <= usage
		return usage
	end
	
	local socket = require "cothread.socket"
	local before = memusage()
	cothread.run(cothread.step(coroutine.create(function()
		for i = 1, 10^5 do
			socket.tcp():close()
		end
	end)))
	assert(before < 1.01*memusage())
end
