#!/bin/sh

. $_MKCONFIG_DIR/bin/testfuncs.sh

maindodisplay $1 'output multiple words'
maindoquery $1 $_MKC_SH

getsname $0
dosetup $@
dorunmkc
chkcache "^mkc_test_multword='word1 word2'$"
chkenv '^test_multword="word1 word2"$'
chkenv '^export test_multword$'
testcleanup

exit $grc
