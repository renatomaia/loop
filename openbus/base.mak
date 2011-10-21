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

LOOPBIN= $(LUABIN) -e "package.path=[[${LOOP_HOME}/lua/?.lua]]"
LUAPRELOADER= ${LOOP_HOME}/lua/preloader.lua

$(PRELOAD_DIR)/$(LIBNAME).c: $(LUAPRELOADER) $(LUASRC)
	$(LOOPBIN) $(LUAPRELOADER) -m \
	                           -l "$(LUADIR)/?.lua" \
	                           -d $(PRELOAD_DIR) \
	                           -h $(LIBNAME).h \
	                           -o $(LIBNAME).c \
	                           $(LUASRC)
