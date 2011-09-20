#!/bin/sh

. $_MKCONFIG_DIR/testfuncs.sh

maindodisplay $1 declare
maindoquery $1 $_MKC_SH_PL

chkccompiler
getsname $0
dosetup $@

> dcltst.h echo '
int a;
int *b;
int *c;
int d;
'
CFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${CFLAGS}"
LDFLAGS="-L${_MKCONFIG_TSTRUNTMPDIR} ${LDFLAGS}"
export CFLAGS LDFLAGS

dorunmkc
chkouth "^#define _dcl_a 1$"
chkoutfile "^#define _dcl_b 1$"
chkoutfile "^#define _dcl_c [01]$"
chkoutfile "^#define _dcl_d [01]$"
testcleanup

exit $grc
