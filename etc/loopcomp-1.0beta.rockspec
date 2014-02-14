package = "LOOPComponents"
version = "1.0beta"
source = {
	url = "http://www.tecgraf.puc-rio.br/~maia/lua/packs/loopcomp-1.0beta.tar.gz",
}
description = {
	summary = "Component Models for Lua",
	detailed = [[
		The LOOP Component is a set of packages for supporting different models
		of component-based design in the Lua language.
	]],
	license = "MIT/X11",
	homepage = "http://www.tecgraf.puc-rio.br/~maia/lua/loop/component",
	maintainer = "Renato Maia <maia@tecgraf.puc-rio.br>",
}
dependencies = {
	"lua >= 5.1",
	"loop >= 3.0",
	"looplib >= 2.0beta",
}
build = {
	type = "none",
	install = {
		lua = {
			["loop.component.base"] = "lua/loop/component/base.lua",
			["loop.component.contained"] = "lua/loop/component/contained.lua",
			["loop.component.dynamic"] = "lua/loop/component/dynamic.lua",
			["loop.component.intercepted"] = "lua/loop/component/intercepted.lua",
			["loop.component.wrapped"] = "lua/loop/component/wrapped.lua",
		},
	},
}
