#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " compile perl scripts${EC}"
  exit 0
fi

script=$@

grc=0

cd $_MKCONFIG_DIR
for i in *.pl; do
  perl -cw $i
  rc=$?
  if [ $rc -ne 0 ];then grc=$rc; fi
done

exit $grc
