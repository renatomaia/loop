cothread = require "cothread"
cothread.plugin(require "cothread.plugin.socket")
socket = require "cothread.socket"
labels = {}
--cothread.verbose:level(3)
--labels = cothread.verbose.viewer.labels

portno = 1234
delay = .1
clients = 9

Server = coroutine.create(function()
	local port = assert(socket.tcp())
	assert(port:bind("*", portno))
	assert(port:listen())
	local i = 0
	while true do
		local conn = assert(port:accept())
		local reader = coroutine.create(function()
			local result, errmsg
			repeat
				result, errmsg = conn:receive()
				if result then
					assert(conn:send(result:reverse()))
					coroutine.yield("delay", delay)
					assert(conn:send("\n"))
				end
			until result == nil
			i = i-1
			if i == 0 then
				coroutine.yield("unschedule", Server)
			end
		end)
		i = i+1
		labels[reader] = "Reader"..i
		coroutine.yield("last", reader)
	end
end)
labels[Server] = "Server"
assert(cothread.schedule(Server) == Server)

for i = 1, clients do
	local Client = coroutine.create(function()
		local conn = socket.tcp()
		assert(conn:connect("localhost", portno))
		for j = 1, i do
			assert(conn:send(")"..i..";"..j.."("))
			coroutine.yield("delay", delay)
		end
		assert(conn:send("\n"))
		local result = assert(conn:receive())
		print(string.format("%.4f - Client %d got '%s'",
		                    socket.gettime()-start, i, result))
		assert(conn:close())
	end)
	labels[Client] = "Client"..i
	assert(cothread.schedule(Client, "delay", delay) == Client)
end

start = socket.gettime()
cothread.run()
