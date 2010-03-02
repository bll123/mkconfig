#!/bin/sh

script=$@
echo ${EN} "compile environmental units${EC}" >&3

grc=0

cd ../env.units
for f in *.sh; do
  /bin/sh -n $f
  rc=$?
  if [ $rc -ne 0 ];then grc=$rc; fi

  if [ -x /bin/dash ]; then
    /bin/dash -n $f
    rc=$?
    if [ $rc -ne 0 ];then grc=$rc; fi
  fi

  if [ -x /usr/bin/ksh ]; then
    /usr/bin/ksh -n $f
    rc=$?
    if [ $rc -ne 0 ];then grc=$rc; fi
  fi

  if [ -x /bin/bash ]; then
    /bin/bash -n $f
    rc=$?
    if [ $rc -ne 0 ];then grc=$rc; fi
  fi
done

exit $grc
