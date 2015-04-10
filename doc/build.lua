local viewer = require("loop.debug.Viewer"){
  linebreak = false,
  noindices = true,
  nolabels = true,
  metaonly = true,
}
local ok, http = pcall(require, "socket.http")
if not ok then http = nil end

local Class = {}
function Class:__call(obj)
	return setmetatable(obj or {}, self)
end
Class:__call(Class)

local Environment = Class{ __index = _G }

local LinkPat = "^https?://"

--------------------------------------------------------------------------------

local function getpath(base, path)
	if path:match(LinkPat) then return path end
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
		if path:match(LinkPat) then
			if http then
				local code
				contents, code = http.request(path)
				if code ~= 200 then
					contents = nil
				end
			end
		else
			local file = assert(io.open(path))
			contents = assert(file:read("*a"))
			file:close()
		end
	end
	return contents
end

--------------------------------------------------------------------------------

local site = {}
assert(loadfile((...), nil, site))()

local outputdir = site.outputdir or "."
if select("#", ...) > 1 then
	outputdir = select(2, ...)
end

local map = {}
local AnchorPattern = '<%s*a%s+name%s*=%s*"([^"]+)"%s*>(.-)<%s*/%s*a%s*>'

local function getid(scope, name, desc)
	if not scope:match("^_") then
		local sep = (desc.type == "method") and ":" or "."
		return scope..sep..name
	end
	return name
end

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
		local environment = Environment{
			item = item,
			menu = function() return "" end,
			href = function() return "" end,
			link = function() return "" end,
			contents = function() return "" end,
			refman = function(refdesc)
				for name, ref in pairs(refdesc) do
					addpage({
						index = item.index.."."..name,
						href = item.href.."#"..name,
						title = ref.summary,
					})
					for field, desc in pairs(ref.fields) do
						local id = getid(name, field, desc)
						addpage({
							index = item.index.."."..id,
							href = item.href.."#"..id,
							title = "<code>"..id.."</code>",
						})
					end
				end
				return ""
			end,
		}
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
			for code in contents:gmatch("<%%(.-)%%>") do
				assert(load(code:gsub("^=", "return "), item.href, nil, environment))()
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

--------------------------------------------------------------------------------

