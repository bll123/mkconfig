#!/bin/sh

script=$@
echo ${EN} "output multiple words${EC}" >&5

grc=0

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
  echo "   testing with ${s} "
  _MKCONFIG_SHELL=$s
  export _MKCONFIG_SHELL
  shell=$ss
  rm -f mkconfig.cache multword.env mkconfig.log > /dev/null 2>&1
  eval "$_MKCONFIG_SHELL $_MKCONFIG_DIR/mkconfig.sh -C \
        ${_MKCONFIG_RUNTESTDIR}/multword.dat"
  . ./mkconfig.cache
  if [ "$di_env_test_multword" != "word1 word2" ]; then
    echo "   failed with ${s}: cache: $di_env_test_multword"
    grc=1
  fi
  . ./multword.env
  if [ "$test_multword" != "word1 word2" ]; then
    echo "   failed with ${s}: env: $test_multword"
    grc=1
  fi
done

exit $grc
