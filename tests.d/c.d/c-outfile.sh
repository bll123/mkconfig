#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " multiple output files${EC}"
  exit 0
fi

shift
script=$@

for f in outfile1.ctest outfile2.ctest \
    mkconfig_env.vars mkconfig.log mkconfig.cache; do
  test -f $f && rm -f $f
done
case ${script} in
  *mkconfig.sh)
    ${_MKCONFIG_SHELL} ${script} -d `pwd` -C ${_MKCONFIG_RUNTESTDIR}/env-outfile.dat
    ;;
  *)
    perl ${script} -C ${_MKCONFIG_RUNTESTDIR}/env-outfile.dat
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
  mv mkconfig_env.vars mkconfig_env.vars${stag}
fi

exit $grc
