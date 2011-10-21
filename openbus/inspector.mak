PROJNAME= luainspector
LIBNAME= $(PROJNAME)

SRC= $(PRELOAD_DIR)/$(LIBNAME).c

LUADIR= ../lua
LUASRC= $(LUADIR)/inspector.lua

include base.mak 
