#!/bin/sh

script=$@

. $_MKCONFIG_DIR/shellfuncs.sh
testshcapability

echo ${EN} "set${EC}" >&5
grc=0
count=1

dosh=T
case $script in
  *.pl)
    dosh=F
    ;;
esac

if [ "$dosh" = "T" ]; then
  echo ${EN} " ${EC}" >&5
  for s in $shelllist; do
    unset _shell
    unset shell
    cmd="$s -c \". $_MKCONFIG_DIR/shellfuncs.sh;getshelltype;echo \\\$shell\""
    ss=`eval $cmd`
    if [ "$ss" = "sh" ]; then
      ss=`echo $s | sed 's,.*/,,'`
    fi
    echo ${EN} "${ss} ${EC}" >&5
    echo "## testing with ${s} "
    _MKCONFIG_SHELL=$s
    export _MKCONFIG_SHELL
    shell=$ss

    eval "${s} ${script} -C ${_MKCONFIG_RUNTESTDIR}/set_c.dat"
    l=`grep "^#define _test1 1$" set_c.ctest | wc -l`
    rc=$?
    if [ $rc -ne 0 ]; then grc=$rc; fi
    if [ $l -ne 1 ]; then grc=1; fi
    grep "^#define _test2 \"a b c\"$" set_c.ctest
    rc=$?
    if [ $rc -ne 0 ]; then grc=$rc; fi
    mv set_c.ctest set_c.ctest.${count}
    mv mkconfig.log mkconfig.log.${count}
    mv mkconfig.cache mkconfig.cache.${count}
    mv mkconfig_c.vars mkconfig_c.vars.${count}
    domath count "$count + 1"
  done
else
  eval "${script} -C ${_MKCONFIG_RUNTESTDIR}/set_c.dat"
  l=`grep "^#define _test1 1$" set_c.ctest | wc -l`
  rc=$?
  if [ $rc -ne 0 ]; then grc=$rc; fi
  if [ $l -ne 1 ]; then grc=1; fi
  grep "^#define _test2 \"a b c\"$" set_c.ctest
  rc=$?
  if [ $rc -ne 0 ]; then grc=$rc; fi
fi

exit $grc
