#!/bin/sh

. $_MKCONFIG_DIR/bin/testfuncs.sh

maindodisplay $1 option
maindoquery $1 $_MKC_SH_PL

chkccompiler
getsname $0
dosetup $@

TMP=opts
> $TMP echo '
TEST_OPT_SET=abc123
TEST_OPT_SET_SPACE=abc 123
'

CFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${CFLAGS}"
LDFLAGS="-L${_MKCONFIG_TSTRUNTMPDIR} ${LDFLAGS}"
export CFLAGS LDFLAGS

${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkconfig.sh -d `pwd` \
    -C $_MKCONFIG_RUNTESTDIR/c.env.dat
. ./c.env

dorunmkc

chkouth "^#define TEST_OPT_DEF \"default\"$"
chkouth "^#define TEST_OPT_SET \"abc123\"$"
chkouth "^#define TEST_OPT_SET_SPACE \"abc 123\"$"

chkouthcompile

testcleanup

exit $grc
