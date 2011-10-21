PROJNAME= loop
LIBNAME= $(PROJNAME)

SRC= $(PRELOAD_DIR)/$(LIBNAME).c

LUADIR= ../lua
LUASRC= \
	$(LUADIR)/loop/base.lua \
	$(LUADIR)/loop/cached.lua \
	$(LUADIR)/loop/collection/ArrayedMap.lua \
	$(LUADIR)/loop/collection/ArrayedSet.lua \
	$(LUADIR)/loop/collection/BiCyclicSets.lua \
	$(LUADIR)/loop/collection/CyclicSets.lua \
	$(LUADIR)/loop/collection/OrderedSet.lua \
	$(LUADIR)/loop/collection/Queue.lua \
	$(LUADIR)/loop/collection/SortedMap.lua \
	$(LUADIR)/loop/collection/UnorderedArray.lua \
	$(LUADIR)/loop/compiler/Arguments.lua \
	$(LUADIR)/loop/compiler/Expression.lua \
	$(LUADIR)/loop/component/base.lua \
	$(LUADIR)/loop/component/contained.lua \
	$(LUADIR)/loop/component/dynamic.lua \
	$(LUADIR)/loop/component/intercepted.lua \
	$(LUADIR)/loop/component/wrapped.lua \
	$(LUADIR)/loop/debug/Crawler.lua \
	$(LUADIR)/loop/debug/Matcher.lua \
	$(LUADIR)/loop/debug/Verbose.lua \
	$(LUADIR)/loop/debug/Viewer.lua \
	$(LUADIR)/loop/hierarchy.lua \
	$(LUADIR)/loop/multiple.lua \
	$(LUADIR)/loop/object/Dummy.lua \
	$(LUADIR)/loop/object/Exception.lua \
	$(LUADIR)/loop/object/Publisher.lua \
	$(LUADIR)/loop/object/Wrapper.lua \
	$(LUADIR)/loop/proto.lua \
	$(LUADIR)/loop/scoped/debug.lua \
	$(LUADIR)/loop/scoped.lua \
	$(LUADIR)/loop/serial/FileStream.lua \
	$(LUADIR)/loop/serial/Serializer.lua \
	$(LUADIR)/loop/serial/Stream.lua \
	$(LUADIR)/loop/serial/StringStream.lua \
	$(LUADIR)/loop/simple.lua \
	$(LUADIR)/loop/table.lua \
	$(LUADIR)/loop.lua

include base.mak
