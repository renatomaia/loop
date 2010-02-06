--------------------------------------------------------------------------------
---------------------- ##       #####    #####   ######  -----------------------
---------------------- ##      ##   ##  ##   ##  ##   ## -----------------------
---------------------- ##      ##   ##  ##   ##  ######  -----------------------
---------------------- ##      ##   ##  ##   ##  ##      -----------------------
---------------------- ######   #####    #####   ##      -----------------------
----------------------                                   -----------------------
----------------------- Lua Object-Oriented Programming ------------------------
--------------------------------------------------------------------------------
-- Project: LOOP Class Library                                                --
-- Release: 2.3 beta                                                          --
-- Title  : Interchangeable Disjoint Cyclic Sets                              --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------

local global = require "_G"
local table  = require "loop.table"
local oo     = require "loop.base"

local next   = global.next
local rawget = global.rawget
local copy   = table.copy
local rawnew = oo.rawnew

module(..., oo.class)

-- [ ? ]     :contains(item) --> [ ? ]      : false
-- [ item ? ]:contains(item) --> [ item ? ] : true
function contains(self, item)
	return self[item] ~= nil
end

-- [ ? ]           :successor(item) --> [ ? ]            : nil 
-- [ item | ? ]    :successor(item) --> [ item | ? ]     : item
-- [ item, succ ? ]:successor(item) --> [ item, succ ? ] : succ
function successor(self, item)
	return self[item]
end

function forward(self, place)
	return self.successor, self, place
end

-- [ ? ]              :addto()            --> [ ? ]               : error "table index is nil"
-- [ ? ]              :addto(place)       --> [ ? ]               : error "table index is nil"
-- [ ? ]              :addto(nil, item)   --> [ item | ? ]        : item
-- [ item ? ]         :addto(nil, item)   --> [ item ? ]          :
-- [ ? ]              :addto(item, item)  --> [ item | ? ]        : item
-- [ item ? ]         :addto(item, item)  --> [ item ? ]          :
-- [ ? ]              :addto(place, item) --> [ place, item | ? ] : item
-- [ place ? ]        :addto(place, item) --> [ place, item ? ]   : item
-- [ item ? ]         :addto(place, item) --> [ item ? ]          :
-- [ place, item ? ]  :addto(place, item) --> [ place, item ? ]   :
-- [ place ? item ?? ]:addto(place, item) --> [ place ? item ?? ] :
function addto(self, place, item)
	if self[item] == nil then
		local succ
		if place == nil then
			place, succ = item, item
		else
			succ = self[place]
			if succ == nil then
				succ = place
			end
		end
		self[item]  = succ
		self[place] = item
		return item
	end
end

-- [ ? ]            :removefrom()      --> [ ? ]       :
-- [ ? ]            :removefrom(place) --> [ ? ]       :
-- [ place | ? ]    :removefrom(place) --> [ ? ]       : place
-- [ place, item ? ]:removefrom(place) --> [ place ? ] : item
function removefrom(self, place)
	local item = self[place]
	if item ~= nil then
		self[place] = self[item]
		self[item] = nil
		return item
	end
end

-- [ ? ]             :removeall()     --> [ ? ] :
-- [ ? ]             :removeall(item) --> [ ? ] :
-- [ item | ? ]      :removeall(item) --> [ ? ] : item
-- [ item..last | ? ]:removeall(item) --> [ ? ] : item
function removeall(self, item)
	local succ = self[item]
	if succ ~= nil then
		self[item] = nil
		while succ ~= item do
			succ, self[succ] = self[succ], nil
		end
		return item
	end
end

