return function(checks)
	local socket = require "cothread.socket"
	
	Server = newtask("Server", function(name)
		local port = assert(socket.tcp())
		assert(port:bind("*", 1234))
		assert(port:listen())
		local i = 1
		while true do
			local conn = assert(port:accept())
			local reader = newtask("Reader"..i, function(name)
				local result, errmsg
				repeat
					result, errmsg = conn:receive()
					if result then
						assert(conn:send(result:reverse()))
						yield("delay", .1)
						assert(conn:send("\n"))
					end
				until not result
				yield("unschedule", Server)
			end)
			yield("resume", reader)
			i = i + 1
		end
	end)
	checks:assert(
		cothread.schedule(Server),
		checks.is(Server))
	
	for i = 1, 3 do
		local Client = newtask("Client"..i, function(name)
			local conn = socket.tcp()
			assert(conn:connect("localhost", 1234))
			for j = 1, i do
				assert(conn:send(")"..i..";"..j.."("))
				yield("delay", .1)
			end
			assert(conn:send("\n"))
			
			local result = assert(conn:receive())
			
			assert(conn:close())
		end)
		checks:assert(
			cothread.schedule(Client, "delay", .1),
			checks.is(Client))
	end
	
	
	resetlog()
	cothread.run()
	checks:assert(EventLog, checks.similar{ --[[table: 0x16b640]]
		"Server started",
		"Client1 started",
		"Client2 started",
		"Client3 started",
		"Reader1 started",
		"Reader2 started",
		"Reader3 started",
		"Client1 ended",
		"Reader1 ended",
		"Client2 ended",
		"Reader2 ended",
		"Client3 ended",
		"Reader3 ended",
	})
	
	checkend(checks, cothread)
end
