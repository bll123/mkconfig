#!/bin/sh

. $_MKCONFIG_DIR/testfuncs.sh

maindodisplay $1 'compile shell scripts'
maindoquery $1 $_MKC_SH

getsname $0
dosetup $@

if [ "$_MKCONFIG_SHELL" = "" ]; then
  _MKCONFIG_SHELL=$SHELL
fi
if [ "$_MKCONFIG_SHELL" = "" ]; then
  _MKCONFIG_SHELL=/bin/sh
fi

# need globbing on.
set +f

cd $_MKCONFIG_DIR
for f in *.sh; do
  $_MKCONFIG_SHELL -n $f
  rc=$?
  if [ $rc -ne 0 ];then grc=$rc; fi
done
cd $_MKCONFIG_DIR/mkconfig.units
for f in *.sh; do
  $_MKCONFIG_SHELL -n $f
  rc=$?
  if [ $rc -ne 0 ];then grc=$rc; fi
done
cd $_MKCONFIG_DIR/tests.d
for f in *.sh; do
  $_MKCONFIG_SHELL -n $f
  rc=$?
  if [ $rc -ne 0 ];then grc=$rc; fi
done
cd $_MKCONFIG_DIR/tests.d/c.d
for f in *.sh; do
  $_MKCONFIG_SHELL -n $f
  rc=$?
  if [ $rc -ne 0 ];then grc=$rc; fi
done
cd $_MKCONFIG_DIR/tests.d/d.d
for f in *.sh; do
  $_MKCONFIG_SHELL -n $f
  rc=$?
  if [ $rc -ne 0 ];then grc=$rc; fi
done
cd $_MKCONFIG_DIR/tests.d/env.d
for f in *.sh; do
  $_MKCONFIG_SHELL -n $f
  rc=$?
  if [ $rc -ne 0 ];then grc=$rc; fi
done

testcleanup
exit $grc
