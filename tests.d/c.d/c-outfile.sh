#!/bin/sh

. $_MKCONFIG_DIR/bin/testfuncs.sh

maindodisplay $1 'multiple output files'
maindoquery $1 $_MKC_SH_PL

chkccompiler
getsname $0
dosetup $@

dorunmkc

for i in 1 2 3 4; do
  sed -e '/Created on:/d' -e "s/OUT${i}/OUT/" out${i}.h > out${i}.h.n
done
chkdiff out1.h.n out3.h.n
chkdiff out2.h.n out4.h.n
chkdiff ${MKC_FILES}/mkc_out1_c.vars ${MKC_FILES}/mkc_out3_c.vars
chkdiff ${MKC_FILES}/mkc_out2_c.vars ${MKC_FILES}/mkc_out4_c.vars

#testcleanup out1.h out2.h out3.h out4.h \
#    out1.h.n out2.h.n out3.h.n out4.h.n \
#    mkc_out1_c.vars mkc_out2_c.vars mkc_out3_c.vars mkc_out4_c.vars
testcleanup

exit $grc
