#!/bin/sh

. $_MKCONFIG_DIR/bin/testfuncs.sh

maindodisplay $1 'need prototype'
maindoquery $1 $_MKC_SH_PL

chkccompiler
getsname $0
dosetup $@

> nptlib.h echo '

#if defined(__STDC__) || defined(__cplusplus) || defined(c_plusplus)
# define _(x) x
#else
# define _(x) ()
# define void char
#endif
#if defined(__cplusplus) || defined (c_plusplus)
# define CPP_EXTERNS_BEG extern "C" {
# define CPP_EXTERNS_END }
CPP_EXTERNS_BEG
extern int printf (const char *, ...);
CPP_EXTERNS_END
#else
# define CPP_EXTERNS_BEG
# define CPP_EXTERNS_END
#endif

CPP_EXTERNS_BEG
/* extern int npt1lib (); */
extern int npt2lib _((void));
CPP_EXTERNS_END
'

> nptlib.c echo '
#include <stdio.h>
#include <stdlib.h>
#include <nptlib.h>
int npt1lib () { printf ("hello world\\n"); return 0; }
int npt2lib () { printf ("hello world\\n"); return 0; }
'

CFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${CFLAGS}"
LDFLAGS="-L${_MKCONFIG_TSTRUNTMPDIR} ${LDFLAGS}"
export CFLAGS LDFLAGS

${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkconfig.sh -d `pwd` \
    -C $_MKCONFIG_RUNTESTDIR/c.env.dat
. ./c.env

chkccompile nptlib.c
ar cq libnptlib.a nptlib.o

dorunmkc

chkouth "^#define _npt_npt1lib 1$"
chkouth "^#define _npt_npt2lib 0$"
chkouthcompile

testcleanup nptlib.c nptlib.h libnptlib.a

exit $grc
