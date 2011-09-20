#!/bin/sh

. $_MKCONFIG_DIR/testfuncs.sh

maindodisplay $1 define
maindoquery $1 $_MKC_SH_PL

chkccompiler
getsname $0
dosetup $@

> deftst.h echo '
#define MYDEFINE 20
'
CFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${CFLAGS}"
export CFLAGS

dorunmkc
chkouth "^#define _define_MYDEFINE 1$"
testcleanup

exit $grc
