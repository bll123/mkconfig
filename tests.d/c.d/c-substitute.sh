#!/bin/sh

. $_MKCONFIG_DIR/bin/testfuncs.sh

maindodisplay $1 substitute
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

dorunmkc

chkouth "^#define _define_EOF 0$"
chkouth "^#define _lib_something" neg
chkouth "^#define _testA 1$" wc 1
chkouth "^#define _test2 \"d e f\"$"

chkouthcompile
testcleanup

exit $grc
