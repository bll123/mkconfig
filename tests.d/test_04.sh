#!/bin/sh

script=$@
echo ${EN} "compile environment.sh${EC}" >&3

grc=0

/bin/sh -n ../environment.sh
rc=$?
if [ $rc -ne 0 ];then grc=$rc; fi

if [ -x /bin/dash ]; then
  /bin/dash -n ../environment.sh
  rc=$?
  if [ $rc -ne 0 ];then grc=$rc; fi
fi

if [ -x /usr/bin/ksh ]; then
  /usr/bin/ksh -n ../environment.sh
  rc=$?
  if [ $rc -ne 0 ];then grc=$rc; fi
fi

if [ -x /bin/bash ]; then
  /bin/bash -n ../environment.sh
  rc=$?
  if [ $rc -ne 0 ];then grc=$rc; fi
fi

exit $grc
