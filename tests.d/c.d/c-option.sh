#!/bin/sh

. $_MKCONFIG_DIR/testfuncs.sh

maindodisplay $1 option
maindoquery $1 $_MKC_SH_PL

chkccompiler
getsname $0
dosetup $@

TMP=opts
cat > $TMP << _HERE_
TEST_OPT_SET=abc123
TEST_OPT_SET_SPACE=abc 123
_HERE_

dorunmkc

chkouth "^#define TEST_OPT_DEF \"default\"$"
chkouth "^#define TEST_OPT_SET \"abc123\"$"
chkouth "^#define TEST_OPT_SET_SPACE \"abc 123\"$"

testcleanup

exit $grc
