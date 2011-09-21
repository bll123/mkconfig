#!/bin/sh

. $_MKCONFIG_DIR/testfuncs.sh

maindodisplay $1 member
maindoquery $1 $_MKC_SH_PL

chkccompiler
getsname $0
dosetup $@

> memtst.h echo '
typedef struct xyzzy {
  int       a;
} xyzzy_t;

typedef struct my_struct {
  int       a;
  char      *b;
  void      *c;
  long      d;
  long      *e;
  xyzzy_t   f;
  struct xyzzy g;
} my_struct_t;

typedef union my_union {
  int       a;
  char      *b;
  void      *c;
  long      d;
  long      *e;
  xyzzy_t   f;
  struct xyzzy g;
} my_union_t;
'

CFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${CFLAGS}"
LDFLAGS="-L${_MKCONFIG_TSTRUNTMPDIR} ${LDFLAGS}"
export CFLAGS LDFLAGS

${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkconfig.sh -d `pwd` \
    -C $_MKCONFIG_RUNTESTDIR/c.env.dat
. ./c.env

dorunmkc

for n in a b c d e f g; do
  chkouth "^#define _mem_my_struct_t_${n} 1$"
  chkouth "^#define _mem_struct_my_struct_${n} 1$"
done
for n in g; do
  chkouth "^#define _mem_my_union_t_${n} 1$"
  chkouth "^#define _mem_union_my_union_${n} 1$"
done
chkouthcompile

testcleanup

exit $grc
