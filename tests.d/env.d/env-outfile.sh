#!/bin/sh

. $_MKCONFIG_DIR/bin/testfuncs.sh

maindodisplay $1 'multiple output files'
maindoquery $1 $_MKC_SH

getsname $0
dosetup $@
dorunmkc

chkdiff test.env test2.env
chkdiff mkc_test_env.vars mkc_test2_env.vars

testcleanup test2.env mkc_test_env.vars mkc_test2_env.vars

exit $grc
