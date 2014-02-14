local input = {}
assert(loadfile(..., "t", input))()

local install = input.build.install
for kind, files in pairs(install) do
	for module, filepath in pairs(files) do
		io.write(filepath, " ")
	end
end

print()
