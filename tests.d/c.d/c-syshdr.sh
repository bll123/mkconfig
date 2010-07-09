#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " syshdr${EC}" 
  exit 0
fi

script=$@

. $_MKCONFIG_DIR/shellfuncs.sh
testshcapability

grc=0
count=1

dosh=T
case $script in
  *.pl)
    dosh=F
    ;;
esac

${_MKCONFIG_SHELL} ${script} -C ${_MKCONFIG_RUNTESTDIR}/syshdr.dat
grep "^#define _sys_types 1$" syshdr.ctest
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi
if [ "$stag" != "" ]; then
  mv syshdr.ctest syshdr.ctest${stag}
  mv mkconfig.log mkconfig.log${stag}
  mv mkconfig.cache mkconfig.cache${stag}
  mv mkconfig_c.vars mkconfig_c.vars${stag}
fi

exit $grc
