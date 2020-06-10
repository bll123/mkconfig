# Example Makefile
#
# OBJ_EXT and EXE_EXT are used for portability to windows.
#

MKC_DIR = ../..
OBJ_EXT = .o
EXE_EXT =
MKC_REQLIB = hello.reqlibs

# executable
hello$(EXE_EXT):		$(MKC_REQLIB) hello$(OBJ_EXT)
	@. ./hello.env;$(_MKCONFIG_SHELL) \
		$(MKC_DIR)/mkc.sh -link -exec -r $(MKC_REQLIB) \
                -o hello$(EXE_EXT) hello$(OBJ_EXT)

# object files
hello$(OBJ_EXT):	config.h
	@. ./hello.env;$(_MKCONFIG_SHELL) $(MKC_DIR)/mkc.sh -compile \
                -o hello$(OBJ_EXT) hello.c

# required libraries
# for this example, there are none.
$(MKC_REQLIB):  config.h
	@$(_MKCONFIG_SHELL) $(MKC_DIR)/mkc.sh -reqlib \
		-o $(MKC_REQLIB) config.h

# config.h file created by mkconfig
config.h:	hello.env hello.mkc
	. ./hello.env; \
		CC=$(CC) $(_MKCONFIG_SHELL) $(MKC_DIR)/mkconfig.sh hello.mkc

# environment variables created by mkconfig
hello.env:	env.mkc
	CC=$(CC) $(_MKCONFIG_SHELL) $(MKC_DIR)/mkconfig.sh env.mkc

.PHONY: clean
clean:
	@-rm -f mkc_* mkconfig.cache mkconfig.log \
		hello.env config.h $(MKC_REQLIB) \
		hello$(EXE_EXT) hello$(OBJ_EXT) \
		*~
