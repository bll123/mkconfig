#!/bin/sh

. $_MKCONFIG_DIR/bin/testfuncs.sh

maindodisplay $1 option
maindoquery $1 $_MKC_SH

getsname $0
dosetup $@

TMP=opts
> $TMP echo '
TEST_OPT_SET=abc123
TEST_OPT_SET_SPACE=abc 123
'

dorunmkc

chkenv "^TEST_OPT_DEF=\"default\"$"
chkenv "^TEST_OPT_SET=\"abc123\"$"
chkenv "^TEST_OPT_SET_SPACE=\"abc 123\"$"

testcleanup
exit $grc
