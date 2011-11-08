#!/bin/sh

. $_MKCONFIG_DIR/bin/testfuncs.sh

maindodisplay $1 'w/multiple libs'
maindoquery $1 $_MKC_SH

chkdcompiler
getsname $0
dosetup $@

CFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${DFLAGS}"
DFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${DFLAGS}"
LDFLAGS="-L${_MKCONFIG_TSTRUNTMPDIR} ${LDFLAGS}"
export CFLAGS DFLAGS LDFLAGS

${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkconfig.sh -d `pwd` \
    -C $_MKCONFIG_RUNTESTDIR/d.env.dat
. ./d.env

> mlib2.d echo '
int mlib2_f () { return 0; }
'

${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkc.sh -d `pwd` -comp -c ${DC} mlib2.d >&9
if [ $? -ne 0 ]; then
  echo "## compile mlib2.d failed"
  exit 1
fi
test -f libmlib2.a && rm -f libmlib2.a
${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkc.sh -d `pwd` \
    -staticlib libmlib2 mlib2${OBJ_EXT} >&9

> mlib1.d echo '
import mlib2;
int mlib1_f () { mlib2_f(); return 0; }
'

${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkc.sh -d `pwd` -comp -c ${DC} mlib1.d >&9
if [ $? -ne 0 ]; then
  echo "compile mlib1.d failed"
  exit 1
fi
test -f libmlib1.a && rm -f libmlib1.a
${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkc.sh -d `pwd` \
    -staticlib libmlib1 mlib1${OBJ_EXT} >&9

dorunmkc reqlibs out.d

grep -v SYSTYPE out.d |
    grep -v 'D_VERSION' |
    grep -v '_d_tango_lib' |
    grep -v 'alias char.. string;' |
    grep -v '_type_string' |
    grep -v '^import std.*string' |
    grep -v '_import_std.*string' |
    grep -v '^$' |
    sed -e 's/: //' -e 's/{ //' -e 's/ }//' > out.d.n
chkdiff d-multlib.ctmp out.d.n

chkdiff ${_MKCONFIG_RUNTESTDIR}/d-multlib.reqlibs mkconfig.reqlibs

if [ $grc -eq 0 ]; then
  chkdcompile out.d
fi

testcleanup out.d.n

exit $grc


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
    -C $_MKCONFIG_RUNTESTDIR/d.env.dat
. ./d.env

grc=0

DFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${DFLAGS}"
LDFLAGS="-L${_MKCONFIG_TSTRUNTMPDIR} ${LDFLAGS}"
export DFLAGS LDFLAGS

> mlib2.d echo '
int mlib2_f () { return 0; }
'

${DC} -c ${DFLAGS} ${CPPFLAGS} mlib2.d
if [ $? -ne 0 ]; then
  echo "## compile mlib2.d failed"
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
${_MKCONFIG_SHELL} ${_MKCONFIG_RUNTOPDIR}/bin/mkc.sh -d `pwd` -reqlib out.d >&9

echo "## diff 1"
grep -v SYSTYPE multlib.dtest |
    grep -v 'D_VERSION' |
    grep -v '_d_tango_lib' |
    grep -v 'alias char.. string;' |
    grep -v '_type_string' |
    grep -v '^import std.*string' |
    grep -v '_import_std.*string' |
    grep -v '^$' |
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
