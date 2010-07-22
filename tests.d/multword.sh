#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " output multiple words${EC}"
  exit 0
fi

stag=$1
shift
script=$@

grc=0

rm -f mkconfig.cache multword.env mkconfig.log > /dev/null 2>&1
case ${script} in
  *mkconfig.sh)
    ${_MKCONFIG_SHELL} ${script} -d `pwd` -C ${_MKCONFIG_RUNTESTDIR}/multword.dat
    ;;
  *)
    ${script} -C ${_MKCONFIG_RUNTESTDIR}/multword.dat
    ;;
esac
. ./mkconfig.cache
if [ "$di_env_test_multword" != "word1 word2" ]; then
  echo "   failed: cache: $di_env_test_multword"
  grc=1
fi
. ./multword.env
if [ "$test_multword" != "word1 word2" ]; then
  echo "   failed: env: $test_multword"
  grc=1
fi
if [ "$stag" != "" ]; then
  mv multword.ctest multword.ctest${stag}
  mv mkconfig.log mkconfig.log${stag}
  mv mkconfig.cache mkconfig.cache${stag}
  mv mkconfig_env.vars mkconfig_env.vars${stag}
fi

exit $grc
