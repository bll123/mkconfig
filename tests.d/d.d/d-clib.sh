#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " c library${EC}"
  exit 0
fi

if [ "${DC}" = "" ]; then
  echo ${EN} " no D compiler; skipped${EC}" >&5
  exit 0
fi

stag=$1
shift
script=$@

${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkconfig.sh -d `pwd` \
    -C $_MKCONFIG_RUNTESTDIR/d-clib.env.dat
. ./clib.env

grc=0

${_MKCONFIG_SHELL} ${script} -d `pwd` -C ${_MKCONFIG_RUNTESTDIR}/d-clib.dat

echo "## diff 1"
grep -v SYSTYPE dclib.d |
    grep -v 'D_VERSION' |
    grep -v '_d_tango_lib' |
    grep -v '_csiz_' |
    grep -v 'alias char.. string;' |
    grep -v '_type_string' |
    grep -v '^import std.*string' |
    grep -v '_import_std.*string' |
    grep -v '^$' |
    sed -e 's/: //' -e 's/{ //' -e 's/ }//' > t
diff -b d-clib.ctmp t
rc=$?
if [ $rc -ne 0 ];then grc=$rc; fi
rm -f t

if [ $grc -eq 0 ]; then
  ${DC} -c ${DFLAGS} dclib.d
  if [ $? -ne 0 ]; then
    echo "## compile dclib.d failed"
    grc=1
  fi
fi

if [ "$stag" != "" ]; then
  mv dclib.d dclib.d${stag}
  mv mkconfig.log mkconfig.log${stag}
  mv mkconfig.cache mkconfig.cache${stag}
  mv mkconfig_d.vars mkconfig_d.vars${stag}
fi

exit $grc
