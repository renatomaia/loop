PROJNAME= luatuple
LIBNAME= $(PROJNAME)

SRC= $(PRELOAD_DIR)/$(LIBNAME).c

LUADIR= ../lua
LUASRC= \
	$(LUADIR)/tuple/weak.lua \
	$(LUADIR)/tuple.lua

include base.mak
