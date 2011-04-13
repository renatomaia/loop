require "cothread.tests.utils"

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
	--"instrospection",
	--"miscelania",
	"wait_notify",
	"wait_unschedule",
	"defer",
}

local function testscheduler(name, scheduler)
	print("\n--- "..name.." -----------------------------------")
	for _, name in ipairs(tests) do
		io.write("["..name.."] ... ")
		io.flush()
		local test = require("cothread.tests."..name)
		setTarget(scheduler)
		test(scheduler)
		print("OK ("..testCount()..")")
	end
end

local cothread = require "cothread"
cothread.loadplugin(require "cothread.plugin.signal")
cothread.loadplugin(require "cothread.plugin.sleep")
testscheduler("Module", cothread)
local new = cothread()
new.loadplugin(require "cothread.plugin.signal")
new.loadplugin(require "cothread.plugin.sleep")
testscheduler("Instance", new)
