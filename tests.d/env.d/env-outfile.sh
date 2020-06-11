#!/bin/sh

. $_MKCONFIG_DIR/bin/testfuncs.sh

maindodisplay $1 'multiple output files'
maindoquery $1 $_MKC_SH

getsname $0
dosetup $@
dorunmkc

for i in 1 2 3 4; do
  sed -e '/^# Created on:/d'test${i}.env > test${i}.env.n
done
chkdiff test1.env.n test3.env.n
chkdiff test2.env.n test4.env.n
chkdiff ${MKC_FILES}/mkc_test1_env.vars ${MKC_FILES}/mkc_test3_env.vars
chkdiff ${MKC_FILES}/mkc_test2_env.vars ${MKC_FILES}/mkc_test4_env.vars

testcleanup

exit $grc
