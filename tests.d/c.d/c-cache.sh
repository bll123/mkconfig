#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " build from cache${EC}"
  exit 0
fi

if [ "${CC}" = "" ]; then
  echo ${EN} " no cc; skipped${EC}" >&5
  exit 0
fi

stag=$1
shift
script=$@

. $_MKCONFIG_DIR/shellfuncs.sh
testshcapability

ccount=1
if [ -f ${_MKCONFIG_RUNTMPDIR}/c-cache.${ccount} ]; then
  domath ccount "$ccount + 1"
fi
while test -f c-cache.${ccount}; do
  domath ccount "$ccount + 1"
done

if [ $ccount -eq 1 ]; then
  case ${script} in
    *mkconfig.sh)
      ${_MKCONFIG_SHELL} ${script} -d `pwd` -C ${_MKCONFIG_RUNTESTDIR}/c-cache.dat
      ;;
    *)
      perl ${script} -C ${_MKCONFIG_RUNTESTDIR}/c-cache.dat
      ;;
  esac
  mv -f c-cache.ctest ${_MKCONFIG_RUNTMPDIR}/c-cache.${ccount}
  cp -f mkconfig_c.vars ${_MKCONFIG_RUNTMPDIR}/c-cache.${ccount}.vars
  mv -f mkconfig.log mkconfig.log.${ccount}
  # keep mkconfig.cache and mkconfig_c.vars around...
  $0 $stag $script
  exit $?
fi

for f in c-cache.ctest mkconfig_c.vars mkconfig.log mkconfig.cache; do
  test -f $f && rm -f $f
done
case ${script} in
  *mkconfig.sh)
    ${_MKCONFIG_SHELL} ${script} -d `pwd` ${_MKCONFIG_RUNTESTDIR}/c-cache.dat
    ;;
  *)
    ${script} ${_MKCONFIG_RUNTESTDIR}/c-cache.dat
    ;;
esac
mv -f c-cache.ctest c-cache.${ccount}
mv -f mkconfig_c.vars c-cache.${ccount}.vars
cp -f ${_MKCONFIG_RUNTMPDIR}/c-cache.1.vars mkconfig_c.vars
mv -f mkconfig.log mkconfig.log.${ccount}
# keep mkconfig.cache and mkconfig_c.vars around...

grc=0
c=2
while test $c -lt $ccount; do
  echo "## diff config.h 1 ${c}"
  diff -b ${_MKCONFIG_RUNTMPDIR}/c-cache.1 c-cache.${c}
  rc=$?
  if [ $rc -ne 0 ]; then grc=$rc; fi
  echo "## diff vars 1 $c"
  diff -b ${_MKCONFIG_RUNTMPDIR}/c-cache.1.vars c-cache.${c}.vars
  rc=$?
  if [ $? -ne 0 ]; then grc=$rc; fi
  domath c "$c + 1"
done

exit $grc
