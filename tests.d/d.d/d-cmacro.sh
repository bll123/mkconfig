#!/bin/sh

. $_MKCONFIG_DIR/bin/testfuncs.sh

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

typedef struct DP DP;
struct DP {
  int length;
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
#define T10(rh, proc, xargs, argsp, xres, resp, secs) \
        ((*(rh)->cl_ops->cl_call)(rh, proc, xargs, \
            argsp, xres, resp, secs))
#define T_11(dp) ((dp)->length)
#define T12 ((DP *) 1)  // test with cast of non basic type

#if 0
# define T13 1
#else
# define T13 2
#endif

#if 1
# define T14 1
#else
# define T14 2
#endif

#define BLAH 1
#if BLAH
# define T15 1
#else
# define T15 2
#endif

#define BAR 0
#if BAR
# define T16 1
#else
# define T16 2
#endif

#if AA  // from cflags
# define T17 1
#else
# define T17 2
#endif

#if BB  // from cflags
# define T18 1
#else
# define T18 2
#endif

#if CC  // from cflags
# define T19 1
#else
# define T19 2
#endif

#define DD1 1
#define DD2 1
#define DD3 0
#define DD4 0
#if DD1 && DD2
# define T20 1
#else
# define T20 2
#endif
#if DD1 && DD3
# define T21 1
#else
# define T21 2
#endif
#if DD1 || DD2
# define T22 1
#else
# define T22 2
#endif
#if DD1 || DD3
# define T23 1
#else
# define T23 2
#endif
#if ! DD1
# define T24 1
#else
# define T24 2
#endif
#if ! DD3
# define T25 1
#else
# define T25 2
#endif
#if DD1 && DD2 || DD3  // no precedence, should be true
# define T26 1
#else
# define T26 2
#endif
#if DD1 && DD3 || DD2
# define T27 1
#else
# define T27 2
#endif
#if DD1 && DD3 || DD4  // no precedence, should be false
# define T28 1
#else
# define T28 2
#endif

#endif
'

CFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${CFLAGS} -DAA -DBB=1 -DCC=0 "
DFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${DFLAGS}"
LDFLAGS="-L${_MKCONFIG_TSTRUNTMPDIR} ${LDFLAGS}"
export CFLAGS DFLAGS LDFLAGS

${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkconfig.sh -d `pwd` \
    -C $_MKCONFIG_RUNTESTDIR/d.env.dat
. ./d.env

dorunmkc

for x in T0 T1 T2 T3 T4 T5 T6 T7 T8 T9 T10 T_11 T12 \
    T13 T14 T15 T16 T17 T18 T19 T20 T21 T22 T23 T24 T25 T26 T27 T28; do
  chkoutd "^enum (: )?bool ({ )?_cmacro_${x} = true( })?;$"
done

for x in T0 T1 T2 T3 T5 T7 T9 T10 T_11 T12; do
  chkoutd "^(auto|int) C_MACRO_${x}"
done

for x in T14 T15 T17 T18 T20 T22 T23 T25 T26 T27; do
  chkoutd "^(auto|int) C_MACRO_${x} \(\) { return 1; }"
done

for x in T13 T16 T19 T21 T24 T28; do
  chkoutd "^(auto|int) C_MACRO_${x} \(\) { return 2; }"
done

for x in T4 ; do
  chkoutd "^(auto|string) C_MACRO_${x}"
done

for x in T6 T8 ; do
  chkoutd "^(auto|uint) C_MACRO_${x}"
done

for x in T12 ; do
  chkoutd "^(auto|DP [*]) C_MACRO_${x}"
done

if [ $grc -eq 0 ]; then
  chkdcompile out.d
fi

testcleanup

exit $grc
