#!/bin/sh

. $_MKCONFIG_DIR/bin/testfuncs.sh

maindodisplay $1 'create exec with shared libs'
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

for i in 1 2 3 4; do
  > mkct${i}.c echo "
#include <stdio.h>
#include <stdlib.h>
int mkct${i} () { return ${i}; }
"
  ${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkc.sh -d `pwd` -compile -shared \
      -log mkc_compile.log${stag} -o mkct${i}${OBJ_EXT} -e mkct${i}.c
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
${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkc.sh -d `pwd` -compile -shared \
    -log mkc_compile.log${stag} -e -o mkct${i}${OBJ_EXT} mkct${i}.c

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
set +f
${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkc.sh -d `pwd` -link -shared \
    -log mkc_compile.log${stag} \
    -e -o libmkct${SHLIB_EXT} mkct[51234]${OBJ_EXT}
set -f
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkc.sh -d `pwd` -link -exec \
    -log mkc_compile.log${stag} -e \
    -o mkct6a.exe -- mkct6${OBJ_EXT} -L. -lmkct
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

LD_LIBRARY_PATH=. ./mkct6a.exe
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

testcleanup mkct6a.exe mkct1.o mkct2.o mkct3.o mkct4.o mkct5.o mkct6.o \
    mkct1.c mkct2.c mkct3.c mkct4.c mkct5.c mkct6.c

exit $grc
