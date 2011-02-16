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

cat > mlib2.d <<_HERE_
import std.stdio;
int mlib2_f () { writefln ("hello world"); return 0; }
_HERE_

${DC} -c ${DFLAGS} ${CPPFLAGS} mlib2.d
if [ $? -ne 0 ]; then
  echo "compile mlib2.d failed"
  exit 1
fi
test -f libmlib2.a && rm -f libmlib2.a
ar cq libmlib2.a mlib2${OBJ_EXT}

> mlib1.d echo '
import mlib2;
int mlib1_f () { mlib2_f(); return 0; }
'

${DC} -c ${DFLAGS} mlib1.d
if [ $? -ne 0 ]; then
  echo "compile mlib1.d failed"
  exit 1
fi
test -f libmlib1.a && rm -f libmlib1.a
ar cq libmlib1.a mlib1${OBJ_EXT}

${_MKCONFIG_SHELL} ${script} -d `pwd` -C ${_MKCONFIG_RUNTESTDIR}/d-multlib.dat
${_MKCONFIG_SHELL} ${_MKCONFIG_RUNTOPDIR}/mkreqlib.sh multlib.dtest

echo "## diff 1"
grep -v SYSTYPE multlib.dtest | grep -v '^$' |
    sed -e 's/: //' -e 's/{ //' -e 's/ }//' > t
diff -b d-multlib.ctmp t
rc=$?
if [ $rc -ne 0 ];then grc=$rc; fi
rm -f t

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