-- [ ? ]                              :movetofrom()               --> [ ? ]                          :
-- [ ? ]                              :movetofrom(nil, old, ...)  --> [ ? ]                          :
-- [ ? ]                              :movetofrom(new, old, ...)  --> [ ? ]                          :
-- [ new ? ]                          :movetofrom(new, old, ...)  --> [ new ? ]                      :
--
-- [ old | ? ]                        :movetofrom(nil, old)       --> [ old | ? ]                    : old
-- [ old | ? ]                        :movetofrom(new, old)       --> [ new, old | ? ]               : old
-- [ old | new ? ]                    :movetofrom(new, old)       --> [ new, old ? ]                 : old
-- [ old, new ? ]                     :movetofrom(new, old)       --> [ new | old ? ]                : new
-- [ old, new..last ? ]               :movetofrom(new, old, last) --> [ old, ? | new..last ]         : new
--
-- [ old, item ? ]                    :movetofrom(nil, old)       --> [ old ? | item ]               : item
-- [ old, item ? ]                    :movetofrom(new, old)       --> [ old ? | new, item ]          : item
-- [ old, item..new ? ]               :movetofrom(new, old)       --> [ old..new, item ? ]           : item
-- [ old, item ? | new ?? ]           :movetofrom(new, old)       --> [ old ? | new, item ?? ]       : item
--
-- [ old, item..last ? ]              :movetofrom(nil, old, last) --> [ old ? | item..last ]         : item
-- [ old, item..last ? ]              :movetofrom(new, old, last) --> [ old ? | new, item..last ]    : item
-- [ old, item..last...new ? ]        :movetofrom(new, old, last) --> [ old...new, item..last ? ]    : item
-- [ old, item..last ? | new ?? ]     :movetofrom(new, old, last) --> [ old ? | new, item..last ?? ] : item
--
-- [ old ? ]                          :movetofrom(new, old, last) --> CORRUPTED                      : ???
-- [ old..new ? ]                     :movetofrom(new, old, last) --> CORRUPTED                      : ???
-- [ old ? | new ?? ]                 :movetofrom(new, old, last) --> CORRUPTED                      : ???
--
-- [ old, item ? | last ?? ]          :movetofrom(nil, old, last) --> UNKNOWN STATE. MAYBE VALID?    : item
-- [ old, item ? | last ?? ]          :movetofrom(new, old, last) --> UNKNOWN STATE. MAYBE VALID?    : item
-- [ old, item..new ? | last ?? ]     :movetofrom(new, old, last) --> UNKNOWN STATE. MAYBE VALID?    : item
-- [ old, item ? | last..new ?? ]     :movetofrom(new, old, last) --> UNKNOWN STATE. MAYBE VALID?    : item
-- [ old, item ? | last ?? | new ??? ]:movetofrom(new, old, last) --> UNKNOWN STATE. MAYBE VALID?    : item
function movetofrom(self, newplace, oldplace, lastitem)
	local theitem = self[oldplace]
	if theitem ~= nil then
		if lastitem == nil then lastitem = theitem end
		local oldsucc = self[lastitem]
		local newsucc
		if newplace == nil or newplace == theitem then
			newplace, newsucc = lastitem, theitem
		else
			newsucc = self[newplace]
			if newsucc == nil then
				newsucc = newplace
			end
		end
		self[oldplace] = oldsucc
		self[lastitem] = newsucc
		self[newplace] = theitem
		return theitem
	end
end

function disjoint(self)
	local result = {}
	local missing = copy(self)
	local start = next(missing)
	while start ~= nil do
		result[#result+1] = start
		local item = start
		repeat
			missing[item] = nil
			item = self[item]
		until item == start
		start = next(missing)
	end
	return result
end

function __tostring(self, tostring, concat)
	tostring = tostring or global.tostring
	concat = concat or global.table.concat
	local result = {}
	local missing = copy(self)
	local start = next(missing)
	result[#result+1] = "[ "
	while start ~= nil do
		local item = start
		repeat
			result[#result+1] = tostring(item)
			result[#result+1] = ", "
			missing[item] = nil
			item = self[item]
		until item == start
		result[#result] = " | "
		start = next(missing)
	end
	local last = #result
	result[last] = (last == 1) and "[]" or " ]"
	return concat(result)
end
