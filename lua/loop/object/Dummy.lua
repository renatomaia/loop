-- Project: LOOP Class Library
-- Title  : Dummy Object that Ignores all Events
-- Author : Renato Maia <maia@inf.puc-rio.br>

local oo = require "loop.base"
local class = oo.class
local getclass = oo.getclass

module(..., class)

function nothing() end
function self(dummy) return dummy end
function binary(one, other)
	if getclass(one) == _M
		then return one
		else return other
	end
end

__add      = binary
__sub      = binary
__mul      = binary
__div      = binary
__mod      = binary
__pow      = binary
__unm      = self
__concat   = binary
__eq       = nothing
__lt       = nothing
__le       = nothing
__index    = self
__newindex = nothing
__call     = self
__tostring = function() return _NAME end
