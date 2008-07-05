local Class = {}
function Class:__call(obj)
	return setmetatable(obj or {}, self)
end
Class:__call(Class)

--------------------------------------------------------------------------------

local function getpath(base, path)
	local replaces = 1
	for dir in base:gmatch("[^/]+/") do
		if replaces == 1
			then path, replaces = path:gsub("^"..dir, "")
			else replaces = replaces - 1
		end
	end
	return string.rep("../", -1*replaces+1)..path
end

--------------------------------------------------------------------------------

local Table = Class{ __index = table }
local tab = "\t"
local ident = 0
local function domenu(map, selected, output)
	if not output then output = Table() end
	output:insert('<div class="outside"><div class="inside"><ul>\n')
	local start = #output
	ident = ident+1
	for _, item in ipairs(map) do
		if item.index then
			output:insert(tab:rep(ident))
			output:insert('<li>')
			if item == selected then
				output:insert(string.format('<strong>%s</strong>', item.index))
			else
				local path = item.href
				if not path:match("^http://") then
					path = getpath(selected.href, item.href)
				end
				output:insert(string.format('<a href="%s", title="%s">%s</a>',
				                            path, item.title or "", item.index))
			end
			
			if #item > 0 and selected.href:find(item.href:match("^(.-)[^/]*$")) == 1 then
				ident = ident+1
				output:insert("\n")
				output:insert(tab:rep(ident))
				domenu(item, selected, output)
				ident = ident-1
			end
			output:insert('</li>\n')
		end
	end
	if #output == start then -- not item was added
		output[#output] = nil
	else
		ident = ident-1
		output:insert(tab:rep(ident))
		output:insert('</ul></div></div>\n')
		output:insert(tab:rep(ident-1))
	end
	return output
end

--------------------------------------------------------------------------------

local map = assert(loadstring(string.format("return {%s}", assert(io.open((...))):read("*a"))))()
local template = map[#map]
map[#map] = nil
if select("#", ...) > 1 then
	map.outputdir = select(2, ...)
end

local function index(items)
	for _, item in ipairs(items) do
		map[item] = item
		if item.index then
			assert(map[item.index] == nil, "duplicated page index '"..item.index.."'")
			map[item.index] = item
		end
		if item.title and map[item.title] == nil then
			map[item.title] = item
		end
		index(item)
	end
end

local Environment = Class{ __index = _G }
local function process(items)
	for _, item in ipairs(items) do
		if not item.href:match("^http://") and not item.href:match("#") then
			local environment = Environment{
				items = map,
				item = item,
				menu = function()
					return domenu(map, item):concat()
				end,
				contents = function(field)
					local file = io.open((map.sourcedir or ".").."/"..item[field or "href"])
					if file then return file:read("*a"), file:close() end
					io.stderr:write("unable to read input file 'source/",item[field or "href"],"'\n")
				end,
				href = function(path)
					return getpath(item.href, path)
				end,
				link = function(index, label, extra)
					index = assert(map[index], item.href..": unknown page tag "..tostring(index))
					return string.format('<a href="%s%s">%s</a>',
					                     getpath(item.href, index.href),
					                     extra or "",
					                     label or index.title or "")
				end,
			}
			local function dotag(code)
				return setfenv(assert(loadstring((code:gsub("^=", "return ")), item.href)), environment)() or ""
			end
			local page, replaces = template
			repeat
				page, replaces = page:gsub("<%%(.-)%%>", dotag)
			until replaces == 0
			local output = assert(io.open((map.outputdir or ".").."/"..item.href, "w"))
			output:write(page)
			output:close()
		end
		process(item)
	end
end

index(map)
process(map)
