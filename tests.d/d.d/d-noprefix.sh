#!/bin/sh

. $_MKCONFIG_DIR/bin/testfuncs.sh

maindodisplay $1 noprefix
maindoquery $1 $_MKC_SH

chkdcompiler
getsname $0
dosetup $@

> noprefixhdr.h echo '
#ifndef _INC_NOPREFIXHDR_H_
#define _INC_NOPREFIXHDR_H_

struct b {
   int a;
   int b;
};
#define T3(a,b,c) ((a)+(b)+(c))
union ub
{
  long double  b;
  float b1;
  double  b2;
  long double  b3;
};
typedef enum {
    TCL_INT, TCL_DOUBLE, TCL_EITHER, TCL_WIDE_INT
} Tcl_ValueType;
typedef enum Tcl_PathType {
    TCL_PATH_ABSOLUTE,
    TCL_PATH_RELATIVE,
    TCL_PATH_VOLUME_RELATIVE
} Tcl_PathType;
typedef long int o;

#endif
'

CFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${CFLAGS}"
DFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${DFLAGS}"
LDFLAGS="-L${_MKCONFIG_TSTRUNTMPDIR} ${LDFLAGS}"
export CFLAGS DFLAGS LDFLAGS

${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkconfig.sh -d `pwd` \
    -C $_MKCONFIG_RUNTESTDIR/d.env.dat
. ./d.env

dorunmkc

chkoutd "^struct b *$"
chkoutd "^struct C_ST_b *$" neg
chkoutd "^union ub *$"
chkoutd "^union C_UN_ub *$" neg
chkoutd "^enum Tcl_ValueType *$"
chkoutd "^enum C_ENUM_Tcl_ValueType *$" neg
chkoutd "^enum Tcl_PathType *$"
chkoutd "^enum C_ENUM_Tcl_PathType *$" neg
chkoutd "^alias Tcl_ValueType" neg
chkoutd "^alias Tcl_PathType" neg
chkoutd "^enum (: )?bool ({ )?_cmacro_T3 = true( })?; *$"
chkoutd "^(auto|int) T3\(int a, int b, int c\) { return .*; } *$"
chkoutd "^alias (int|long) o;$"

if [ $grc -eq 0 ]; then
  chkdcompile out.d
fi

testcleanup

exit $grc
