#!/bin/sh

. $_MKCONFIG_DIR/bin/testfuncs.sh

maindodisplay $1 'multiple output files'
maindoquery $1 $_MKC_SH

chkdcompiler
getsname $0
dosetup $@

${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkconfig.sh -d `pwd` \
    -C $_MKCONFIG_RUNTESTDIR/d.env.dat
. ./d.env

dorunmkc

for i in 1 2 3 4; do
  sed -e '/^\/\/ Created on:/d' -e "s/OUT${i}/OUT/" out${i}.d > out${i}.d.n
done
chkdiff out1.d.n out3.d.n
chkdiff out2.d.n out4.d.n
chkdiff mkc_out1_d.vars mkc_out3_d.vars
chkdiff mkc_out2_d.vars mkc_out4_d.vars

#testcleanup out1.d out2.d out3.d out4.d \
#    out1.d.n out2.d.n out3.d.n out4.d.n \
#    mkc_out1_d.vars mkc_out2_d.vars mkc_out3_d.vars mkc_out4_d.vars
testcleanup

exit $grc
