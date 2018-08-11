#!/bin/sh

. $_MKCONFIG_DIR/bin/testfuncs.sh

maindodisplay $1 'ifoption - no option'
maindoquery $1 $_MKC_SH_PL

chkccompiler
getsname $0
dosetup $@

TOPTFILE=opts
> $TOPTFILE echo '
TEST_ENABLE=enable
TEST_DISABLE=disable
TEST_ASSIGN_T=t
TEST_ASSIGN_F=f
'

CFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${CFLAGS}"
LDFLAGS="-L${_MKCONFIG_TSTRUNTMPDIR} ${LDFLAGS}"
export CFLAGS LDFLAGS

${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkconfig.sh -d `pwd` \
    -C $_MKCONFIG_RUNTESTDIR/c.env.dat
. ./c.env

dorunmkc

for t in _test_a _test_b; do
  chkouth "^#define ${t} 0$"
  chkouth "^#define ${t} 1$" neg
done
chkouthcompile

testcleanup

exit $grc
