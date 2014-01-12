local _G = require "_G"
local error = _G.error
local ipairs = _G.ipairs
local pcall = _G.pcall
local require = _G.require
local select = _G.select
local tonumber = _G.tonumber
local tostring = _G.tostring

local io = require "io"
local open = io.open

local package = require "package"

local string = require "string"
local format = string.format
local match = string.match

local array = require "table"
local concat = array.concat
local unpack = array.unpack

local checks = require "loop.test.checks"
local assert = checks.assert
local like = checks.like
local is = checks.is

function string.escape(str)
	return str:gsub("([%.%?%*%+%-%[%]%(%)%^%$])", "%%%%%1")
end

function string.trim(str)
	return str:gsub("^ *(.-) *$", "%1")
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
		return { format(" error %q", match(..., ":%d+: (.+)")) }
	end
	return { n = select("#", ...), ... }
end

local function showvalues(values)
	if values.n then
		local result = {}
		for i = 1, values.n do
			result[i] = tostring(values[i])
		end
		return concat(result, ", ")
	end
	return values[1]
end

local CaseFmt = "%s:%s(%s) -> %%s : %%s"
local ErrorFmt = [[expected transition failed:
	Case: %s
	Was : %s
]]

local pattern = "^%-%- { (.+) } *:(%w+)%((.*)%) +%-%-> { (.+) } +:(.*)$"

return function(name, create, autocases, blackbox)
	local source
	for path in package.path:gmatch("[^;]+") do
		path = path:gsub("%?", "loop/collection/"..name)
		source = open(path)
		if source then break end
	end
	if source == nil then error("unable to locate '"..name.."' source file") end
	
	for line in source:lines() do
		local pre, method, par, pos, res = line:match(pattern)
		if pre then
			local params = values(par)
			local results = values(res)
			local function runtest(pre, pos)
				local actual = create(pre)
				local expected = create(pos)
				local case = CaseFmt:format(tostring(actual), method, showvalues(params))
				local returned = packres(pcall(actual[method], actual, unpack(params, 1, params.n)))
				local errormsg = ErrorFmt:format(case:format(tostring(expected), showvalues(results)),
				                                 case:format(tostring(actual), showvalues(returned)))
				if blackbox then
					assert(tostring(actual), is(tostring(expected), errormsg))
				else
					assert(actual, like(expected, errormsg))
				end
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
