#!/bin/sh

. $_MKCONFIG_DIR/testfuncs.sh

maindodisplay $1 typedef
maindoquery $1 $_MKC_SH_PL

chkccompiler
getsname $0
dosetup $@

> typtst.h echo '
typedef int my_type_t;
'

CFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${CFLAGS}"
export CFLAGS

dorunmkc

chkouth "^#define _typ_my_type_t 1$"

testcleanup

exit $grc
