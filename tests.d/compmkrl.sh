#!/bin/sh

script=$@
echo ${EN} "compile mkreqlib.sh${EC}" >&3

grc=0

echo ${EN} " ${EC}" >&3
for s in $shelllist; do
  unset _shell
  unset shell
  cmd="$s -c \". $_MKCONFIG_DIR/shellfuncs.sh;getshelltype;echo \\\$shell\""
  ss=`eval $cmd`
  if [ "$ss" = "sh" ]; then
    ss=`echo $s | sed 's,.*/,,'`
  fi
  echo ${EN} "${ss} ${EC}" >&3
  echo "   testing with ${s} "
  $s -n $_MKCONFIG_DIR/mkreqlib.sh
  rc=$?
  if [ $rc -ne 0 ];then grc=$rc; fi
done

exit $grc
