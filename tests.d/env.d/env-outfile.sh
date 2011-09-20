#!/bin/sh

. $_MKCONFIG_DIR/testfuncs.sh

maindodisplay $1 'multiple output files'
maindoquery $1 $_MKC_SH

getsname $0
dosetup $@
dorunmkc

chkdiff test.env test2.env

testcleanup test2.env

exit $grc
