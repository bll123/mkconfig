#!/bin/sh

. $_MKCONFIG_DIR/bin/testfuncs.sh

maindodisplay $1 source
maindoquery $1 $_MKC_SH

getsname $0
dosetup $@

> stest.sh echo '
COOKIE=oatmeal
'

dorunmkc

grc=1
if [ -f test.env ];then
  . ./test.env

  if [ "$COOKIE" = oatmeal ]; then
    grc=0
  fi
fi

testcleanup
exit $grc