local domenu do
	local Table = Class{ __index = table }
	local tab = "\t"
	local ident = 0
	function domenu(map, selected, output)
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
					output:insert('<a href="'..path..'", title="'..(item.title or item.index)..'">'
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
end

--------------------------------------------------------------------------------

local dorefman do
	local sorted do
		local function iterator(next, last)
			local key = next[last]
			return key, next.map[key]
		end
		function sorted(map, comp)
			local keys = {}
			for key in pairs(map) do
				if type(key) == "string" then
					keys[#keys+1] = key
				end
			end
			table.sort(keys, comp)
			local next = {map=map}
			local last = next
			for _, key in ipairs(keys) do
				next[last] = key
				last = key
			end
			return iterator, next, next
		end
	end

	local function out(output, text, ...)
		local ident = ""
		local inc = ...
		if select("#", ...) == 0 then inc = 0 end
		if inc ~= nil then
			if inc < 0 then output.level = output.level+inc end
			ident = string.rep("\t", output.level)
			if inc > 0 then output.level = output.level+inc end
		end
		output[#output+1] = ident
		output[#output+1] = text:gsub("\n", "\n"..ident)
		output[#output+1] = "\n"
	end

	local function descparams(manual, list)
		local result = ""
		if list ~= nil then
			local count = #list
			for i = count, 1, -1 do
				local param = list[i]
				local name = param.name
				local paramtype = param.type
				if manual[paramtype] ~= nil then
					name = '<a href="#'..paramtype..'">'..name..'</a>'
				end
				result = name..result
				if i > 1 then
					result = ", "..result
				end
				if param.eventual or param.default ~= nil then
					result = "["..result.."]"
					if i > 1 then
						result = " "..result
					end
				end
			end
		end
		return result
	end

	local function removeExtraTabs(text)
		local extra = text:match("^\t+")
		if extra ~= nil then
			text = text:gsub("\n"..extra, "\n")
			           :gsub("^"..extra, "")
			           :gsub("%s+$", "")
		end
		return text
	end

	local function writetext(item, contents, ...)
		local texts = {}
		for index = 1, select("#", ...) do
			local text = select(index, ...)
			if text ~= nil then
				text = text:gsub("<#([^>]+)>", function (tag, label)
					index = assert(map[item.index.."."..tag], item.href..": unknown local tag "..tostring(tag))
					return string.format('<a href="#%s">%s</a>', tag, label or index.title or index.index)
				end)
				texts[#texts+1] = removeExtraTabs(text)
					:gsub("\n\n", "</p>\n<p>")
			end
		end
		out(contents, "<p>"..table.concat(texts, " ").."</p>")
	end

	local function getDescOf(manual, desc)
		local description = desc.description or desc.summary or ""
		local typename = desc.type
		if type(typename) == "string" then
			local typedesc = manual[typename]
			if typedesc ~= nil then
				typename = '<a href="#'..typename..'">'..typedesc.summary..'</a>'
			end
			if description ~= "" then
				description = " that "..description
			end
			description = "is a "..typename..description
		end
		local default = desc.default
		if default ~= nil then
			description = description.."\nThe default value is <code>"..viewer:tostring(default).."</code>."
		end
		local missingdesc = desc.eventual
		if missingdesc ~= nil then
			description = description.."\nWhen absent "..missingdesc.."."
		end
		return description
	end

	TitleOf = {
		parameters = "Parameter",
		results = "Returned value",
	}

	function dorefman(currentpage, Reference)
		local index = {level=0}
		local contents = {level=0}
		out(index, '<table>', 1)
		for name, ref in sorted(Reference) do
			out(contents, '<h2><a name="'..name..'">'..(ref.summary or name)..'</a></h2>')
			writetext(currentpage, contents, ref.description)
			out(contents, '<dl>', 1)
			for field, desc in sorted(ref.fields) do
				local id = getid(name, field, desc)

				out(index, '<tr>', 1)
				out(index, '<td><a href="#'..id..'"><code>'..id..'</code></a></td>')
				out(index, '<td>'..(desc.summary or "")..'</td>')
				out(index, '</tr>', -1)

				local signature
				local fieldtype = desc.type
				if Reference[fieldtype] ~= nil then
					signature = '<a name="'..id..'" href="#'..fieldtype..'">'..id..'</a>'
				else
					signature = '<a name="'..id..'">'..id..'</a>'
					if fieldtype == "method" or fieldtype == "function" then
						signature = signature..'('..descparams(Reference, desc.parameters)..')'
						local results = descparams(Reference, desc.results)
						if results ~= "" then
							signature = results.." = "..signature
						end
					end
				end
				out(contents, '<dt><code>'..signature..'</code></dt>')
				out(contents, '<dd>', 1)
				writetext(currentpage, contents, getDescOf(Reference, desc))
				if fieldtype == "method" or fieldtype == "function" then
					for _, listname in ipairs{"parameters","results"} do
						local title = TitleOf[listname]
						local list = desc[listname]
						if list ~= nil then
							for _, itemdesc in ipairs(list) do
								writetext(currentpage, contents, title.." <code>"..itemdesc.name.."</code> "..getDescOf(Reference, itemdesc))
							end
						end
					end
				end
				local examples = desc.examples
				if examples ~= nil then
					out(contents, '<p>Example:</p>')
					for _, example in ipairs(examples) do
						out(contents, '<pre>'..example..'</pre>', nil)
					end
				end
				out(contents, '</dd>', -1)
			end
			out(contents, '</dl>', -1)
			out(index, '<tr><td><br></td></tr>')
		end
		out(index, '</table><br>', -1)

		return index, contents
	end
end

--------------------------------------------------------------------------------

local function process(items)
	for _, item in ipairs(items) do
		if not item.href:match(LinkPat) and not item.href:match("#") then
			local environment = Environment{
				item = item,
				menu = function()
					return domenu(site.pages, item):concat()
				end,
				refman = function(...)
					local index, contents = dorefman(item, ...)
					return table.concat(index).."\n"..table.concat(contents)
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
					                     label or index.title or index.index)
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
