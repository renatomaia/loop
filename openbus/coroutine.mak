PROJNAME= luacoroutine
LIBNAME= $(PROJNAME)

SRC= $(PRELOAD_DIR)/$(LIBNAME).c

LUADIR= ../lua
LUASRC= \
	$(LUADIR)/coroutine/debug.lua \
	$(LUADIR)/coroutine/replace.lua \
	$(LUADIR)/coroutine/symetric.lua

include base.mak 
