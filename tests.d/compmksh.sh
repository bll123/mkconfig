#!/bin/sh

script=$@
echo ${EN} "compile mkconfig.sh${EC}" >&3

grc=0

/bin/sh -n ../mkconfig.sh
rc=$?
if [ $rc -ne 0 ];then grc=$rc; fi

if [ -x /bin/dash ]; then
  /bin/dash -n ../mkconfig.sh
  rc=$?
  if [ $rc -ne 0 ];then grc=$rc; fi
fi

if [ -x /usr/bin/ksh ]; then
  /usr/bin/ksh -n ../mkconfig.sh
  rc=$?
  if [ $rc -ne 0 ];then grc=$rc; fi
fi

if [ -x /bin/bash ]; then
  /bin/bash -n ../mkconfig.sh
  rc=$?
  if [ $rc -ne 0 ];then grc=$rc; fi
fi

exit $grc
