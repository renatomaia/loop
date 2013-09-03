--------------------------------------------------------------------------------
---------------------- ##       #####    #####   ######  -----------------------
---------------------- ##      ##   ##  ##   ##  ##   ## -----------------------
---------------------- ##      ##   ##  ##   ##  ######  -----------------------
---------------------- ##      ##   ##  ##   ##  ##      -----------------------
---------------------- ######   #####    #####   ##      -----------------------
----------------------                                   -----------------------
----------------------- Lua Object-Oriented Programming ------------------------
--------------------------------------------------------------------------------
-- Project: LOOP Class Library                                                --
-- Release: 2.3 beta                                                          --
-- Title  : Conditional Compiler for Code Generation                          --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------

local _G = require "_G"
local type       = _G.type
local assert     = _G.assert
local ipairs     = _G.ipairs

if _G._VERSION == "Lua 5.1" then
	local loadstring = _G.loadstring
	local setfenv = _G.setfenv
	local load51 = _G.load

	_G.load = function (ld, source, mode, env)
		local loadfunc = (type(ld)=="string") and loadstring or load51
		local chunk, errmsg = loadfunc(ld, source)
		if chunk == nil then
			return nil, errmsg
		else
			if env ~= nil then setfenv(chunk, env) end
			return chunk
		end
	end
end
local load = _G.load

local table = require "table"
local oo    = require "loop.base"

local module = oo.class()

function module.source(self, includes)
	local func = {}
	for line, strip in ipairs(self) do
		local cond = strip[2]
		if cond then
			cond = assert(load("return "..cond,
				"compiler condition "..line..":", nil, includes))
			cond = cond()
		else
			cond = true
		end
		if cond then
			assert(type(strip[1]) == "string",
				"code string is not a string")
			func[#func+1] = strip[1]
		end
	end
	return table.concat(func, "\n")
end

function module.execute(self, includes, ...)
	return assert(load(module.source(self, includes), self.name))(...)
end

return module