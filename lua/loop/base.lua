-- Project: LOOP - Lua Object-Oriented Programming
-- Release: 3.0 beta
-- Title  : Base Class Model
-- Author : Renato Maia <maia@inf.puc-rio.br>

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
	local new = class.__new
	if new == nil
		then return rawnew(class, ...)
		else return new(class, ...)
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

getclass = getmetatable

function isclass(class)
	return getclass(class) == ClassMeta
end

function isinstanceof(object, class)
	return getclass(object) == class
end

getmember = rawget

members = pairs

setmetatable(ClassMeta, {
	__index = {
		new = new,
		rawnew = rawnew,
		getmember = getmember,
		members = members,
	},
})
