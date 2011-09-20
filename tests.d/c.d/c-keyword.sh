#!/bin/sh

. $_MKCONFIG_DIR/testfuncs.sh

maindodisplay $1 keyword
maindoquery $1 $_MKC_SH_PL

chkccompiler
getsname $0
dosetup $@
dorunmkc

chkouth "^#define _key_long 1$"
chkouth "^#define _key_xyzzy 0$"

testcleanup

exit $grc
