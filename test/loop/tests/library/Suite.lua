local Suite = require "loop.test.Suite"

return Suite{
	Viewer       = require "loop.tests.library.Viewer",
	Wrapper      = require "loop.tests.library.Wrapper",
	Publisher    = require "loop.tests.library.Publisher",
	CyclicSets   = require "loop.tests.library.CyclicSets",
	--SortedMap    = require "loop.tests.library.SortedMap",
}
