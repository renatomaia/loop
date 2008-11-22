local Suite = require "loop.test.Suite"

return Suite{
	Models     = require "loop.tests.models.Suite",
	Components = require "loop.tests.component.Suite",
	Library    = require "loop.tests.library.Suite",
}
