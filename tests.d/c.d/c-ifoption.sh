#!/bin/sh

set -x
script=$@

. $_MKCONFIG_DIR/shellfuncs.sh
testshcapability

echo ${EN} "option_env${EC}" >&5
grc=0
count=1

dosh=T
case $script in
  *.pl)
    echo ${EN} " skipped${EC}" >&5
    exit 0
    ;;
esac

OPTIONS="NO_TEST_NO YES_TEST_YES WITHOUT_TEST_WITHOUT WITH_TEST_WITH
    TEST_OPT_T=T TEST_OPT_F=F TEST_F_OTHER=F"
export OPTIONS

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

    eval "${s} ${script} -C ${_MKCONFIG_RUNTESTDIR}/option_env.dat"
    for t in TEST_T TEST_YES TEST_WITH TEST_OPT_T; do
      echo "chk: _option_$t (1)"
      grep "^_option_${t}=\"1\"$" option_env.ctest
      rc=$?
      if [ $rc -ne 0 ]; then grc=$rc; fi
    done
    for t in TEST_F TEST_NO TEST_WITHOUT TEST_OPT_F TEST_F_OTHER; do
      echo "chk: _option_$t (0)"
      grep "^_option_${t}=\"0\"$" option_env.ctest
      rc=$?
      if [ $rc -ne 0 ]; then grc=$rc; fi
    done
    for t in TEST_TEMP; do
      echo "chk: _option_$t (0)"
      grep "^_option_${t}=\"0\"$" option_env.ctest
      rc=$?
      if [ $rc -ne 0 ]; then grc=$rc; fi
    done
    mv option_env.ctest option_env.ctest.${count}
    mv mkconfig.log mkconfig.log.${count}
    mv mkconfig.cache mkconfig.cache.${count}
    mv mkconfig_env.vars mkconfig_env.vars.${count}
    domath count "$count + 1"
  done
fi

exit $grc
