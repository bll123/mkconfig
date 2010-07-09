#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " cache${EC}"
  exit 0
fi

script=$@

. $_MKCONFIG_DIR/shellfuncs.sh
testshcapability

ccount=1
if [ -f ${_MKCONFIG_RUNTMPDIR}/cache.${ccount} ]; then
  domath ccount "$ccount + 1"
fi
while test -f cache.${ccount}; do
  domath ccount "$ccount + 1"
done

if [ $ccount -eq 1 ]; then
  eval "${script} -C $_MKCONFIG_RUNTESTDIR/cache.dat"
  mv -f cache.ctest ${_MKCONFIG_RUNTMPDIR}/cache.${ccount}
  cp -f mkconfig_c.vars ${_MKCONFIG_RUNTMPDIR}/cache.${ccount}.vars
  $0 $@
  exit $?
fi

dosh=T
case $script in
  *.pl)
    dosh=F
    ;;
esac

${_MKCONFIG_SHELL} ${script} $_MKCONFIG_RUNTESTDIR/cache.dat
mv -f cache.ctest cache.${ccount}
mv -f mkconfig_c.vars cache.${ccount}.vars
cp -f ${_MKCONFIG_RUNTMPDIR}/cache.1.vars mkconfig_c.vars

grc=0
c=2
while test $c -lt $ccount; do
  echo "## diff config.h 1 ${c}"
  diff -b ${_MKCONFIG_RUNTMPDIR}/cache.1 cache.${c}
  rc=$?
  if [ $rc -ne 0 ]; then grc=$rc; fi
  echo "## diff vars 1 $c"
  diff -b ${_MKCONFIG_RUNTMPDIR}/cache.1.vars cache.${c}.vars
  rc=$?
  if [ $? -ne 0 ]; then grc=$rc; fi
  domath c "$c + 1"
done
exit $grc
