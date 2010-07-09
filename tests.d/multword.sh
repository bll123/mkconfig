#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " output multiple words${EC}"
  exit 0
fi

script=$@

grc=0

rm -f mkconfig.cache multword.env mkconfig.log > /dev/null 2>&1
${script} -C ${_MKCONFIG_RUNTESTDIR}/multword.dat
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

exit $grc
