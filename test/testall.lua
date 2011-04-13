package.path = "../lua/?.lua;"..package.path

local Results = require "loop.test.Results"
local Reporter = require "loop.test.Reporter"
local exec = Results{ reporter = Reporter{ time = socket and socket.gettime } }
exec:test("LOOP", require("loop.tests.Suite"), exec)

require("cothread.tests.Suite")
