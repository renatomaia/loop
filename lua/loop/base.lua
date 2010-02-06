--------------------------------------------------------------------------------
-- Project: LOOP - Lua Object-Oriented Programming                            --
-- Title  : Base Class Model                                                  --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------

local _G = require "_G"
local pairs = _G.pairs
local rawget = _G.rawget
local setmetatable = _G.setmetatable
local getmetatable = _G.getmetatable

module "loop.base"

function rawnew(class, object)
	if object == nil then object = {} end
	return setmetatable(object, class)
end

function new(class, ...)
	if class.__init == nil
		then return rawnew(class, ...)
		else return class:__init(...)
	end
end

function initclass(class)
	if class == nil then class = {} end
	if class.__index == nil then class.__index = class end
	return class
end

local ClassMeta = { __call = new }
function class(class)
	return setmetatable(initclass(class), ClassMeta)
end

classof = getmetatable

function isclass(class)
	return classof(class) == ClassMeta
end

function instanceof(object, class)
	return classof(object) == class
end

memberof = rawget

members = pairs
