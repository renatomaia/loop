local socket = require "socket.core"

do
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
	do
		local pair
		newTest{ "S writes to socket and schedules T to read the peer socket",
			tasks = {
				S = function(_ENV)
					pair = newsockpair()
					assert(addwait(pair.socket, "r", T) == true)
					pair:notify()
				end,
				N = function(_ENV)
					pair:notify()
				end,
				T = function(_ENV)
					pair:consume()
					removewait(pair.socket, "r", T)
					yield("yield")
				end,
			},
		}
	end
	-- S writes to socket and schedules T to read the peer socket
	testCase{S="outer",N="none" ,T="none" ,[[   ...   T ...       ]]}
	testCase{S="outer",N="none" ,T="ready",[[   ...   T ... T ... ]]}
	testCase{S="outer",N="ready",T="none" ,[[   ... N T ...       ]]}
	testCase{S="outer",N="ready",T="ready",[[   ... N T ... T ... ]]}
	testCase{S="none" ,N="none" ,T="none" ,[[ S ...   T ...       ]]}
	testCase{S="none" ,N="none" ,T="ready",[[ S ...   T ... T ... ]]}
	testCase{S="none" ,N="ready",T="none" ,[[ S ... N T ...       ]]}
	testCase{S="none" ,N="ready",T="ready",[[ S ... N T ... T ... ]]}
	testCase{S="ready",N="none" ,T="none" ,[[ S ...   T ...       ]]}
	testCase{S="ready",N="none" ,T="ready",[[ S ...   T ... T ... ]]}
	testCase{S="ready",N="ready",T="none" ,[[ S ... N T ...       ]]}
	testCase{S="ready",N="ready",T="ready",[[ S ... N T ... T ... ]]}

	do
		local pair
		newTest{ "S writes to socket and schedules T to read the peer socket",
			tasks = {
				S = function(_ENV)
					pair = newsockpair()
					assert(addwait(pair.socket, "r", T) == true)
				end,
				N = function(_ENV)
					pair:notify()
					yield("yield")
					pair:notify()
				end,
				T = function(_ENV)
					pair:consume()
					yield("yield")
					pair:consume()
					removewait(pair.socket, "r", T)
					yield("yield")
				end,
			},
		}
	end
	-- S writes to socket and schedules T to read the peer socket
--	testCase{S="outer",N="ready",T="none" ,[[   ... N T ... N T ...       ]]}
--	testCase{S="outer",N="ready",T="ready",[[   ... N T ... N T ... T ... ]]}
--	testCase{S="none" ,N="ready",T="none" ,[[ S ... N T ... N T ...       ]]}
--	testCase{S="none" ,N="ready",T="ready",[[ S ... N T ... N T ... T ... ]]}
--	testCase{S="ready",N="ready",T="none" ,[[ S ... N T ... N T ...       ]]}
--	testCase{S="ready",N="ready",T="ready",[[ S ... N T ... N T ... T ... ]]}
end
end
