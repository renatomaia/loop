local http = require "socket.http"

local Class = {}
function Class:__call(obj)
	return setmetatable(obj or {}, self)
end
Class:__call(Class)

--------------------------------------------------------------------------------

local function getpath(base, path)
	if path:match("^http://") then return path end
	local replaces = 1
	for dir in base:gmatch("[^/]+/") do
		if replaces == 1
			then path, replaces = path:gsub("^"..dir, "")
			else replaces = replaces - 1
		end
	end
	return string.rep("../", -1*replaces+1)..path
end

local ContentsOf = {}
local function readcontents(path)
	local contents = ContentsOf[path]
	if contents == nil then
		if path:match("^http://") then
			--local code
			--contents, code = http.request(path)
			--if code ~= 200 then
			--	contents = nil
			--end
		else
			local file = assert(io.open(path))
			contents = assert(file:read("*a"))
			file:close()
		end
	end
	return contents
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
				output:insert('<strong>'..item.index..'</strong>')
			else
				local path = getpath(selected.href, item.href)
				output:insert('<a href="'..path..'", title="'..(item.title or "")..'">'
				              ..item.index..'</a>')
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

if _VERSION == "Lua 5.1" then
	local function loadresults(env, chunk, errmsg)
		if chunk == nil then
			return nil, errmsg
		end
		if env ~= nil then setfenv(chunk, env) end
		return chunk
	end
	local loadfile51 = loadfile
	function loadfile(filename, mode, env)
		return loadresults(env, loadfile51(filename))
	end
	local load51 = load
	function load(ld, source, mode, env)
		local loadfunc = (type(ld)=="string") and loadstring or lua51
		return loadresults(env, loadfunc(ld, source))
	end
end

local site = {}
assert(loadfile((...), nil, site))()

local outputdir = site.outputdir or "."
if select("#", ...) > 1 then
	outputdir = select(2, ...)
end

local map = {}
local AnchorPattern = '<%s*a%s+name%s*=%s*"([^"]+)"%s*>(.-)<%s*/%s*a%s*>'

local function addpage(item)
	local index = item.index
	if index ~= nil then
		assert(map[index] == nil, "duplicated page '"..index.."'")
		map[index] = item
	end
	local title = item.title
	if title ~= nil and map[title] == nil then
		map[title] = item
	end
end

local function addlinks(items)
	for _, item in ipairs(items) do
		addpage(item)
		local href = item.href
		local index = item.index
		local contents = readcontents(href)
		if contents ~= nil then
			for anchor, title in contents:gmatch(AnchorPattern) do
				local id = anchor
				local alias = item.alias
				if alias ~= nil then
					id = alias[anchor] or id
				end
				addpage({
					index = index.."."..id,
					href = href.."#"..anchor,
					title = title,
				})
			end
		elseif item.alias ~= nil then
			for anchor, alias in pairs(item.alias) do
				addpage({
					index = index.."."..alias,
					href = href.."#"..anchor,
					title = alias,
				})
			end
		end
		addlinks(item)
	end
end

local Environment = Class{ __index = _G }
local function process(items)
	for _, item in ipairs(items) do
		if not item.href:match("^http://") and not item.href:match("#") then
			local environment = Environment{
				item = item,
				menu = function()
					return domenu(site.pages, item):concat()
				end,
				contents = function(field)
					return readcontents(item[field or "href"])
				end,
				href = function(path)
					return getpath(item.href, path)
				end,
				link = function(index, label)
					index = assert(map[index], item.href..": unknown page tag "..tostring(index))
					return string.format('<a href="%s">%s</a>',
					                     getpath(item.href, index.href),
					                     label or index.title or "")
				end,
			}
			local function dotag(code)
				code = code:gsub("^=", "return ")
				code = assert(load(code, item.href, nil, environment))
				return code() or ""
			end
			local page, replaces = site.template
			repeat
				page, replaces = page:gsub("<%%(.-)%%>", dotag)
			until replaces == 0
			local output = assert(io.open(outputdir.."/"..item.href, "w"))
			output:write(page)
			output:close()
		end
		process(item)
	end
end

addlinks(site.pages)
addlinks(site.refs)
process(site.pages)
