#!/bin/sh

. $_MKCONFIG_DIR/bin/testfuncs.sh

maindodisplay $1 'w/single lib'
maindoquery $1 $_MKC_SH_PL

chkccompiler
getsname $0
dosetup $@

> tst1lib.h echo '

#if defined(__STDC__) || defined(__cplusplus) || defined(c_plusplus)
# define _(x) x
#else
# define _(x) ()
# define void char
#endif

extern int tst1lib ();
'

> tst1lib.c echo '
#include <stdio.h>
#include <stdlib.h>
#include <tst1lib.h>
int tst1lib () { printf ("hello world\\n"); return 0; }
'

CFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${CFLAGS}"
LDFLAGS="-L${_MKCONFIG_TSTRUNTMPDIR} ${LDFLAGS}"
export CFLAGS LDFLAGS

${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkconfig.sh -d `pwd` \
    -C $_MKCONFIG_RUNTESTDIR/c.env.dat
. ./c.env

${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkc.sh -d `pwd` -compile \
    -log mkc_compile.log${stag} -e -o tst1lib${OBJ_EXT} tst1lib.c
if [ $? -ne 0 ]; then
  echo "compile tst1lib.c failed"
  exit 1
fi
${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkc.sh -d `pwd` -staticlib \
    -log mkc_compile.log${stag} \
    libtst1lib tst1lib${OBJ_EXT}

dorunmkc reqlibs out.h

chkouthcompile
sed -e '/^#define _key_/d' \
    -e '/^#define _proto_/d' \
    -e '/^#define _param_/d' \
    -e '/Created on: /,/Using: mkc/ d' \
    out.h > out.h.n
chkdiff c-singlelib.ctmp out.h.n
chkdiff ${_MKCONFIG_RUNTESTDIR}/c-singlelib.reqlibs mkconfig.reqlibs

testcleanup

exit $grc
