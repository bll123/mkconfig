#!/bin/sh

. $_MKCONFIG_DIR/testfuncs.sh

maindodisplay $1 set
maindoquery $1 $_MKC_SH_PL

chkccompiler
getsname $0
dosetup $@
dorunmkc

chkouth "^#define _define_EOF 0$"
chkouth "^#define _lib_something" neg
chkouth "^#define _test1 1$" wc 1
chkouth "^#define _test2 \"a b c\"$"

testcleanup

exit $grc
