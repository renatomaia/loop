package = "Preloader"
version = "2.0"
source = {
	url = "http://www.tecgraf.puc-rio.br/~maia/lua/packs/luapreloader-2.0.tar.gz",
}
description = {
	summary = "Generator of Lua Module Pre-Loading Code.",
	detailed = [[
		Lua preloader is a script that generates C code that precompiles Lua code
		as modules that can be pre-loaded into a Lua execution state.
		It works as a sort of replacement for the old bin2c application that used
		to be included in the Lua distribution, however it is primarily intended
		to pre-compile and pre-load scripts that implement Lua modules.
	]],
	license = "MIT/X11",
	homepage = "http://www.tecgraf.puc-rio.br/~maia/lua/preloader",
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
		bin = {
			"lua/preloader.lua",
		},
	},
}
