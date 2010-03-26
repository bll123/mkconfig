#!/bin/sh

script=$@
echo ${EN} "compile mkconfig.sh${EC}" >&3

. $MKCONFIG_DIR/shellfuncs.sh
grc=0

echo ${EN} " ${EC}" >&3
getlistofshells
for s in $shelllist; do
  unset _shell
  unset shell
  cmd="$s -c \". $MKCONFIG_DIR/shellfuncs.sh;getshelltype;echo \\\$shell\""
  ss=`eval $cmd`
  if [ "$ss" = "sh" ]; then
    ss=`echo $s | sed 's,.*/,,'`
  fi
  echo ${EN} "${ss} ${EC}" >&3
  echo "   testing with ${s} "
  $s -n $MKCONFIG_DIR/mkconfig.sh
  rc=$?
  if [ $rc -ne 0 ];then grc=$rc; fi
done

exit $grc
