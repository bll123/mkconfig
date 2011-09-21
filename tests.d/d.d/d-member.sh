#!/bin/sh

. $_MKCONFIG_DIR/testfuncs.sh

maindodisplay $1 member
maindoquery $1 $_MKC_SH

chkdcompiler
getsname $0
dosetup $@

DFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${DFLAGS}"
LDFLAGS="-L${_MKCONFIG_TSTRUNTMPDIR} ${LDFLAGS}"
export DFLAGS LDFLAGS

> memtst.d echo '
struct xyzzy {
  int       a;
}

struct my_struct {
  int          a;
  char *       b;
  void *       c;
  long         d;
  long *       e;
  xyzzy        f;
}
'

${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkconfig.sh -d `pwd` \
    -C $_MKCONFIG_RUNTESTDIR/d.env.dat
. ./d.env

dorunmkc

for n in a b c d e f; do
  chkoutd "^enum (: )?bool ({ )?_mem_my_struct_${n} = true( })?;$"
done

if [ $grc -eq 0 ]; then
  chkdcompile out.d
fi

testcleanup

exit $grc
