#!/bin/sh

. $_MKCONFIG_DIR/bin/testfuncs.sh

maindodisplay $1 set
maindoquery $1 $_MKC_SH

getsname $0
dosetup $@
dorunmkc

chkenv "^_test1=\"1\"$" wc 1
chkenv "^_test2=\"a b c\"$"

testcleanup
exit $grc
