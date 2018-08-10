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

${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkc.sh -d `pwd` -compile \
    -log mkc_compile.log${stag} -c ${DC} -o mlib2${OBJ_EXT} mlib2.d >&9
if [ $? -ne 0 ]; then
  echo "## compile mlib2.d failed"
  exit 1
fi
test -f libmlib2.a && rm -f libmlib2.a
${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkc.sh -d `pwd` -staticlib \
    -log mkc_compile.log${stag} \
    -o libmlib2.a mlib2${OBJ_EXT} >&9

> mlib1.d echo '
import mlib2;
int mlib1_f () { mlib2_f(); return 0; }
'

${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkc.sh -d `pwd` -compile \
    -log mkc_compile.log${stag} -o mlib1${OBJ_EXT} -c ${DC} mlib1.d >&9
if [ $? -ne 0 ]; then
  echo "compile mlib1.d failed"
  exit 1
fi
test -f libmlib1.a && rm -f libmlib1.a
${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkc.sh -d `pwd` -staticlib \
    -log mkc_compile.log${stag} \
    -o libmlib1.a mlib1${OBJ_EXT} >&9

dorunmkc reqlibs out.d

grep -v SYSTYPE out.d |
    grep -v '^//' |
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
