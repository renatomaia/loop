local Suite = require "loop.test.Suite"

return Suite{
	Wrapper   = require "loop.tests.library.Wrapper",
	Publisher = require "loop.tests.library.Publisher",
	Scheduler = require "loop.tests.library.Scheduler",
}
