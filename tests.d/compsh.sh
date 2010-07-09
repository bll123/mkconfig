#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " compile shell scripts${EC}" 
  exit 0
fi

script=$@

grc=0

if [ "$_MKCONFIG_SHELL" = "" ]; then
  _MKCONFIG_SHELL=$SHELL
fi
if [ "$_MKCONFIG_SHELL" = "" ]; then
  _MKCONFIG_SHELL=/bin/sh
fi

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

exit $grc
