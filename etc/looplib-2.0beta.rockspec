package = "LOOPLib"
version = "2.0beta"
source = {
	url = "http://www.tecgraf.puc-rio.br/~maia/lua/packs/looplib-2.0beta.tar.gz",
}
description = {
	summary = "Utility Classes using LOOP",
	detailed = [[
		The LOOP Class Library provides many useful use examples of LOOP classes
		ranging from single-table data structures to utilities for debugging,
		serialization, unit-testing and more.
	]],
	license = "MIT/X11",
	homepage = "http://www.tecgraf.puc-rio.br/~maia/lua/loop/classlib",
	maintainer = "Renato Maia <maia@tecgraf.puc-rio.br>",
}
dependencies = {
	"lua >= 5.1",
	"loop >= 3.0",
}
build = {
	type = "none",
	install = {
		lua = {
			["loop.collection.ArrayedMap"] = "lua/loop/collection/ArrayedMap.lua",
			["loop.collection.ArrayedSet"] = "lua/loop/collection/ArrayedSet.lua",
			["loop.collection.BiCyclicSets"] = "lua/loop/collection/BiCyclicSets.lua",
			["loop.collection.CyclicSets"] = "lua/loop/collection/CyclicSets.lua",
			["loop.collection.LRUCache"] = "lua/loop/collection/LRUCache.lua",
			["loop.collection.OrderedSet"] = "lua/loop/collection/OrderedSet.lua",
			["loop.collection.Queue"] = "lua/loop/collection/Queue.lua",
			["loop.collection.SortedMap"] = "lua/loop/collection/SortedMap.lua",
			["loop.collection.UnorderedArray"] = "lua/loop/collection/UnorderedArray.lua",
			["loop.compiler.Arguments"] = "lua/loop/compiler/Arguments.lua",
			["loop.debug.Crawler"] = "lua/loop/debug/Crawler.lua",
			["loop.debug.Matcher"] = "lua/loop/debug/Matcher.lua",
			["loop.debug.Verbose"] = "lua/loop/debug/Verbose.lua",
			["loop.debug.Viewer"] = "lua/loop/debug/Viewer.lua",
			["loop.object.Dummy"] = "lua/loop/object/Dummy.lua",
			["loop.object.Exception"] = "lua/loop/object/Exception.lua",
			["loop.object.Publisher"] = "lua/loop/object/Publisher.lua",
			["loop.object.Wrapper"] = "lua/loop/object/Wrapper.lua",
			["loop.serial.FileStream"] = "lua/loop/serial/FileStream.lua",
			["loop.serial.Serializer"] = "lua/loop/serial/Serializer.lua",
			["loop.serial.Stream"] = "lua/loop/serial/Stream.lua",
			["loop.serial.StringStream"] = "lua/loop/serial/StringStream.lua",
			["loop.test.checks"] = "lua/loop/test/checks.lua",
			["loop.test.Fixture"] = "lua/loop/test/Fixture.lua",
			["loop.test.Reporter"] = "lua/loop/test/Reporter.lua",
			["loop.test.Results"] = "lua/loop/test/Results.lua",
			["loop.test.Suite"] = "lua/loop/test/Suite.lua",
		},
	},
}
