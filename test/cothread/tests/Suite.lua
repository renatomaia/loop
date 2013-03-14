require "cothread.tests.utils"

local plugins = { false, "signal", "sleep", "socket" }

local tests = {
	"testitself",
	"yield",
	"unschedule",
	"last",
	"next",
	"after",
	"suspend",
	"step",
	"halt",
	signal = {
		"wait_notify",
		"wait_unschedule",
	},
	sleep = {
		"defer",
	},
	socket = {
		"luasocket",
		"socket_memleak",
	},
}

local function testcases(name, scheduler, cases)
	for _, name in ipairs(cases) do
		io.write("["..name.."] ... ")
		io.flush()
		local test = require("cothread.tests."..name)
		setTarget(scheduler)
		test(scheduler)
		print("OK ("..testCount()..")")
	end
end

local function testscheduler(name, scheduler)
	local loaded = {}
	for _, plugin in ipairs(plugins) do
		if plugin then
			scheduler.plugin(require("cothread.plugin."..plugin))
			loaded[#loaded+1] = plugin
		end
		local desc = #loaded>0 and " ("..table.concat(loaded, ", ")..")" or ""
		print(string.format("\n--- %-30s -----------------------------", name..desc))
		testcases(name, scheduler, tests)
		for _, plugin in ipairs(loaded) do
			local cases = tests[plugin]
			if cases ~= nil then
				testcases(name, scheduler, cases)
			end
		end
	end
end

local cothread = require "cothread"
testscheduler("Module", cothread)
testscheduler("Instance", cothread())
