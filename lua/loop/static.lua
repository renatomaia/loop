--------------------------------------------------------------------------------
-- Project: LOOP - Lua Object-Oriented Programming                            --
-- Title  : Static Class Model without Support for Introspection              --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------

local _G = require "_G"
local getfenv = _G.getfenv
local setfenv = _G.setfenv
local setmetatable = _G.setmetatable
local type = _G.type

local module = {}

local BuilderOf = setmetatable({}, { __mode = "k" })

function module.class(builder)
	local function class(...)
		local object = {}
		setfenv(builder, object)
		local result = builder(...)
		if result ~= nil then
			setfenv(builder, result)
		end
		return getfenv(builder)
	end
	BuilderOf[class] = builder
	return class
end

function module.inherit(class, ...)
	local builder = BuilderOf[class]
	setfenv(builder, getfenv(2))
	return builder(...)
end

function module.become(object)
	if object ~= nil then
		setfenv(2, object)
	end
end

function module.self(level)
	return getfenv((level or 1) + 1)
end

function module.new(class, ...)
	return module.class(...)
end

return module
