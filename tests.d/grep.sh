#!/bin/sh

. $_MKCONFIG_DIR/bin/testfuncs.sh

maindodisplay $1 grep
maindoquery $1 $_MKC_SH_PL

getsname $0
dosetup $@

> ${_MKCONFIG_TSTRUNTMPDIR}/gfile echo '
test1a="blah"
'

dorunmkc

chkouth '^#define _grep_test1a 1$'
chkouth '^#define _grep_test1b 0$'
chkouth '^#define _grep_test1c 1$'
chkcache "^mkc__grep_test1a='1'$"
chkcache "^mkc__grep_test1b='0'$"
chkcache "^mkc__grep_test1c='1'$"

testcleanup

exit $grc
