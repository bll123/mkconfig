#!/bin/sh

. $_MKCONFIG_DIR/testfuncs.sh

maindodisplay $1 const
maindoquery $1 $_MKC_SH_PL

chkccompiler
getsname $0
dosetup $@
dorunmkc
chkouth "^#define _const_O_RDONLY 1$"
testcleanup

exit $grc
