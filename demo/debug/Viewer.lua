Viewer = require "loop.debug.Viewer"

print "\nview simple values"
do
	Viewer:write(nil, true, math.pi, [[
Hello, World!
Good bye, cruel world!
]], "\0\1\2\3\4\5", {
	1,2,3,4,5,
	field = "field value",
	[{}] = "table",
	[function() end] = "function",
	[coroutine.create(function() end)] = "thread",
	[newproxy()] = "userdata",
})
end

print "\n\nview packages"
do
	Viewer:write(table, string, os, io, math, debug)
end

print "\n\ncustom formating"
do
	local viewer = Viewer{
		maxdepth = 2,
		prefix = "--> ",
		indentation = "|   ",
		linebreak = "\n\r",
		output = io.strerr,
		tostringmeta = true, -- do not ignore '__tostring' metamethod
	}
	
	viewer:write(setmetatable({
		"A", "B", "C", "D", "E", "F",
		struct = {
			field1 = "field one",
			field2 = "field two",
			field3 = "field three",
			nested = { nested = { nested = { nested = {} } } },
		},
	}, {
		__tostring = function() return "custom tostring" end,
	}))
end

print "\n\ncustom string options"
do
	local viewer = Viewer{
		singlequotes = true, -- use singles quotes preferably
		noaltquotes = true, -- use only one kind quotation mark (either ' or ")
		nolongbrackets = true, -- do not write string using long brackets
	}
	
	viewer:write("single quotes (') or double quotes (\")",
	             "one line\nanother line\nyet another line\n")
end

print "\n\ncustom table options"
do
	local table = {
		"A", nil, "C", nil, "E", "F",
		field1 = "field one",
		field2 = "field two",
		field3 = "field three",
	}
	
	local viewer = Viewer{ nolabels = true } -- omit labels of values (e.g. table)
	viewer:write(table)
	
	local viewer = Viewer{ nofields = true } -- write fields as ordinary keys
	viewer:write(table)

	local viewer = Viewer{ noindices = true } -- omit array indices
	viewer:write(table)
	viewer.noarrays = true -- write array part as ordinary entries
	viewer:write(table)
end
