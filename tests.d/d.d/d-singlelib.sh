#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " w/single lib${EC}"
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
    -C $_MKCONFIG_RUNTESTDIR/d.env.dat
. ./d.env

grc=0

DFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${DFLAGS}"
LDFLAGS="-L${_MKCONFIG_TSTRUNTMPDIR} ${LDFLAGS}"
export DFLAGS LDFLAGS

cat > slib1.d <<_HERE_
int slib1_f () { return 0; }
_HERE_

${DC} -c ${DFLAGS} slib1.d
if [ $? -ne 0 ]; then
  echo "## compile slib1.d failed"
  exit 1
fi
test -f libslib1.a && rm -f libslib1.a
ar cq libslib1.a slib1${OBJ_EXT}

${_MKCONFIG_SHELL} ${script} -d `pwd` -C ${_MKCONFIG_RUNTESTDIR}/d-singlelib.dat
${_MKCONFIG_SHELL} ${_MKCONFIG_RUNTOPDIR}/mkreqlib.sh singlelib.dtest

echo "## diff 1"
grep -v 'SYSTYPE' singlelib.dtest |
    grep -v 'D_VERSION' |
    grep -v '_d_tango_lib' |
    grep -v 'alias char.. string;' |
    grep -v '_type_string' |
    grep -v '^import std.*string' |
    grep -v '_import_std.*string' |
    grep -v '^$' |
    sed -e 's/: //' -e 's/{ //' -e 's/ }//' > t
diff -b d-singlelib.ctmp t
rc=$?
if [ $rc -ne 0 ];then grc=$rc; fi
rm -f t

echo "## diff 2"
diff -b ${_MKCONFIG_RUNTESTDIR}/d-singlelib.reqlibs mkconfig.reqlibs
rc=$?
if [ $rc -ne 0 ];then grc=$rc; fi

if [ "$stag" != "" ]; then
  mv singlelib.dtest singlelib.dtest${stag}
  mv mkconfig.log mkconfig.log${stag}
  mv mkconfig.cache mkconfig.cache${stag}
  mv mkconfig_d.vars mkconfig_d.vars${stag}
fi

exit $grc
