#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " build from cache${EC}"
  exit 0
fi

stag=$1
shift
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
  ${script} -C $_MKCONFIG_RUNTESTDIR/cache.dat
  mv -f cache.ctest ${_MKCONFIG_RUNTMPDIR}/cache.${ccount}
  cp -f mkconfig_c.vars ${_MKCONFIG_RUNTMPDIR}/cache.${ccount}.vars
  mv -f mkconfig.log mkconfig.log.${ccount}
  # keep mkconfig.cache and mkconfig_c.vars around...
  $0 $@
  exit $?
fi

for f in cache.ctest mkconfig_c.vars mkconfig.log mkconfig.cache; do
  test -f $f && rm -f $f
done
${script} $_MKCONFIG_RUNTESTDIR/cache.dat
mv -f cache.ctest cache.${ccount}
mv -f mkconfig_c.vars cache.${ccount}.vars
cp -f ${_MKCONFIG_RUNTMPDIR}/cache.1.vars mkconfig_c.vars
mv -f mkconfig.log mkconfig.log.${ccount}
# keep mkconfig.cache and mkconfig_c.vars around...

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
