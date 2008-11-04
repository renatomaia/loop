local oo = require "loop.base"

local class = oo.class
local classof = oo.classof
local rawnew = oo.rawnew

module("loop.object.Dummy", class)

function nothing() end
function self(dummy) return dummy end
function binary(one, other)
	return (classof(one) == _M) and one or other
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
