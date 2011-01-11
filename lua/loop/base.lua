-- Project: LOOP - Lua Object-Oriented Programming
-- Release: 3.0 beta
-- Title  : Base Class Model
-- Author : Renato Maia <maia@inf.puc-rio.br>

local _G = require "_G"
local pairs = _G.pairs
local rawget = _G.rawget
local setmetatable = _G.setmetatable
local getmetatable = _G.getmetatable

local function rawnew(class, object)
	if object == nil then object = {} end
	return setmetatable(object, class)
end

local function new(class, ...)
	local new = class.__new
	if new == nil
		then return rawnew(class, ...)
		else return new(class, ...)
	end
end

local function initclass(class)
	if class == nil then class = {} end
	if class.__index == nil then class.__index = class end
	return class
end

local ClassMeta = setmetatable({ __call = new }, {
	__index = {
		new = new,
		rawnew = rawnew,
		getmember = rawget,
		members = pairs,
	},
})

return {
	initclass = initclass,
	getclass = getmetatable,
	getmember = rawget,
	members = pairs,
	new = new,
	rawnew = rawnew,
	
	class = function(class)
		return setmetatable(initclass(class), ClassMeta)
	end,
	isclass = function(class)
		return getmetatable(class) == ClassMeta
	end,
	isinstanceof = function(object, class)
		return getmetatable(object) == class
	end,
}
