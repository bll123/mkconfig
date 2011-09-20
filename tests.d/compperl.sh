#!/bin/sh

. $_MKCONFIG_DIR/testfuncs.sh

maindodisplay $1 'compile perl scripts'
maindoquery $1 $_MKC_ONCE

getsname $0
dosetup $@

cd $_MKCONFIG_DIR
for i in *.pl; do
  perl -cw $i
  rc=$?
  if [ $rc -ne 0 ];then grc=$rc; fi
done

testcleanup
exit $grc
