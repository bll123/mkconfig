#!/bin/sh

. $_MKCONFIG_DIR/testfuncs.sh

maindodisplay $1 'ifoption - no option'
maindoquery $1 $_MKC_SH_PL

chkccompiler
getsname $0
dosetup $@

TMP=opts
cat > $TMP << _HERE_
TEST_ENABLE=enable
TEST_DISABLE=disable
TEST_ASSIGN_T=t
TEST_ASSIGN_F=f
_HERE_

dorunmkc

for t in _test_a _test_b; do
  chkouth "^#define ${t} 0$"
  chkouth "^#define ${t} 1$" neg
done

testcleanup

exit $grc
