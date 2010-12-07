#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " size${EC}"
  exit 0
fi

if [ "${CC}" = "" ]; then
  echo ${EN} " no cc; skipped${EC}" >&5
  exit 0
fi

stag=$1
shift
script=$@

grc=0

case ${script} in
  *mkconfig.sh)
    ${_MKCONFIG_SHELL} ${script} -d `pwd` -C ${_MKCONFIG_RUNTESTDIR}/c-size.dat
    ;;
  *)
    perl ${script} -C ${_MKCONFIG_RUNTESTDIR}/c-size.dat
    ;;
esac
v=`grep "^#define _siz_long [0-9]*$" size.ctest | sed 's/.* //'`
grc=1
if [ "$v" != "" ]; then
  if [ $v -ge 4 ]; then
    grc=0
  fi
fi
if [ "$stag" != "" ]; then
  mv size.ctest size.ctest${stag}
  mv mkconfig.log mkconfig.log${stag}
  mv mkconfig.cache mkconfig.cache${stag}
  mv mkconfig_c.vars mkconfig_c.vars${stag}
fi

exit $grc
