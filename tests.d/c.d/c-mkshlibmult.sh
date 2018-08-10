#!/bin/sh

. $_MKCONFIG_DIR/bin/testfuncs.sh

maindodisplay $1 'create shared libs w/deps'
maindoquery $1 $_MKC_SH

chkccompiler
getsname $0
dosetup $@

${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkconfig.sh -d `pwd` -C $_MKCONFIG_RUNTESTDIR/c-shared.env.dat
. ./c.env

if [ "${_MKCONFIG_SYSTYPE}" = "BSD" ]; then
  echo ${EN} " bsd; skipped${EC}" >&5
  exit 0
fi
if [ "${_MKCONFIG_USING_GCC}" = "N" -a \
    "${_MKCONFIG_SYSTYPE}" = "HP-UX" ]; then
  ${CC} -v 2>&1 | grep 'Bundled'
  rc=$?
  if [ $rc -eq 0 ]; then
    echo ${EN} " bundled cc; skipped${EC}" >&5
    exit 0
  fi
fi

i=1
> mkct${i}.c echo "
#include <stdio.h>
#include <stdlib.h>
#if defined(__STDC__) || defined(__cplusplus) || defined(c_plusplus)
# define _(x) x
#else
# define _(x) ()
# define void char
#endif

int mkct${i} () { return 1; }
"
${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkc.sh -d `pwd` -compile -shared \
    -log mkc_compile.log${stag} -e -o mkct${i}${OBJ_EXT} mkct${i}.c

i=2
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
int mkct${i} () { int i; i = 0;
    i += mkct1(); i += 2;
    return i; }
"
${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkc.sh -d `pwd` -compile -shared \
    -log mkc_compile.log${stag} -e -o mkct${i}${OBJ_EXT} mkct${i}.c

i=3
> mkct${i}.c echo "
#include <stdio.h>
#include <stdlib.h>
#if defined(__STDC__) || defined(__cplusplus) || defined(c_plusplus)
# define _(x) x
#else
# define _(x) ()
# define void char
#endif

extern int mkct2 _((void));
int mkct${i} () { int i; i = 0;
    i += mkct2(); i += 3;
    return i; }
"
${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkc.sh -d `pwd` -compile -shared \
    -log mkc_compile.log${stag} -e -o mkct${i}${OBJ_EXT} mkct${i}.c

i=4
> mkct${i}.c echo "
#include <stdio.h>
#include <stdlib.h>
#if defined(__STDC__) || defined(__cplusplus) || defined(c_plusplus)
# define _(x) x
#else
# define _(x) ()
# define void char
#endif

extern int mkct3 _((void));
int mkct${i} () { int i; i = 0;
    i += mkct3(); i += 4;
    return i; }
"
${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkc.sh -d `pwd` -compile -shared \
    -log mkc_compile.log${stag} -e -o mkct${i}${OBJ_EXT} mkct${i}.c

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

extern int mkct4 _((void));
int mkct${i} () { int i; i = 0;
    i += mkct4();
    return i; }
"
${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkc.sh -d `pwd` -compile -shared \
    -log mkc_compile.log${stag} -e -o mkct${i}${OBJ_EXT} -- mkct${i}.c

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
${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkc.sh -d `pwd` -compile -shared \
    -log mkc_compile.log${stag} -e -o mkct${i}${OBJ_EXT} mkct${i}.c

grc=0

${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkc.sh -d `pwd` -link -shared \
    -log mkc_compile.log${stag} \
    -e -o libmkct1${SHLIB_EXT} mkct1${OBJ_EXT} -L.
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkc.sh -d `pwd` -link -shared \
    -log mkc_compile.log${stag} \
    -e -o libmkct2${SHLIB_EXT} mkct2${OBJ_EXT} -L. -lmkct1
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkc.sh -d `pwd` -link -shared \
    -log mkc_compile.log${stag} \
    -e -o libmkct3${SHLIB_EXT} mkct3${OBJ_EXT} -L. -lmkct2
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkc.sh -d `pwd` -link -shared \
    -log mkc_compile.log${stag} \
    -e -o libmkct4${SHLIB_EXT} mkct4${OBJ_EXT} -L. -lmkct3
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkc.sh -d `pwd` -link -shared \
    -log mkc_compile.log${stag} \
    -e -o libmkct5${SHLIB_EXT} mkct5${OBJ_EXT} -L. -lmkct4
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkc.sh -d `pwd` -link -exec \
    -log mkc_compile.log${stag} -e -c ${CC} \
    -o mkct6a${EXE_EXT} -- mkct6${OBJ_EXT} -L. -lmkct5
eval $cmd
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

./mkct6a${EXE_EXT}
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

testcleanup mkct6a${EXE_EXT} \
    mkct1${OBJ_EXT} mkct2${OBJ_EXT} mkct3${OBJ_EXT} \
    mkct4${OBJ_EXT} mkct5${OBJ_EXT} mkct6${OBJ_EXT} \
    mkct1.c mkct2.c mkct3.c mkct4.c mkct5.c mkct6.c

exit $grc
