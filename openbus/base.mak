ifeq "$(TEC_SYSNAME)" "SunOS"
  USE_CC=Yes
  NO_LOCAL_LD=Yes
  AR=CC
  CFLAGS+= -KPIC
  STDLFLAGS= -xar
  CPPFLAGS= +p -KPIC -mt -D_REENTRANT
  ifeq ($(TEC_WORDSIZE), TEC_64)
    FLAGS+= -m64
    LFLAGS+= -m64
    STDLFLAGS+= -m64
  endif
  STDLFLAGS+= -o
endif

USE_LUA51= YES
NO_LUALINK=YES
USE_NODEPEND=YES

PRELOAD_DIR= ../obj/${TEC_UNAME}
INCLUDES= . $(PRELOAD_DIR)

LOOPBIN= export LD_LIBRARY_PATH="${LUACOMPAT52_HOME}/lib/${TEC_UNAME}:${LD_LIBRARY_PATH}"; export DYLD_LIBRARY_PATH="${LUACOMPAT52_HOME}/lib/${TEC_UNAME}:${DYLD_LIBRARY_PATH}"; $(LUABIN) -e "package.path=[[${LUACOMPAT52_HOME}/?.lua;${LOOP_HOME}/lua/?.lua]]package.cpath=[[${LUACOMPAT52_HOME}/lib/${TEC_UNAME}/liblua?.so]]" -lcompat52
LUAPRELOADER= ${LOOP_HOME}/lua/preloader.lua

$(PRELOAD_DIR)/$(LIBNAME).c: $(LUAPRELOADER) $(LUASRC)
	$(LOOPBIN) $(LUAPRELOADER) -m \
	                           -l "$(LUADIR)/?.lua" \
	                           -d $(PRELOAD_DIR) \
	                           -h $(LIBNAME).h \
	                           -o $(LIBNAME).c \
	                           $(LUASRC)
