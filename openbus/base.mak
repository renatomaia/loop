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

NO_LUALINK=YES
USE_NODEPEND=YES

ifeq ($(findstring $(TEC_SYSNAME), Win32 Win64), )
  PRELOAD_DIR= ${OBJROOT}/${TEC_UNAME}
else
  ifdef LIBNAME
    PRELOAD_DIR= ${OBJROOT}/${TEC_UNAME}
  else
    PRELOAD_DIR= ${OBJROOT}/${TEC_SYSNAME}
  endif
endif

INCLUDES+= . $(PRELOAD_DIR)
DEF_FILE= $(PRELOAD_DIR)/$(LIBNAME).def

ifdef USE_LUA51
  LOOPBIN= export LD_LIBRARY_PATH="${LUACOMPAT52_HOME}/lib/${TEC_UNAME}:${LD_LIBRARY_PATH}"; export DYLD_LIBRARY_PATH="${LUACOMPAT52_HOME}/lib/${TEC_UNAME}:${DYLD_LIBRARY_PATH}"; $(LUABIN) -e "package.path=[[${LUACOMPAT52_HOME}/?.lua;${LOOP_HOME}/lua/?.lua]]package.loaded.bit32={}" -lcompat52
else
  LOOPBIN= $(LUABIN) -e "package.path=[[${LOOP_HOME}/lua/?.lua]]"
endif
LUAPRELOADER= ${LOOP_HOME}/lua/preloader.lua

$(PRELOAD_DIR)/$(LIBNAME).c: $(LUAPRELOADER) $(LUASRC)
	$(LOOPBIN) $(LUAPRELOADER) $(LUAPRELOADFLAGS) \
	                           -m \
	                           -l "$(LUADIR)/?.lua" \
	                           -d $(PRELOAD_DIR) \
	                           -h $(LIBNAME).h \
	                           -o $(LIBNAME).c \
	                           -def $(LIBNAME).def \
	                           $(LUASRC)
