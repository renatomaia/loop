local socket = require "socket.core"
local EventPoll = require "cothread.EventPoll"

local function newsockpair()
	local read = assert(socket.tcp())
	assert(read:settimeout(0))
	assert(read:listen())
	local pair = { socket = read }
	function pair:notify()
		local _, port = assert(read:getsockname())
		local write = assert(socket.tcp())
		assert(write:settimeout(0))
		assert(write:connect("localhost", port) == nil)
		socket.sleep(.1) -- let socket event be propagated
		--assert(write:close())
	end
	function pair:consume()
		assert(assert(read:accept()):close())
	end
	return pair
end

return function(cothread)

--cothread.verbose:level(100)

	newTest{ "S",
		tasks = {
			S = function(_ENV)
				local poll = EventPoll()
				local res, err = poll:getready()
				assert(res == nil)
				assert(err == "empty")
				res, err = poll:getready(.1)
				assert(res == nil)
				assert(err == "empty")
			end,
		},
	}
	testCase{S="none"  ,[[ S ... ]]}
	testCase{S="ready" ,[[ S ... ]]}

	newTest{ "S",
		tasks = {
			S = function(_ENV)
				local poll = EventPoll()
				local pair = newsockpair()
				poll:add(pair.socket, "r")
				pair:notify()
				poll:getready(.1)
				yield("yield")
			end,
		},
	}

	testCase{S="none"  ,[[ S ...+ ]]}
	testCase{S="ready" ,[[ S ...+ ]]}

	newTest{ "S",
		tasks = {
			S = function(_ENV)
				local poll = EventPoll()
				poll:add(socket.tcp(), "r")
				poll:getready(.1)
				yield("yield")
			end,
		},
	}
	testCase{S="none"  ,[[ S ...+ S ... ]]}
	testCase{S="ready" ,[[ S ...+ S ... ]]}

	newTest{ "S",
		tasks = {
			S = function(_ENV)
				local poll = EventPoll()
				local pair = newsockpair()
				poll:add(pair.socket, "r")
				poll:getready(.1)
				yield("yield")
				poll:getready(.1)
				yield("yield")
				pair:notify()
			end,
		},
	}
	testCase{S="none"  ,[[ S ...+ S ...+ S ... ]]}
	testCase{S="ready" ,[[ S ...+ S ...+ S ... ]]}

	newTest{ "S",
		tasks = {
			S = function(_ENV)
				local poll = EventPoll()
				local pair = newsockpair()
				poll:add(pair.socket, "r")
				pair:notify()
				poll:remove(pair.socket, "r")
				local res, err = poll:getready()
				assert(res == nil)
				assert(err == "empty")
				res, err = poll:getready(.1)
				assert(res == nil)
				assert(err == "empty")
			end,
		},
	}
	testCase{S="none"  ,[[ S ...+ ]]}
	testCase{S="ready" ,[[ S ...+ ]]}

end
