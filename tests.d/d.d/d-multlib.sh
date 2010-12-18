#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " w/multiple libs${EC}"
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
    -C $_MKCONFIG_RUNTESTDIR/d-multlib.env.dat
. ./multlib.env

grc=0

DFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${DFLAGS}"
LDFLAGS="-L${_MKCONFIG_TSTRUNTMPDIR} ${LDFLAGS}"
export DFLAGS LDFLAGS

cat > tst2libc.d <<_HERE_
import std.stdio;
int tst2libc_f () { writeln ("hello world"); return 0; }
_HERE_

${DC} -c ${DFLAGS} ${CPPFLAGS} tst2libc.d
if [ $? -ne 0 ]; then
  echo "compile tst2libc.d failed"
  exit 1
fi
ar cq libtst2libc.a tst2libc${OBJ_EXT}

> tst2libb.d echo '
import tst2libc;
int tst2libb_f () { tst2libc_f(); return 0; }
'

${DC} -c ${DFLAGS} tst2libb.d
if [ $? -ne 0 ]; then
  echo "compile tst2libb.d failed"
  exit 1
fi
ar cq libtst2libb.a tst2libb${OBJ_EXT}

${_MKCONFIG_SHELL} ${script} -d `pwd` -C ${_MKCONFIG_RUNTESTDIR}/d-multlib.dat
${_MKCONFIG_SHELL} ${_MKCONFIG_RUNTOPDIR}/mkreqlib.sh multlib.dtest

echo "## diff 1"
diff -b d-multlib.ctmp multlib.dtest
rc=$?
if [ $rc -ne 0 ];then grc=$rc; fi

echo "## diff 2"
diff -b ${_MKCONFIG_RUNTESTDIR}/d-multlib.reqlibs mkconfig.reqlibs
rc=$?
if [ $rc -ne 0 ];then grc=$rc; fi

if [ "$stag" != "" ]; then
  mv multlib.dtest multlib.dtest${stag}
  mv mkconfig.log mkconfig.log${stag}
  mv mkconfig.cache mkconfig.cache${stag}
  mv mkconfig_d.vars mkconfig_d.vars${stag}
fi

exit $grc
