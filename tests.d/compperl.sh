#!/bin/sh

script=$@
echo ${EN} "compile perl scripts${EC}" >&5

grc=0

cd $_MKCONFIG_DIR
for i in *.pl; do
  perl -cw $i
  rc=$?
  if [ $rc -ne 0 ];then grc=$rc; fi
done

exit $grc
