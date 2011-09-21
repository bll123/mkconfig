#!/bin/sh

. $_MKCONFIG_DIR/testfuncs.sh

maindodisplay $1 'ifoption - no options file'
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

for t in _test_a _test_b; do
  chkoutfile "^#define ${t} 0$"
  chkoutfile "^#define ${t} 1$"
done
chkouthcompile

testcleanup

exit $grc
