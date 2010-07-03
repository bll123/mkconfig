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
    echo ${EN} " skipped${EC}" >&5
    exit 0
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

    eval "${s} ${script} -C ${_MKCONFIG_RUNTESTDIR}/set_env.dat"
    l=`grep "^_test1=\"1\"$" set_env.ctest | wc -l`
    rc=$?
    if [ $rc -ne 0 ]; then grc=$rc; fi
    if [ $l -ne 1 ]; then grc=1; fi
    grep "^_test2=\"a b c\"$" set_env.ctest
    rc=$?
    if [ $rc -ne 0 ]; then grc=$rc; fi
    mv set_env.ctest set_env.ctest.${count}
    mv mkconfig.log mkconfig.log.${count}
    mv mkconfig.cache mkconfig.cache.${count}
    mv mkconfig_env.vars mkconfig_env.vars.${count}
    domath count "$count + 1"
  done
fi

exit $grc
