#!/bin/sh

. $_MKCONFIG_DIR/testfuncs.sh

maindodisplay $1 'w/single lib'
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

dorunmkc reqlibs out.d

grep -v 'SYSTYPE' out.d |
    grep -v 'D_VERSION' |
    grep -v '_d_tango_lib' |
    grep -v 'alias char.. string;' |
    grep -v '_type_string' |
    grep -v '^import std.*string' |
    grep -v '_import_std.*string' |
    grep -v '^$' |
    sed -e 's/: //' -e 's/{ //' -e 's/ }//' > out.d.n
chkdiff d-singlelib.ctmp out.d.n

chkdiff ${_MKCONFIG_RUNTESTDIR}/d-singlelib.reqlibs mkconfig.reqlibs

testcleanup out.d.n

exit $grc
