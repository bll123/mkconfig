#!/bin/sh

. $_MKCONFIG_DIR/bin/testfuncs.sh

maindodisplay $1 'create static library'
maindoquery $1 $_MKC_SH

chkccompiler
getsname $0
dosetup $@

${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkconfig.sh -d `pwd` \
    -C $_MKCONFIG_RUNTESTDIR/c.env.dat
. ./c.env

for i in 1 2 3 4; do
  > mkct${i}.c echo "
#include <stdio.h>
#include <stdlib.h>
int mkct${i} () { return ${i}; }
"
  ${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkc.sh -d `pwd` -comp -e -o mkct${i}${OBJ_EXT} mkct${i}.c
done

i=5
> mkct${i}.c echo "
#include <stdio.h>
#include <stdlib.h>
#if defined(__STDC__) || defined(__cplusplus) || defined(c_plusplus)
# define _(x) x
#else
# define _(x) ()
# define void char
#endif

extern int mkct1 _((void));
extern int mkct2 _((void));
extern int mkct3 _((void));
extern int mkct4 _((void));
int mkct${i} () { int i; i = 0;
    i += mkct1(); i += mkct2(); i += mkct3(); i += mkct4();
    return i; }
"
${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkc.sh -d `pwd` -comp -e -o mkct${i}${OBJ_EXT} mkct${i}.c

i=6
> mkct${i}.c echo '
#include <stdio.h>
#include <stdlib.h>
#if defined(__STDC__) || defined(__cplusplus) || defined(c_plusplus)
# define _(x) x
#else
# define _(x) ()
# define void char
#endif
extern int mkct5 _((void));
main () { int i, j; i = mkct5(); j = 1; if (i == 10) { j = 0; } return j; }
'
${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkc.sh -d `pwd` -comp -e -o mkct${i}${OBJ_EXT} mkct${i}.c

grc=0
set +f
${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkc.sh -d `pwd` -staticlib \
    -e mkct mkct[51234]${OBJ_EXT}
set -f
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

ar t libmkct.a
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkc.sh -d `pwd` -link -e -c ${CC} \
    -o mkct6a${EXE_EXT} -- mkct6${OBJ_EXT} libmkct.a
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

./mkct6a${EXE_EXT}
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkc.sh -d `pwd` -link -e -c ${CC} \
    -o mkct6b${EXE_EXT} -- mkct6${OBJ_EXT} -L. -lmkct
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

./mkct6b${EXE_EXT}
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

testcleanup mkct6a${EXE_EXT} mkct6b${EXE_EXT} \
    mkct1${OBJ_EXT} mkct2${OBJ_EXT} mkct3${OBJ_EXT} \
    mkct4${OBJ_EXT} mkct5${OBJ_EXT} mkct6${OBJ_EXT} \
    mkct1.c mkct2.c mkct3.c mkct4.c mkct5.c mkct6.c

exit $grc
