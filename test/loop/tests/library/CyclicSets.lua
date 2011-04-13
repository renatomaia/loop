local checks = require "loop.test.checks"
local assert = checks.assert
local like = checks.like

local CyclicSets = require "loop.collection.CyclicSets"

function string.escape(str)
	return str:gsub("([%.%?%*%+%-%[%]%(%)%^%$])", "%%%%%1")
end

function string.trim(str)
	return str:gsub("^ *(.-) *$", "%1")
end

local function create(spec)
	local instance = CyclicSets()
	for set in spec:gmatch("([^|]+)") do
		local last
		for item in set:gmatch("([^, ]+)") do
			instance:add(item, last)
			last = item
		end
	end
	return instance
end

local function values(spec)
	local result = {}
	if spec:match('^ error ".*"$') then
		result[1] = spec
	else
		local count = 0
		for value in spec:gmatch("([^, ]+)") do
			value = value:trim()
			count = count + 1
			if value == "true" then
				result[count] = true
			elseif value == "false" then
				result[count] = false
			elseif value ~= "nil" then
				result[count] = tonumber(value) or value
			end
		end
		result.n = count
	end
	return result
end

local function packres(success, ...)
	if not success then
		return { string.format(" error %q", string.match(..., ":%d+: (.+)")) }
	end
	return { n = select("#", ...), ... }
end

local function showvalues(values)
	if values.n then
		local result = {}
		for i = 1, values.n do
			result[i] = tostring(values[i])
		end
		return table.concat(result, ", ")
	end
	return values[1]
end

local CaseFmt = "%s:%s(%s) -> %%s : %%s"
local ErrorFmt = [[expected transition failed:
	Case: %s
	Was : %s
]]

local pattern = "^%-%- %[ (.+) %] *:(%w+)%((.*)%) +%-%-> %[ (.+) %] +:(.*)$"
local autocases = {
	{ pat = "(%.%.+)", args = "(%w+)(ID)(%w+)",
		"%1, %3",
		"%1, a, %3",
		"%1, a, b, %3",
		"%1, a, b, c, %3",
	},
	{ pat = "(%?+)", args = "(ID)",
		"",
		", x",
		", x, y",
		"| x",
		"| x, y",
		", x | y",
		", x, y | z",
		", x | y, z",
		", x, y | w, z",
	},
}

return function()
	local source
	for path in package.path:gmatch("[^;]+") do
		path = path:gsub("%?", "loop/collection/CyclicSets")
		source = io.open(path)
		if source then break end
	end
	if source == nil then error("unable to locate 'CyclicSets' source file") end
	
	for line in source:lines() do
		local pre, method, par, pos, res = line:match(pattern)
		if pre then
			params = values(par)
			results = values(res)
			local function runtest(pre, pos)
				local actual = create(pre)
				local expected = create(pos)
				local case = CaseFmt:format(tostring(actual), method, showvalues(params))
				local returned = packres(pcall(actual[method], actual, unpack(params, 1, params.n)))
				local errormsg = ErrorFmt:format(case:format(tostring(expected), showvalues(results)),
				                                 case:format(tostring(actual), showvalues(returned)))
				assert(actual, like(expected, errormsg))
				assert(returned, like(results, errormsg))
			end
			local function autotest(index, pre, pos)
				local case = autocases[index]
				if case then
					local id = pre:match(case.pat)
					if id then
						local pattern = case.args:gsub("ID", id:escape())
						local function donames(name)
							return name:rep(#id)
						end
						for _, replace in ipairs(case) do
							replace = replace:gsub("(%l)", donames)
							autotest(index,
								pre:gsub(pattern, replace),
								pos:gsub(pattern, replace))
						end
					else
						return autotest(index+1, pre, pos)
					end
				else
					return runtest(pre, pos)
				end
			end
			autotest(1, pre, pos)
		end
	end
	source:close()
end
