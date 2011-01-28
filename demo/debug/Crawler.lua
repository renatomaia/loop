local tabop = require "loop.table"
local Crawler = require "loop.debug.Crawler"

do -- count values by type
	local count = tabop.memoize(function() return 0 end)
	local crawler = Crawler()
	function crawler:foundvalue(value, visited)
		if value == nil then
			count["nil"] = 1
		elseif not visited then
			local t = type(value)
			count[t] = count[t]+1
		end
	end
	crawler:crawl()
	table.foreach(count, print)
end

print()

do -- find all references to a value
	local subject = Crawler
	local crawler = Crawler()
	function crawler:foundvalue(value, visited, from, kind, ...)
		if value == subject then
			io.write(tostring(value), " is a ", kind)
			io.write(" of ", tostring(from or "a root"))
			if select("#", ...) > 0 then
				io.write(" (", table.concat({...}, ","), ")")
			end
			print()
		end
	end
	crawler:crawl()
end

print()

do -- shortest path to a object
	local function shortestpath(...)
		local roots = tabop.memoize(function() return {} end)
		local to_from = tabop.memoize(function()
			return tabop.memoize(function()
				return {}
			end)
		end)
		local crawler = Crawler{
			visited = {
				[to_from] = true,
				[roots] = true,
			},
		}
		function crawler:foundvalue(to, visited, from, label, ...)
			local desc
			if label == "environment" then
				desc = "@env"
			elseif label == "metatable" then
				desc = "@meta"
			elseif label == "upvalue" then
				local name, index = ...
				desc = "@upval("..name..","..index..")"
			elseif label == "local" then
				local name, index = ...
				desc = "@local("..name..","..index..")"
			elseif label == "callfunc" then
				local info, level = ...
				desc = "@stackfunc("..(info.name or info.namewhat or "?")..","..level..")"
			elseif label == "key" then
				local entry = ...
				desc = "[]"
			elseif label == "entry" then
				local key = ...
				if type(key) ~= "string" then
					desc = string.format("[%s]", tostring(key))
				elseif key:match("^[%a_][%w_]*$") then
					desc = string.format(".%s", key)
				else
					desc = string.format("[%q]", key)
				end
			else
				desc = "@"..label
			end
			if to ~= nil then
				if from ~= nil then
					to_from[to][from][desc] = label
				else
					roots[to][desc] = label
				end
			end
		end
		
		crawler:crawl()
		
		local weight = {
			entry = 1,
			key = 2,
			environment = 3,
			metatable = 4,
			upvalue = 5,
			["local"] = 6,
			callfunc = 7,
			upname = 8,
			locname = 8,
			callfuncname = 8,
			callfuncnamewhat = 8,
			callfuncsource = 8,
			callfuncsrc = 8,
			callfuncwhat = 8,
		}
		function showpathsto(value)
			-- input
			local neighborsof = to_from
			local dest = tabop.copy(roots)
			-- output
			local nearest = {}
			local linklabel = {}
			-- internal
			local distof = { [value] = {weight=0,length=0} }
			local unvisitedat = tabop.memoize(function() return {} end)
			unvisitedat[0][value] = true
		
			while next(dest) ~= nil do
				-- get node with shortest path at 'unvisitedat'
				local node
				for dist = 0, table.maxn(unvisitedat) do
					local list = unvisitedat[dist]
					node = next(list)
					if node ~= nil then
						list[node] = nil -- remove it from the 'unvisitedat'
						dest[node] = nil
						break
					end
				end
			
				if node == nil then break end
				for neighbor, links in pairs(neighborsof[node]) do
					local minweight = math.huge
					local minlength
					local label
					for desc, kind in pairs(links) do
						local linkweight = weight[kind]
						if linkweight < minweight
						or (linkweight == minweight and #desc < minlength)
						then
							minweight = linkweight
							minlength = #desc
							label = desc
						end
					end
				
					local dist = distof[node]
					local newweight = dist.weight + minweight
					local newlength = dist.length + minlength
					dist = distof[neighbor]
					if dist == nil
					or newweight < dist.weight
					or (newweight == dist.weight and newlength < dist.length)
					then
						linklabel[neighbor] = label
						nearest[neighbor] = node
						distof[neighbor] = {weight=newweight,length=newlength}
						if dist ~= nil then
							unvisitedat[dist.weight][neighbor] = nil
						end
						unvisitedat[newweight][neighbor] = true
					end
				end
			end
			
			local found
			for root, labels in pairs(roots) do
				local node = nearest[root]
				if root == value or node ~= nil then
					io.write((next(labels)))
					local label = linklabel[root]
					while label ~= nil do
						io.write(label)
						label = linklabel[node]
						node = nearest[node]
					end
					print()
					found = true
				end
			end
			return found
		end
		
		for i = 1, select("#", ...) do
			if not showpathsto(select(i, ...)) then return false end
			print()
		end
		return true
	end
	
	shortestpath(_G)
end
