#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " size${EC}"
  exit 0
fi

script=$@

grc=0

${script} -C ${_MKCONFIG_RUNTESTDIR}/size.dat
v=`grep "^#define _siz_long 4$" size.ctest | sed 's/.* //'`
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
