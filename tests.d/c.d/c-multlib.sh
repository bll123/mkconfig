#!/bin/sh

. $_MKCONFIG_DIR/bin/testfuncs.sh

maindodisplay $1 'w/multiple libs'
maindoquery $1 $_MKC_SH_PL

chkccompiler
getsname $0
dosetup $@

CFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${CFLAGS}"
LDFLAGS="-L${_MKCONFIG_TSTRUNTMPDIR} ${LDFLAGS}"
export CFLAGS LDFLAGS

${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkconfig.sh -d `pwd` \
    -C $_MKCONFIG_RUNTESTDIR/c.env.dat
. ./c.env

> tst2libb.h echo '
extern int tst2libb ();
'
> tst2libc.h echo '
extern int tst2libc ();
'

> tst2libb.c echo '
#include <stdio.h>
#include <stdlib.h>
#include <tst2libb.h>
#include <tst2libc.h>
int tst2libb () { tst2libc(); return 0; }
'

${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkc.sh -d `pwd` -compile \
    -log mkc_compile.log${stag} -e -o tst2libb${OBJ_EXT} tst2libb.c
${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkc.sh -d `pwd` -staticlib \
    -log mkc_compile.log${stag} -e \
    libtst2libb tst2libb${OBJ_EXT}

> tst2libc.c echo '
#include <stdio.h>
#include <stdlib.h>
#include <tst2libc.h>
int tst2libc () { printf ("hello world\\n"); return 0; }
'

${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkc.sh -d `pwd` -compile \
    -log mkc_compile.log${stag} -e -o tst2libc${OBJ_EXT} tst2libc.c
${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkc.sh -d `pwd` -staticlib \
    -log mkc_compile.log${stag} -e \
    libtst2libc tst2libc${OBJ_EXT}

dorunmkc reqlibs out.h

sed -e '/^#define _key_/d' \
    -e '/^#define _proto_/d' \
    -e '/^#define _param_/d' \
    -e '/Created on: /,/Using: mkc/ d' \
    out.h > out.h.n
chkdiff c-multlib.ctmp out.h.n
chkdiff ${_MKCONFIG_RUNTESTDIR}/c-multlib.reqlibs mkconfig.reqlibs

testcleanup out.h.n

exit $grc
