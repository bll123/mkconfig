#!/bin/sh

script=$@

. $_MKCONFIG_DIR/shellfuncs.sh
testshcapability

echo ${EN} "if${EC}" >&5
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

    eval "${s} ${script} -C ${_MKCONFIG_RUNTESTDIR}/if_env.dat"
    for t in \
        _var_a _var_b \
        _test_b1_ok _test_b2_ok _test_b3_ok _test_b4_ok \
        _test_a1_ok _test_a2_ok _test_a3_ok _test_a4_ok _test_a5_ok \
        _test_o1_ok _test_o2_ok _test_o3_ok _test_o4_ok \
            _test_o5_ok _test_o6_ok \
        _test_m1_ok _test_m2_ok; do
      echo "chk: $t (1)"
      grep "^${t}=\"1\"$" if_env.ctest
      rc=$?
      if [ $rc -ne 0 ]; then grc=$rc; fi
    done

    mv if_env.ctest if_env.ctest.${count}
    mv mkconfig.log mkconfig.log.${count}
    mv mkconfig.cache mkconfig.cache.${count}
    mv mkconfig_env.vars mkconfig_env.vars.${count}
    domath count "$count + 1"
  done
fi

exit $grc
