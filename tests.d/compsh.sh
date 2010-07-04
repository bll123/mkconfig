#!/bin/sh

script=$@
echo ${EN} "compile shell scripts${EC}" >&5

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
  echo "## testing with ${s} "
  cd $_MKCONFIG_DIR
  for f in *.sh; do
    $s -n $f
    rc=$?
    if [ $rc -ne 0 ];then grc=$rc; fi
  done
  cd $_MKCONFIG_DIR/mkconfig.units
  for f in *.sh; do
    $s -n $f
    rc=$?
    if [ $rc -ne 0 ];then grc=$rc; fi
  done
  cd $_MKCONFIG_DIR/tests.d
  for f in *.sh; do
    $s -n $f
    rc=$?
    if [ $rc -ne 0 ];then grc=$rc; fi
  done
done

exit $grc
