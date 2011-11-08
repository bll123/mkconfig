#!/bin/sh

. $_MKCONFIG_DIR/bin/testfuncs.sh

maindodisplay $1 'multiple output files'
maindoquery $1 $_MKC_SH_PL

chkccompiler
getsname $0
dosetup $@

dorunmkc

sed -e 's/OUT2/OUT/' out2.h > out2.h.n
chkdiff out.h out2.h.n
chkdiff mkc_out_c.vars mkc_out2_c.vars

testcleanup out2.h mkc_out2_c.vars out2.h.n

exit $grc
