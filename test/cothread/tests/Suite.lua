local Fixture = require "loop.test.Fixture"
local Suite = require "loop.test.Suite"
local utils = require "cothread.tests.utils"
local oo = require "loop.cached"

cothread = require "cothread"
--Labels = cothread.verbose.viewer.labels
--cothread.verbose:level(2)
--cothread.verbose:flag("socket", true)
--cothread.verbose:flag("state", true)
--require "inspector"

local LogFixture = oo.class({setup=function()
	resetlog()
	resetscheduler(cothread)
end}, Fixture)

return Suite{
	schedule = LogFixture{require "cothread.tests.schedule"},
	unschedule = LogFixture{require "cothread.tests.unschedule"},
	--notify = LogFixture{require "cothread.tests.notify"},
	--cancel = LogFixture{require "cothread.tests.cancel"},
	suspend = LogFixture{require "cothread.tests.suspend"},
	rescheduled = LogFixture{require "cothread.tests.rescheduled"},
	delay = LogFixture{require "cothread.tests.delay"},
	resume_blocked = LogFixture{require "cothread.tests.resume_blocked"},
	socket = LogFixture{require "cothread.tests.socket"},
	--select = LogFixture{require "cothread.tests.select"},
}
