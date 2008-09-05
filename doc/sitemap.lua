outputdir = "website",

{ index="Home"   , href="index.html", board="latests.html" },
{                  href="news.html" , title="News" },
{ index="Install"   , href="release/index.html"   , title="Installation",
	{ index="Changes" , href="release/changes.html" , title="Release Notes" },
	{ index="Previous", href="release/previous.html", title="Previous Releases" },
	{ index="Preload" , href="release/preload.html" , title="Pre-Loading Script Libraries" },
},
{ index="Manual"   , href="manual/index.html"     , title="User Manual",
	{ index="Intro"  , href="manual/intro.html"     , title="Introduction" },
	{ index="Basics" , href="manual/basics.html"    , title="Basic Concepts" },
	{ index="Models" , href="manual/models.html"    , title="Class Models" },
	{ index="Classes", href="manual/classops.html"  , title="Class Features" },
	{ index="Comps"  , href="manual/components.html", title="Component Models" },
},
{ index="Library", href="library/index.html"    , title="Class Library",
	{                href="library/overview.html" , title="Overview" },
	{ index="collection", href="library/overview.html#collection", title="Collections",
		{                   href="library/collection/ObjectCache.html"        , title="Object Cache" },
		{                   href="library/collection/UnorderedArray.html"     , title="Unordered Array" },
		{                   href="library/collection/UnorderedArraySet.html"  , title="Unordered Array Set" },
		{                   href="library/collection/MapWithArrayOfKeys.html" , title="Map with Array of Keys" },
		{                   href="library/collection/OrderedSet.html"         , title="Ordered Set" },
		{                   href="library/collection/PriorityQueue.html"      , title="Priority Queue" },
	},
	{ index="compiler", href="library/overview.html#compiler"    , title="Compiling",
		{                 href="library/compiler/Arguments.html"   , title="Argument Processor" },
		{                 href="library/compiler/Conditional.html" , title="Conditional Compiler" },
		{                 href="library/compiler/Expression.html"  , title="Expression Parser" },
	},
	{ index="debug", href="library/overview.html#debug" , title="Debugging",
		{              href="library/debug/Viewer.html"   , title="Value Viewer" },
		{              href="library/debug/Matcher.html"  , title="Value Matcher" },
		{              href="library/debug/Inspector.html", title="Code Inspector" },
		{              href="library/debug/Verbose.html"  , title="Verbose Manager" },
	},
	{ index="object", href="library/overview.html#object" , title="Objects",
		{               href="library/object/Exception.html", title="Exception Object" },
		{               href="library/object/Wrapper.html"  , title="Object Wrapper" },
		{               href="library/object/Publisher.html", title="Event Publisher" },
	},
	{ index="serial", href="library/overview.html#serial"    , title="Serialization",
		{               href="library/serial/Serializer.html"  , title="Value Serializer" },
		{               href="library/serial/StringStream.html", title="String Stream" },
		{               href="library/serial/FileStream.html"  , title="File Stream" },
		{               href="library/serial/SocketStream.html", title="Socket Stream" },
	},
	--{ index="test", href="library/overview.html#test", title="Testing",
	--	{             href="library/test/Fixture.html" , title="Test Fixture" },
	--	{             href="library/test/Reporter.html", title="Result Reporter" },
	--	{             href="library/test/Results.html" , title="Result Collector" },
	--	{             href="library/test/Suite.html"   , title="Test Suite" },
	--},
	{ index="thread", href="library/overview.html#thread"       , title="Threading",
		{               href="library/thread/Scheduler.html"      , title="Thread Scheduler" },
		{               href="library/thread/IOScheduler.html"    , title="Thread Scheduler with I/O" },
		{               href="library/thread/CoSocket.html"       , title="Cooperative Sockets" },
		{               href="library/thread/SocketScheduler.html", title="Thread Scheduler with Sockets" },
		{               href="library/thread/Timer.html"          , title="Event Timer" },
	},
},
{ index="Contact" , href="contact.html" , title="Contact People" },
{ index="LuaForge", href="http://luaforge.net/projects/loop/", title="Project at LuaForge" },

[==============================================================================[
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

<div id="Header">Class Models for Lua</div>
<div id="Logo"><img alt="small (1K)" src="<%=href("small.gif")%>" height="70"></div>

<div id="Menu">
<%=menu()%>
</div>

<div class="content">
<% if item.title then return "<h1>"..item.title.."</h1>" end %>
<%
local package, class = item.href:match("^library/(%w+)/(%w+).html$")
if package then
	return string.format("<h2><code>loop.%s.%s</code></h2><br>", package, class)
end
%>
<%=contents()%>
</div>

<div class="content">
<p><small><strong>Copyright (C) 2004-2008 Tecgraf, PUC-Rio</strong></small></p>
<small>This project is currently being maintained by <a href="http://www.tecgraf.puc-rio.br">Tecgraf</a> at <a href="http://www.puc-rio.br">PUC-Rio</a>.</small>
</div>

<%
if item.board then
	return '<div id="Board">\n'..contents("board")..'</div>\n'
end
%>

</body>

</html>
]==============================================================================]
