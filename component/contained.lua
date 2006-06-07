-------------------------------------------------------------------------------
---------------------- ##       #####    #####   ######  ----------------------
---------------------- ##      ##   ##  ##   ##  ##   ## ----------------------
---------------------- ##      ##   ##  ##   ##  ######  ----------------------
---------------------- ##      ##   ##  ##   ##  ##      ----------------------
---------------------- ######   #####    #####   ##      ----------------------
----------------------                                   ----------------------
----------------------- Lua Object-Oriented Programming -----------------------
-------------------------------------------------------------------------------
-- Title  : LOOP - Lua Object-Oriented Programming                           --
-- Name   : Component Model with Interception                                --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                --
-- Version: 3.0 work1                                                        --
-- Date   : 22/2/2006 16:18                                                  --
-------------------------------------------------------------------------------
-- Exported API:                                                             --
--   Type                                                                    --
-------------------------------------------------------------------------------

local oo          = require "loop.cached"
local base        = require "loop.component.wrapped"
local OrderedSet  = require "loop.collection.OrderedSet"

module("loop.component.contained", package.seeall)

--------------------------------------------------------------------------------

BaseType = oo.class({}, base.BaseType)

function BaseType:__new(...)
	local comp = self[1](...)
	local state = {
		__component = comp,
		__home = self,
	}
	for port, class in pairs(self) do
		if port ~= 1 then
			state[port] = class(comp[port], comp)
		end
	end
	return state
end

function Type(type, ...)
	if select("#", ...) > 0
		then return oo.class(type, ...)
		else return oo.class(type, BaseType)
	end
end

--------------------------------------------------------------------------------

iports = base.iports