-- Project: LOOP Class Library
-- Title  : Dummy Object that Ignores all Events
-- Author : Renato Maia <maia@inf.puc-rio.br>

local _G = require "_G"
local getmetatable = _G.getmetatable
local newproxy = _G.newproxy

local oo = require "loop.base"
local class = oo.class

local prototype = newproxy(true)
local Dummy = class(getmetatable(prototype))

function Dummy:__new()
	return newproxy(prototype)
end

local function none() end
local function number() return 0 end
local function string() return "" end

Dummy.string = string
Dummy.number = number
Dummy.none   = none

Dummy.__concat   = string
Dummy.__unm      = number
Dummy.__add      = number
Dummy.__sub      = number
Dummy.__mul      = number
Dummy.__div      = number
Dummy.__mod      = number
Dummy.__pow      = number
Dummy.__call     = none
Dummy.__eq       = none
Dummy.__lt       = none
Dummy.__le       = none
Dummy.__newindex = none
Dummy.__index    = function(self) return self end
Dummy.__len      = number
Dummy.__pairs    = function() return none end
Dummy.__tostring = string
Dummy.__metatable = prototype

return Dummy
