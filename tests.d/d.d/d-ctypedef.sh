#!/bin/sh

. $_MKCONFIG_DIR/bin/testfuncs.sh

maindodisplay $1 c-typedef
maindoquery $1 $_MKC_SH

chkdcompiler
getsname $0
dosetup $@

> typedefhdr.h echo '
#ifndef _INC_TYPEDEFHDR_H_
#define _INC_TYPEDEFHDR_H_

typedef unsigned char a;
typedef unsigned short int b;
typedef unsigned int c;
typedef unsigned long int d;
typedef signed char e;
typedef unsigned char f;
typedef signed short int g;
typedef unsigned short int h;
typedef signed int i;
#if __GNUC__
__extension__ typedef signed long long int j;
__extension__ typedef unsigned long long int k;
__extension__ typedef void * l;
#endif
typedef void *m;
struct ns { int n; };
typedef struct ns n;
typedef struct { int o; } o_t;
typedef o_t o;  // typedef of typedef
typedef o p;    // typedef of typedef
typedef void *q;  // with semi ; in comment
typedef int *r;   /* semi ; in comment */
typedef int * (s) (int s1);
typedef struct ns *t;
typedef void (u)(int u1);
typedef int*(v) (int v1);
// multiline
typedef int (w) (int w1,
	int *w2, int w3);
typedef int (*x) (int *, void *,...);
// multiline
typedef int yyy (int *a, int b, int *c, int d, int *const e[])

                             ;

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

if [ "${_MKCONFIG_USING_GCC}" = "Y" ]; then
  for x in j k l; do
    chkoutd "^enum (: )?bool ({ )?_ctypedef_${x} = true( })?;$"
    chkoutd "alias.*[ \*]${x};$"
  done
fi

for x in a b c d e f g h i m n o p q r t u v w x yyy; do
  chkoutd "^enum (: )?bool ({ )?_ctypedef_${x} = true( })?;$"
  chkoutd "alias.*[ \*]${x};$"
done

if [ $grc -eq 0 ]; then
  chkdcompile out.d
fi

testcleanup

exit $grc
