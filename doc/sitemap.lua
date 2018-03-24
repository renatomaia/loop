pages = {
	{ index="Home"      , href="index.html"           , board="latests.html" },
	{                     href="news.html"            , title="News" },
	{ index="Download"  , href="release/index.html",
		{ index="Previous", href="release/previous.html", title="Previous Releases" },
	},
	{ index="Manual"    , href="manual/index.html"    , title="User Manual",
		{ index="Intro"   , href="manual/intro.html"    , title="Introduction" },
		{ index="Basics"  , href="manual/basics.html"   , title="Basic Concepts" },
		{ index="Classes" , href="manual/classops.html" , title="Class Features" },
		{ index="Modules" , href="manual/models.html"   , title="Module Reference" },
		{ index="Changes" , href="manual/changes.html"  , title="Release Notes" },
	},
	{ index="Contact"   , href="contact.html"         , title="Contact People" },
}

refs = {
	{ index="maia"              , href="https://github.com/renatomaia"                      , title="Renato Maia"                 },
	{ index="Tecgraf"           , href="http://www.tecgraf.puc-rio.br"                      , },
	{ index="PUC-Rio"           , href="http://www.puc-rio.br"                              , },
	{ index="MitLicense"        , href="http://www.opensource.org/licenses/mit-license.html", title="MIT License" },
	{ index="LuaLicense"        , href="http://www.lua.org/license.html"                    , title="Lua License" },
	{ index="LuaSite"           , href="http://www.lua.org/"                                , title="Lua" },
	{ index="PiLBook"           , href="http://www.lua.org/pil"                             , title="Programming in Lua"          },
	{ index="PiL1stEd"          , href="http://www.lua.org/pil/contents.html"               , title="Programming in Lua (1st ed.)",
		{ index="PiL1stEd.Memoize", href="http://www.lua.org/pil/17.1.html"                   , title="Memoize Functions"           },
	},
	{ index="LuaManual"         , href="http://www.lua.org/manual/5.2/manual.html"          , title="Lua Manual",
		alias = {
			["2.4"] = "Metatables",
			["2.5.2"] = "WeakTables",
			["6"] = "StdLibs",
			["6.5"] = "TableLib",
			["6.10"] = "DebugLib",
			["pdf-package.path"] = "LuaPath",
		},
	},
	{ index="LuaWiki"           , href="http://lua-users.org/wiki"                          , title="Lua Wiki"                    ,
		{ index="LuaWiki.OOP"     , href="http://lua-users.org/wiki/ObjectOrientedProgramming", title="Object Oriented Programming" },
	},
	{ index="LuaRocks"          , href="http://www.luarocks.org/"                                        , title="LuaRocks" },
	{ index="LuaPreloader"      , href="https://github.com/renatomaia/luapreloader"                      , title="Lua Preloader" },
	{ index="OiL"               , href="https://github.com/renatomaia/oil"                               , },
	{ index="LOOP"              , href="https://renatomaia.github.io/loop"                               ,
		{ index="LOOP.Collections", href="https://github.com/renatomaia/loop-collections"                  , title="LOOP Collections" },
		{ index="LOOP.Debugging"  , href="https://github.com/renatomaia/loop-debugging"                    , title="LOOP Debugging" },
		{ index="LOOP.Objects"    , href="https://github.com/renatomaia/loop-objects"                      , title="LOOP Objects" },
		{ index="LOOP.Parsing"    , href="https://github.com/renatomaia/loop-parsing"                      , title="LOOP Parsing" },
		{ index="LOOP.Serializing", href="https://github.com/renatomaia/loop-serializing"                  , title="LOOP Serializing" },
		{ index="LOOP.Component"  , href="https://github.com/renatomaia/loop-compdev"                      , title="LOOP Component Models" },
		{ index="LOOP.v23"        , href="https://github.com/renatomaia/loop/releases/tag/LOOP_2_3_beta"   , title="LOOP 2.3" },
		{ index="LOOP.v22"        , href="https://github.com/renatomaia/loop/releases/tag/loop-2.2-alpha"  , title="LOOP 2.2" },
		{ index="LOOP.v21"        , href="https://github.com/renatomaia/loop/releases/tag/loop-2.1-alpha"  , title="LOOP 2.1" },
		{ index="LOOP.v3.tgz"     , href="https://github.com/renatomaia/loop/archive/v3.0.tar.gz"          , title="LOOP 3.0 (tar.gz)" },
		{ index="LOOP.v3.zip"     , href="https://github.com/renatomaia/loop/archive/v3.0.zip"             , title="LOOP 3.0 (zip)" },
		{ index="LOOP.v23.tgz"    , href="https://github.com/renatomaia/loop/archive/LOOP_2_3_beta.tar.gz" , title="LOOP 2.3 (tar.gz)" },
		{ index="LOOP.v23.zip"    , href="https://github.com/renatomaia/loop/archive/LOOP_2_3_beta.zip"    , title="LOOP 2.3 (zip)" },
		{ index="LOOP.v22.tgz"    , href="https://github.com/renatomaia/loop/archive/loop-2.2-alpha.tar.gz", title="LOOP 2.2 (tar.gz)" },
		{ index="LOOP.v22.zip"    , href="https://github.com/renatomaia/loop/archive/loop-2.2-alpha.zip"   , title="LOOP 2.2 (zip)" },
		{ index="LOOP.v21.tgz"    , href="https://github.com/renatomaia/loop/archive/loop-2.1-alpha.tar.gz", title="LOOP 2.1 (tar.gz)" },
		{ index="LOOP.v21.zip"    , href="https://github.com/renatomaia/loop/archive/loop-2.1-alpha.zip"   , title="LOOP 2.1 (zip)" },
	},
}

template = [===================================================================[
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">

<head>
	<meta http-equiv="content-type" content="text/html; charset=iso-8859-1" />
	<title>LOOP: <%=item.title or "Lua Object-Oriented Programming"%></title>
	<style type="text/css" media="all"><!--
		@import "<%=href("loop.css")%>";
		@import "<%=href("layout"..(item.board and 3 or 1)..".css")%>";
	--></style>
</head>

<body>

<div id="Header">Object-Oriented Programming Support for Lua</div>
<div id="Logo"><img alt="small (1K)" src="<%=href("small.gif")%>" height="70"></div>

<div id="Menu">
<%=menu()%>
</div>

<div class="content">
<% if item.title then return "<h1>"..item.title.."</h1>" end %>
<%=contents()%>
</div>

<div class="content">
<p><small><strong>Copyright (C) 2004-2018 <%=link("maia")%></strong></small></p>
<small>This project was originally developed in <%=link("Tecgraf")%> at <%=link("PUC-Rio")%>.</small>
</div>

<%
if item.board then
	return '<div id="Board">\n'..contents("board")..'</div>\n'
end
%>

</body>

</html>    ]===================================================================]
