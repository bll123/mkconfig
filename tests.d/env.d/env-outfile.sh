#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " multiple output files${EC}"
  exit 0
fi

if [ "${CC}" = "" ]; then
  echo ${EN} " no cc; skipped${EC}" >&5
  exit 0
fi

shift
script=$@

for f in outfile1.ctest outfile2.ctest \
    mkconfig_c.vars mkconfig.log mkconfig.cache; do
  test -f $f && rm -f $f
done
case ${script} in
  *mkconfig.sh)
    ${_MKCONFIG_SHELL} ${script} -d `pwd` -C ${_MKCONFIG_RUNTESTDIR}/c-outfile.dat
    ;;
  *)
    perl ${script} -C ${_MKCONFIG_RUNTESTDIR}/c-outfile.dat
    ;;
esac

grc=0

echo "## diff outfile1.ctest outfile2.ctests"
diff -b outfile1.ctest outfile2.ctest
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

if [ "$stag" != "" ]; then
  mv outfile1.ctest outfile1.ctest${stag}
  mv outfile2.ctest outfile2.ctest${stag}
  mv mkconfig.log mkconfig.log${stag}
  mv mkconfig.cache mkconfig.cache${stag}
  mv mkconfig_c.vars mkconfig_c.vars${stag}
fi


exit $grc
