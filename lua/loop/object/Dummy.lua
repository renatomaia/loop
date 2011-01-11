-- Project: LOOP Class Library
-- Title  : Dummy Object that Ignores all Events
-- Author : Renato Maia <maia@inf.puc-rio.br>

local _G = require "_G"
local getmetatable = _G.getmetatable
local newproxy = _G.newproxy

local oo = require "loop.base"
local class = oo.class

local prototype = newproxy(true)
local meta = getmetatable(prototype)
if loop.object == nil then
	loop.object = { Dummy = meta }
else
	loop.object.Dummy = meta
end
module("loop.object.Dummy", class)

function __new()
	return newproxy(prototype)
end

function none() end
function number() return 0 end
function string() return "" end

__concat   = string
__unm      = number
__add      = number
__sub      = number
__mul      = number
__div      = number
__mod      = number
__pow      = number
__call     = none
__eq       = none
__lt       = none
__le       = none
__newindex = none
__index    = function(self) return self end
__len      = number
__pairs    = function() return none end
__tostring = string
__metatable = prototype
