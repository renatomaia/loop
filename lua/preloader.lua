#!/usr/bin/env lua
--------------------------------------------------------------------------------
-- @script  Lua Pre-Loader
-- @version 2.0
-- @author  Renato Maia <maia@tecgraf.puc-rio.br>

local _G = require "_G"
local arg = _G.arg
local assert = _G.assert
local error = _G.error
local ipairs = _G.ipairs
local loadfile = _G.loadfile or _G.load
local pairs = _G.pairs
local pcall = _G.pcall
local select = _G.select
local setfenv = _G.setfenv

local package = require "package"
local path = package.path

local array = require "table"
local insert = array.insert
local concat = array.concat
local unpack = array.unpack or _G.unpack

local string = require "string"
local byte = string.byte
local dump = string.dump
local find = string.find
local format = string.format
local imatch = string.gmatch
local replace = string.gsub
local match = string.match
local substring = string.sub
local upper = string.upper

local io = require "io"
local open = io.open
local stderr = io.stderr
local stdin = io.stdin

local os = require "os"
local exit = os.exit

local Arguments = require "loop.compiler.Arguments"

local _ENV = Arguments{
	bytecodes   = false,
	compileonly = false,
	directory   = "",
	funcload    = "",
	header      = "",
	include     = {},
	luapath     = path,
	modfuncs    = false,
	names       = false,
	output      = "preloaded.c",
	prefix      = "LUAOPEN_API",
	signatures  = false,
	warnings    = false,
}
pcall(setfenv, 2, _ENV) -- compatibility with Lua 5.1

-- parameter aliases
local alias = {
	I = "include",
	["-help"] = "help",
}
for name in pairs(_ENV) do alias[substring(name, 1, 1)] = name end
_ENV._alias = alias -- set parameter aliases
_ENV._optpat = "^%-(%-?%w+)(=?)(.-)$" -- set parameter pattern
_ENV.help = false -- declare aditional parameter 'help' without alias


local FILE_SEP = "/"
local FUNC_SEP = "_"
local PATH_SEP = ";"
local PATH_MARK = "?"
local OPEN_PAT = "int%s+luaopen_([%w_]+)%s*%(%s*lua_State%s*%*[%w_]*%)%s*;"


local start, errmsg = _ENV(...)
if not start or help then
	if errmsg then stderr:write("ERROR: ", errmsg, "\n") end
	stderr:write([[
Lua Pre-Loader 2.0  Copyright (C) 2006-2011 Tecgraf, PUC-Rio
Usage: ]],arg[0],[[ [options] [inputs]
  
  [inputs] is a sequence Lua script files, C header files of Lua libraries or
  even Lua package names. Use the options described below to indicate how the
  [inputs] should be interpreted. If no [inputs] are provided then such names
  are read from the standard input.
  
Options:
  
  -b, -bytecodes    Indicates the provided [inputs] define files containing
                    compiled bytecodes instead of source code, like the files
                    produces by the 'luac' compiler. When this flag is used no
                    compilation is performed by this script.
  
  -c, -compileonly  Disables the generation of a preloader function. This flag
                    implicitly forces the use of flag -modfuncs.
  
  -d, -directory    Defines the directory where the output files should be
                    generated. The default value is the current directory.
  
  -f, -funcload     Defines the name of the preloader function, a function
                    that pre-loads all modules in a Lua state. The default
                    value is 'luapreload_' plus the name defined by option
                    -output.
  
  -h, -header       Defines the name of the header file to be generated with
                    the signature of all generated functions (module functions
                    and the preloader function). If this option is not
                    provided, no header file is generated.
  
  -I, -i, -include  Adds a directory to the list of paths where the C header
                    files are searched.
  
  -l, -luapath      Defines a sequence of path templates used to infer package
                    names from script paths and vice versa. These templates
                    follow the same format of the 'package.path' field of Lua.
                    The default value is: "]],luapath,[[".
  
  -m, -modfuncs     Enables the generation of functions to load the compiled
                    script modules (luaopen_*). These functions follow the
                    format defined by the Lua package model. Thus they can be
                    exported by a dynamic library to load the compiled script
                    modules by the standard Lua runtime.
  
  -n, -names        Flag that indicates the provided input names are actually
                    package names and not paths to script files and C header
                    files. Each package name provided is applied to the path
                    defined by -luapath option to find the file containing the
                    implementation of the package. If no file can be found
                    then the package is assumed to be implemented by a C file
                    that must be linked with the generated file to produce the
                    final binary. This flag can be used in conjunction with
                    the -bytecodes flag to indicate that inferred file paths
                    contains bytecodes instead of source code.
  
  -o, -output       Defines the name of the output file with all generated
                    generated functions: module functions and the preloader
                    function. The default value is ']],output,[['.
  
  -p, -prefix       Defines the prefix added to the signature of the functions
                    generated. The default value is ']],prefix,[['.
  
  -s, -signatures   Disables the use of '#include' directives to include the C
                    header files of Lua libraries processed, generating
                    function signatures instead.
  
  -w, -warnings     Enables the generation of warning messages in the standard
                    error output.
]])
	exit(1)
