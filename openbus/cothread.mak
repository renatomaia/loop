PROJNAME= luacothread
LIBNAME= $(PROJNAME)

SRC= $(PRELOAD_DIR)/$(LIBNAME).c

LUADIR= ../lua
LUASRC= \
	$(LUADIR)/cothread/EventPoll.lua \
	$(LUADIR)/cothread/Mutex.lua \
	$(LUADIR)/cothread/plugin/signal.lua \
	$(LUADIR)/cothread/plugin/sleep.lua \
	$(LUADIR)/cothread/plugin/socket.lua \
	$(LUADIR)/cothread/Queue.lua \
	$(LUADIR)/cothread/socket.lua \
	$(LUADIR)/cothread/Timer.lua \
	$(LUADIR)/cothread.lua

include base.mak 
