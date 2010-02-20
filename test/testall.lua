package.path = "../lua/?.lua;"..package.path

local Results  = require "loop.test.Results"
local Reporter = require "loop.test.Reporter"

local results = Results{
	reporter = Reporter{
		time = socket and socket.gettime,
	},
}
results:test("LOOP", require("loop.tests.Suite"), results)
results:test("CoThread", require("cothread.tests.Suite"), results)
