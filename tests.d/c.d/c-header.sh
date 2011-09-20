#!/bin/sh

. $_MKCONFIG_DIR/testfuncs.sh

maindodisplay $1 header
maindoquery $1 $_MKC_SH_PL

chkccompiler
getsname $0
dosetup $@
dorunmkc
chkouth "^#define _sys_types 1$"
chkouth "^#define _hdr_ctype 1$"
testcleanup

exit $grc
