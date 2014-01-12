local allchars = {}
for i = 0, 255 do
	allchars[#allchars+1] = string.char(i)
end
local strings = {
	[table.concat(allchars)] = {
		double = [["\000\001\002\003\004\005\006\007\b\t\n\v\f\013\014\015\016\017\018\019\020\021\022\023\024\025\026\027\028\029\030\031 !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~\127\128\129\130\131\132\133\134\135\136\137\138\139\140\141\142\143\144\145\146\147\148\149\150\151\152\153\154\155\156\157\158\159\160\161\162\163\164\165\166\167\168\169\170\171\172\173\174\175\176\177\178\179\180\181\182\183\184\185\186\187\188\189\190\191\192\193\194\195\196\197\198\199\200\201\202\203\204\205\206\207\208\209\210\211\212\213\214\215\216\217\218\219\220\221\222\223\224\225\226\227\228\229\230\231\232\233\234\235\236\237\238\239\240\241\242\243\244\245\246\247\248\249\250\251\252\253\254\255"]],
		single = [['\000\001\002\003\004\005\006\007\b\t\n\v\f\013\014\015\016\017\018\019\020\021\022\023\024\025\026\027\028\029\030\031 !"#$%&\'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~\127\128\129\130\131\132\133\134\135\136\137\138\139\140\141\142\143\144\145\146\147\148\149\150\151\152\153\154\155\156\157\158\159\160\161\162\163\164\165\166\167\168\169\170\171\172\173\174\175\176\177\178\179\180\181\182\183\184\185\186\187\188\189\190\191\192\193\194\195\196\197\198\199\200\201\202\203\204\205\206\207\208\209\210\211\212\213\214\215\216\217\218\219\220\221\222\223\224\225\226\227\228\229\230\231\232\233\234\235\236\237\238\239\240\241\242\243\244\245\246\247\248\249\250\251\252\253\254\255']],
	},
	[" "] = {
		double = [[" "]],
		single = [[' ']],
	},
	[" John Doe "] = {
		double = [[" John Doe "]],
		single = [[' John Doe ']],
	},
	[""] = {
		double = [[""]],
		single = [['']],
	},
	["\b"] = {
		double = [["\b"]],
		single = [['\b']],
	},
	["\t"] = {
		double = [["\t"]],
		single = [['\t']],
	},
	["\n"] = {
		double = [["\n"]],
		single = [['\n']],
	},
	["\v"] = {
		double = [["\v"]],
		single = [['\v']],
	},
	['"'] = {
		double = [=["\""]=],
		single = [=['"']=],
		dbrack = [=[[["]]]=],
		d_pref = [=['"']=],
	},
	["'"] = {
		double = [=["'"]=],
		single = [=['\'']=],
		sbrack = [=[[[']]]=],
		s_pref = [=["'"]=],
	},
	['a \n\t'] = {
		double = [=["a \n\t"]=],
		single = [=['a \n\t']=],
		dbrack = [=[[[
a 
	]]]=],
		sbrack = [=[[[
a 
	]]]=],
	},
	["\tJohn\n\tDoe"] = {
		double = [=["\tJohn\n\tDoe"]=],
		single = [=['\tJohn\n\tDoe']=],
		dbrack = [=[[[
	John
	Doe]]]=],
		sbrack = [=[[[
	John
	Doe]]]=],
	},
	['"double quotes"'] = {
		double = [=["\"double quotes\""]=],
		single = [=['"double quotes"']=],
		dbrack = [=[[["double quotes"]]]=],
		d_pref = [=['"double quotes"']=],
	},
	["'single quotes'"] = {
		double = [=["'single quotes'"]=],
		single = [=['\'single quotes\'']=],
		sbrack = [=[[['single quotes']]]=],
		s_pref = [=["'single quotes'"]=],
	},
	["'both quotes\""] = {
		double = [=["'both quotes\""]=],
		single = [=['\'both quotes"']=],
		sbrack = [=[[['both quotes"]]]=],
		dbrack = [=[[['both quotes"]]]=],
	},
	["C:\\Program Files\\Lua"] = {
		double = [=["C:\\Program Files\\Lua"]=],
		single = [=['C:\\Program Files\\Lua']=],
		dbrack = [=[[[C:\Program Files\Lua]]]=],
		sbrack = [=[[[C:\Program Files\Lua]]]=],
	},
	["[[]]"] = {
		double = [==["[[]]"]==],
		single = [==['[[]]']==],
	},
	["[[\t"] = {
		double = [==["[[\t"]==],
		single = [==['[[\t']==],
		dbrack = [==[[=[[[	]=]]==],
		sbrack = [==[[=[[[	]=]]==],
	},
	["[=[\t"] = {
		double = [==["[=[\t"]==],
		single = [==['[=[\t']==],
		dbrack = [==[[[[=[	]]]==],
		sbrack = [==[[[[=[	]]]==],
	},
	["[[line1\nline2\nline3]]"] = {
		double = [==["[[line1\nline2\nline3]]"]==],
		single = [==['[[line1\nline2\nline3]]']==],
		dbrack = [==[[=[
[[line1
line2
line3]]]=]]==],
		sbrack = [==[[=[
[[line1
line2
line3]]]=]]==],
	},
	["']=]"] = {
		double = [===["']=]"]===],
		single = [===['\']=]']===],
		sbrack = [===[[==[']=]]==]]===],
		s_pref = [===["']=]"]===],
	},
	['"]=]'] = {
		double = [===["\"]=]"]===],
		single = [===['"]=]']===],
		dbrack = [===[[==["]=]]==]]===],
		d_pref = [===['"]=]']===],
	},
	["'\"]]"] = {
		double = [==["'\"]]"]==],
		single = [==['\'"]]']==],
		dbrack = [==[[=['"]]]=]]==],
		sbrack = [==[[=['"]]]=]]==],
	},
	["'\"]=]"] = {
		double = [===["'\"]=]"]===],
		single = [===['\'"]=]']===],
		dbrack = [===[[==['"]=]]==]]===],
		sbrack = [===[[==['"]=]]==]]===],
	},
	["'\"]==]"] = {
		double = [===["'\"]==]"]===],
		single = [===['\'"]==]']===],
		dbrack = [===[[=['"]==]]=]]===],
		sbrack = [===[[=['"]==]]=]]===],
	},
	["'\"]]]=]]==]"] = {
		double = [====["'\"]]]=]]==]"]====],
		single = [====['\'"]]]=]]==]']====],
		dbrack = [====[[===['"]]]=]]==]]===]]====],
		sbrack = [====[[===['"]]]=]]==]]===]]====],
	},
}

local function teststring(value, expected, viewer)
	local actual = viewer:tostring(value)
	assert(actual == expected, "'"..tostring(actual).."' was not '"..expected.."'")
	local builder = assert(load("return "..actual))
	assert(builder() == value)
end

local Viewer = require "loop.debug.Viewer"

return function()
	for value, cases in pairs(strings) do
		teststring(value, cases.d_pref or cases.dbrack or cases.double, Viewer())
		teststring(value, cases.s_pref or cases.sbrack or cases.single, Viewer{singlequotes=true})
		teststring(value, cases.d_pref or cases.double                , Viewer{nolongbrackets=true})
		teststring(value, cases.s_pref or cases.single                , Viewer{nolongbrackets=true,singlequotes=true})
	
		teststring(value, cases.dbrack or cases.double, Viewer{noaltquotes=true})
		teststring(value, cases.sbrack or cases.single, Viewer{noaltquotes=true,singlequotes=true})
		teststring(value, cases.double                , Viewer{noaltquotes=true,nolongbrackets=true})
		teststring(value, cases.single                , Viewer{noaltquotes=true,nolongbrackets=true,singlequotes=true})
	end
end