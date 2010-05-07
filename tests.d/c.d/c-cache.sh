#!/bin/sh

script=$@

. $_MKCONFIG_DIR/shellfuncs.sh
testshcapability

count=1
while test -f cache.${count}; do
  domath count "$count + 1"
done

if [ $count -eq 1 ]; then
  echo ${EN} "cache${EC}" >&3
  pwd
  eval "${script} -C $RUNTESTDIR/cache.dat"
  mv -f cache.ctest cache.${count}
  cp -f mkconfig_c.vars cache.${count}.vars
  pwd
  $0 $@
  exit $?
fi

dosh=T
case $script in
  *.pl)
    dosh=F
    ;;
esac

if [ $dosh = "T" ]; then
  echo ${EN} " ${EC}" >&3
  for s in $shelllist; do
    unset _shell
    unset shell
    cmd="$s -c \". $_MKCONFIG_DIR/shellfuncs.sh;getshelltype;echo \\\$shell\""
    ss=`eval $cmd`
    cmd="$s -c \". $_MKCONFIG_DIR/shellfuncs.sh;getshelltype;echo \\\$shell\""
    ss=`eval $cmd`
    if [ "$ss" = "sh" ]; then
      ss=`echo $s | sed 's,.*/,,'`
    fi
    echo ${EN} "${ss} ${EC}" >&3
    eval "${s} -c '${script} $RUNTESTDIR/cache.dat'"
    mv -f cache.ctest cache.${count}
    mv -f mkconfig_c.vars cache.${count}.vars
    cp -f cache.1.vars mkconfig_c.vars
    domath count "$count + 1"
  done
else
  echo ${EN} "cache${EC}" >&3
  eval "${script} $RUNTESTDIR/cache.dat"
  mv -f cache.ctest cache.${count}
  mv -f mkconfig_c.vars cache.${count}.vars
  cp -f cache.1.vars mkconfig_c.vars
fi

grc=0
c=2
while test $c -lt $count; do
  echo "## diff config.h 1 ${c}"
  diff -b cache.1 cache.${c}
  rc=$?
  if [ $rc -ne 0 ]; then grc=$rc; fi
  echo "## diff vars 1 $c"
  diff -b cache.1.vars cache.${c}.vars
  rc=$?
  if [ $? -ne 0 ]; then grc=$rc; fi
  domath c "$c + 1"
done
exit $grc
