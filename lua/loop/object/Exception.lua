-- Project: LOOP Class Library
-- Title  : Data Structure for Exception/Error Information
-- Author : Renato Maia <maia@inf.puc-rio.br>

local _G = require "_G"
local tostring = _G.tostring
local traceback = _G.debug and _G.debug.traceback -- only if available

local oo = require "loop.base"
local class = oo.class
local rawnew = oo.rawnew

local Exception = class()

if traceback ~= nil then
	function Exception:__new(object)
		if object == nil then
			object = { traceback = traceback() }
		elseif object.traceback == nil then
			object.traceback = traceback()
		end
		return rawnew(self, object)
	end
end

function Exception:__concat(other)
	return tostring(self)..tostring(other)
end

function Exception:__tostring()
	local result = self[1] or "Exception"
	local message = self.message
	if message ~= nil then
		result = result..": "..message:gsub(
			"(%$+)([_%a][_%w]*)",
			function(prefix, field)
				if #prefix%2 == 1 then
					prefix = prefix:sub(1, -2)
					field = tostring(self[field])
				end
				return prefix..field
			end
		)
	end
	local traceback = self.traceback
	if traceback ~= nil then
		result = result.."\n"..traceback
	end
	return result
end

return Exception
