#!/bin/sh

. $_MKCONFIG_DIR/testfuncs.sh

maindodisplay $1 size
maindoquery $1 $_MKC_SH_PL

chkccompiler
getsname $0
dosetup $@
dorunmkc

v=`grep "^#define _siz_long [0-9]*$" out.h | sed 's/.* //'`
grc=1
if [ "$v" != "" ]; then
  if [ $v -ge 4 ]; then
    grc=0
  fi
fi

testcleanup

exit $grc
