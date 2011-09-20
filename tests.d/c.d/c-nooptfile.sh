#!/bin/sh

. $_MKCONFIG_DIR/testfuncs.sh

maindodisplay $1 'ifoption - no options file'
maindoquery $1 $_MKC_SH_PL

chkccompiler
getsname $0
dosetup $@
dorunmkc

for t in _test_a _test_b; do
  chkoutfile "^#define ${t} 0$"
  chkoutfile "^#define ${t} 1$"
done

testcleanup

exit $grc
