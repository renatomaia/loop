package = "Tuple"
version = "1.0beta"
source = {
	url = "http://www.tecgraf.puc-rio.br/~maia/lua/packs/luatuple-1.0beta.tar.gz",
}
description = {
	summary = "Tuple of Values for Lua.",
	detailed = [[
		Tuples is a library that provides support for internalized tokens that
		represent a tuple of Lua values.
	]],
	license = "MIT/X11",
	homepage = "http://www.tecgraf.puc-rio.br/~maia/lua/tuple",
	maintainer = "Renato Maia <maia@tecgraf.puc-rio.br>",
}
dependencies = {
	"lua >= 5.1",
}
build = {
	type = "none",
	install = {
		lua = {
			["tuple.weak"] = "lua/tuple/weak.lua",
			["tuple"] = "lua/tuple.lua",
		},
	},
}
