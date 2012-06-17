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
	[io.stdout] = "userdata",
})
end

print "\n\nview packages"
do
	Viewer:write(table, string, os, io, math, debug)
end

print "\n\ncustom formating"
do
	local table = {
		"A", "B", "C", "D", "E", "F",
		struct = {
			field1 = "field one",
			field2 = "field two",
			field3 = "field three",
			nested = { nested = { nested = { nested = {} } } },
		},
		custom = setmetatable({"custom tostring"}, {
			__tostring = function(self) return self[1] end,
		})
	}
	table.self = table
	
	io.write "['tostring' metamethod only]: "
	local viewer = Viewer{ metaonly = true }
	viewer:write(table)
	
	io.write "\n[single line]: "
	local viewer = Viewer{
		nolabels = true,
		noindices = true,
		linebreak = false,
	}
	viewer:write(table)
	
	io.write "\n[bells and whistles]: "
	local viewer = Viewer{
		maxdepth = 2,
		prefix = "[bells and whistles]: ",
		indentation = "|   ",
		linebreak = "\n\r",
		output = io.strerr,
		metalabels = true, -- use '__tostring' metamethod to generate labels
	}
	viewer:write(table)
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
	table.self = table
	
	local viewer = Viewer{ nolabels = true } -- omit labels of values (e.g. table)
	viewer:write(table)
	
	local viewer = Viewer{ nofields = true } -- write fields as ordinary keys
	viewer:write(table)

	local viewer = Viewer{ noindices = true } -- omit array indices
	viewer:write(table)
	
	local viewer = Viewer{ noarrays = true } -- write array part as ordinary entries
	viewer:write(table)
end
