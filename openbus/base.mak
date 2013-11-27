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

INCLUDES= . $(PRELOAD_DIR)
DEF_FILE= $(PRELOAD_DIR)/$(LIBNAME).def

LOOPBIN= $(LUABIN) -e "package.path=[[${LOOP_HOME}/lua/?.lua]]"
LUAPRELOADER= ${LOOP_HOME}/lua/preloader.lua

$(PRELOAD_DIR)/$(LIBNAME).c: $(LUAPRELOADER) $(LUASRC)
	$(LOOPBIN) $(LUAPRELOADER) -m \
	                           -l "$(LUADIR)/?.lua" \
	                           -d $(PRELOAD_DIR) \
	                           -h $(LIBNAME).h \
	                           -o $(LIBNAME).c \
	                           -def $(LIBNAME).def \
	                           $(LUASRC)
