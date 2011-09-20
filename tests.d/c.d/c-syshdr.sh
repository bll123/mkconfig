#!/bin/sh

. $_MKCONFIG_DIR/testfuncs.sh

maindodisplay $1 'sys/ header'
maindoquery $1 $_MKC_SH_PL

chkccompiler
getsname $0
dosetup $@
dorunmkc

chkouth "^#define _sys_types 1$"

testcleanup

exit $grc
