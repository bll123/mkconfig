#!/bin/sh

. $_MKCONFIG_DIR/testfuncs.sh

maindodisplay $1 c-macro
maindoquery $1 $_MKC_SH

chkdcompiler
getsname $0
dosetup $@

> macrohdr.h echo '
#ifndef _INC_MACROHDR_H_
#define _INC_MACROHDR_H_

struct b {
   int a;
   int b;
};
typedef struct CL CL;
struct CL {
   struct clnt_ops {
     int (*cl_call)(CL *, int, int, int, int, int, struct b);
   } *cl_ops;
};

#define T0 2
#define T1(a) ((a)+1)
#define T2(a, b) ((a)+(b)+1)
#define T3(a,b,c) ((a)+(b)+(c))
# define T4(args) (args)
#define T5 (3)
#    define   T6(a , b , c) ((a)*(b)*(c))
/* tabs, ->, multi-line (was clnt_call) */
#define	T7(rh, proc, xargs, argsp, xres, resp, secs)	\
	((*(rh)->cl_ops->cl_call)(rh, proc, xargs, argsp, xres, resp, secs))
#    define   T8( a , b , c ) ((a)*(b)*(c))
#define T9(cmd, type)  (((cmd) << 8) | ((type) & 0x0f))

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

for x in T0 T1 T2 T3 T4 T5 T6 T7 T8 T9 ; do
  chkoutd "^enum (: )?bool ({ )?_cmacro_${x} = true( })?;$"
done

for x in T0 T1 T2 T3 T5 T7 T9 ; do
  chkoutd "^(auto|int) C_MACRO_${x}"
done

for x in T4 ; do
  chkoutd "^(auto|string) C_MACRO_${x}"
done

for x in T6 T8 ; do
  chkoutd "^(auto|uint) C_MACRO_${x}"
done

if [ $grc -eq 0 ]; then
  chkdcompile out.d
fi

testcleanup

exit $grc