end

--------------------------------------------------------------------------------

local function warn(...)
	if warnings then
		stderr:write("WARNING: ", ...)
		stderr:write("\n")
	end
end

local function escapepattern(pattern)
	return replace(pattern, "([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
end

local filesep  = escapepattern(FILE_SEP)
local funcsep  = escapepattern(FUNC_SEP)
local pathsep  = escapepattern(PATH_SEP)
local pathmark = escapepattern(PATH_MARK)

local function adjustpath(path)
	if path ~= "" and not find(path, filesep.."$") then
		return path..FILE_SEP
	end
	return path
end

local function readopcodes(path)
	local file = open(path, "rb")
	if file ~= nil then
		if bytecodes then
			local opcodes = file:read("*a")
			file:close()
			return opcodes
		else
			file:close()
			return dump(assert(loadfile(path)))
		end
	end
end

local function allequals(...)
	local name = ...
	for i = 2, select("#", ...) do
		if name ~= select(i, ...) then return nil end
	end
	return name
end

--------------------------------------------------------------------------------

if compileonly then
	modfuncs = true
	if #include > 0 then
		warn("ignoring include paths: ",unpack(include))
	end
	if funcload ~= "" then
		warn("ignoring 'funcload' parameter: ",funcload)
	end
elseif funcload == "" then
	funcload = "luapreload_"..match(output, "[_%a][_%w]*")
end

--------------------------------------------------------------------------------

local headers = {}
local cmodules = {}
local scripts = {}

local template = "[^"..pathsep.."]+"
local function processinput(input)
	if names then
		-- try to load opcodes from LUA_PATH
		local err = {}
		local file = replace(input, "%.", FILE_SEP)
		for pattern in imatch(luapath, template) do
			local path = replace(pattern, pathmark, file)
			local opcodes = readopcodes(path)
			if opcodes ~= nil then
				scripts[input] = opcodes
				return
			end
			insert(err, format("\tno file '%s'", path))
		end
		err = "module '"..input.."' not found:\n"..concat(err, "\n")
		if compileonly then
			error(err)
		else
			-- assume the name is a C module
			warn("assuming C module: Lua ",err)
			cmodules[input] = replace(input, "%.", FUNC_SEP)
		end
	else
		-- try to figure out the package name
		local module
		for path in imatch(luapath, template) do
			path = replace(path, pathmark, "\0")
			path = escapepattern(path)
			path = replace(path, "%z", "(.-)")
			path = "^"..path.."$"
			module = allequals(match(input, path)) or module
		end
		-- try to load opcodes from file path
		local err
		if module ~= nil then
			local opcodes = readopcodes(input)
			if opcodes ~= nil then
				scripts[replace(module, filesep, ".")] = opcodes
				return
			else
				err = "unable to read file '"..input.."'"
			end
		else
			err = "unable to figure out module name of file '"..input.."'"
		end
		if compileonly then
			error(err)
		end
		-- assume input is a C header file
		warn("assuming C header file: ",err) 
		-- try to read header file
		local file = open(input)
		if file == nil then
			for _, path in ipairs(include) do
				path = adjustpath(path)..input
				file = open(path)
				if file ~= nil then break end
			end
		end
		if file ~= nil then
			-- process header file
			local header = file:read("*a")
			file:close()
			module = nil
			for cname in imatch(header, OPEN_PAT) do
				module = replace(cname, funcsep, ".")
				cmodules[module] = cname
				if not signatures then
					headers[module] = input
				end
			end
			if module == nil then
				error("no 'luaopen_*' functions in header file '"..input.."'")
			end
		else
			-- raise error due to missing file
			error("unable to read file '"..input.."'")
		end
	end
end

--------------------------------------------------------------------------------

local inputs = { select(start, ...) }
if #inputs == 0 then
	for name in stdin:lines() do
		inputs[#inputs+1] = name
	end
end

for i, input in ipairs(inputs) do
	processinput(input)
end

--------------------------------------------------------------------------------

local outc = assert(open(adjustpath(directory)..output, "w"))
local outh = { write = function() end, close = function() end }

local guard = replace(upper(output), "[^%w]", "_")

outc:write([[
#include <lua.h>
#include <lauxlib.h>

]])

if header ~= "" then
	outh = assert(open(adjustpath(directory)..header, "w"))
	outc:write([[
#include "]],header,[["

]])
end

outh:write([[
#ifndef __]],guard,[[__
#define __]],guard,[[__

#include <lua.h>

#if defined(_WINDLL)

#if defined(LUA_MODULE_INTERNAL)
#define ]],prefix,[[ __declspec(dllexport)
#else
#define ]],prefix,[[ __declspec(dllimport)
#endif

#else

#ifndef ]],prefix,[[ 
#define ]],prefix,[[ 
#endif

#endif

]])

if not compileonly then
	for _, header in pairs(headers) do
		outc:write('#include "'..header..'"\n')
	end
	outc:write('\n')
	for module, cname in pairs(cmodules) do
		local header = headers[module]
		if header == nil then
			if modfuncs then
				outh:write(prefix,' int luaopen_',cname,'(lua_State*);\n')
			else
				outc:write('int luaopen_',cname,'(lua_State*);\n')
			end
		end
	end
	outc:write('\n')
end

if not compileonly or modfuncs then
	for module, opcodes in pairs(scripts) do
		local cname = replace(module, "%.", FUNC_SEP)
		outc:write('static const unsigned char opcodes_',cname,'[]={\n')
		for j = 1, #opcodes do
			outc:write(format("%3u,", byte(opcodes, j)))
			if j % 20 == 0 then outc:write("\n") end
		end
		outc:write('};\n\n')
		scripts[module] = cname
	end
end

if modfuncs then
	for module, cname in pairs(scripts) do
		outh:write(prefix,' int luaopen_',cname,'(lua_State*);\n')
		outc:write(prefix,[[ int luaopen_]],cname,[[(lua_State *L) {
	int arg = lua_gettop(L);
	if (luaL_loadbuffer(L,(const char*)opcodes_]],cname,[[,sizeof(opcodes_]],cname,[[),"]],module,[[")) lua_error(L);
	lua_insert(L,1);
	lua_call(L,arg,1);
	return 1;
}

]])
		-- treat scripts as C modules from now on
		cmodules[module], scripts[module] = cname, nil
	end
end

if not compileonly then
	outh:write(prefix,' int ',funcload,'(lua_State*);\n')
	outc:write(
prefix,[[ int ]],funcload,[[(lua_State *L) {
#if defined(LUA_VERSION_NUM) && LUA_VERSION_NUM > 501
	luaL_getsubtable(L, LUA_REGISTRYINDEX, "_PRELOAD");
#else
	luaL_findtable(L, LUA_GLOBALSINDEX, "package.preload", ]],#inputs,[[);
#endif
	
]])
	-- preload C modules
	for module, cname in pairs(cmodules) do
		outc:write([[
	lua_pushcfunction(L, luaopen_]],cname,[[);
	lua_setfield(L, -2, "]],module,[[");
]])
	end
	-- preload scripts
	for module, cname in pairs(scripts) do
		outc:write([[
	if (luaL_loadbuffer(L,(const char*)opcodes_]],cname,[[,sizeof(opcodes_]],cname,[[),"]],module,[[")) lua_error(L);
	lua_setfield(L, -2, "]],module,[[");
]])
	end
	outc:write([[
	
	lua_pop(L, 1);
	return 0;
}
]])
end

outh:write([[

#endif /* __]],guard,[[__ */
]])

outh:close()
outc:close()
