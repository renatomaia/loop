-- Project: LOOP Class Library
-- Title  : Data Structure for Exception/Error Information
-- Author : Renato Maia <maia@inf.puc-rio.br>

local _G = require "_G"
local tostring = _G.tostring

local oo = require "loop.base"
local class = oo.class

local Exception = class{ "Exception" }

function Exception:__concat(other)
	return tostring(self)..tostring(other)
end

function Exception:__tostring()
	return self[1]:gsub(
		"(%$+)([_%a][_%w]*)",
		function(prefix, field)
			local size = #prefix
			if size%2 == 1 then
				field = tostring(self[field])
			end
			return prefix:sub(1, size/2)..field
		end
	)
end

return Exception
