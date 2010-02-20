local Suite = require "loop.test.Suite"
local utils = require "cothread.tests.utils"

require "cothread"
--Labels = cothread.verbose.viewer.labels
--cothread.verbose:level(2)
--cothread.verbose:flag("socket", true)

return Suite{
	schedule = require "cothread.tests.schedule",
	unschedule = require "cothread.tests.unschedule",
	--unblock = require "cothread.tests.unblock",
	--cancel = require "cothread.tests.cancel",
	delay = require "cothread.tests.delay",
	resume_blocked = require "cothread.tests.resume_blocked",
	socket = require "cothread.tests.socket",
	--select = require "cothread.tests.select"
}
