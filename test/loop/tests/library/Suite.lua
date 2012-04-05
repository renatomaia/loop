local Suite = require "loop.test.Suite"

return Suite{
	Viewer       = require "loop.tests.library.Viewer",
	Wrapper      = require "loop.tests.library.Wrapper",
	Publisher    = require "loop.tests.library.Publisher",
	CyclicSets   = require "loop.tests.library.CyclicSets",
	Queue        = require "loop.tests.library.Queue",
	LRUCache     = require "loop.tests.library.LRUCache",
	StringStream = require "loop.tests.library.Streams",
	--SortedMap    = require "loop.tests.library.SortedMap",
}
