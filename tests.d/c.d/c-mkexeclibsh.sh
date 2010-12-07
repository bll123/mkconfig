#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " create exec with shared lib${EC}"
  exit 0
fi

if [ "${CC}" = "" ]; then
  echo ${EN} " no cc; skipped${EC}" >&5
  exit 0
fi

stag=$1
shift
script=$@

${_MKCONFIG_DIR}/mkconfig.sh -d `pwd` -C $_MKCONFIG_RUNTESTDIR/c-mkexeclibsh.dat
. ./mkexeclibsh.env

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
  cat > mkct${i}.c <<_HERE_
#include <stdio.h>
#include <stdlib.h>
int mkct${i} () { return ${i}; }
_HERE_
  ${CC} ${CPPFLAGS} ${CFLAGS} ${SHCFLAGS} -c mkct${i}.c
done

i=5
cat > mkct${i}.c <<_HERE_
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
_HERE_
${CC} ${CPPFLAGS} ${CFLAGS} ${SHCFLAGS} -c mkct${i}.c

i=6
cat > mkct${i}.c <<_HERE_
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
_HERE_
${CC} ${CPPFLAGS} ${CFLAGS} ${SHCFLAGS} -c mkct${i}.c

grc=0
${_MKCONFIG_DIR}/mksharedlib.sh -e mkct mkct[51234]${OBJ_EXT}
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

${_MKCONFIG_DIR}/mklink.sh -e mkct6a mkct6${OBJ_EXT} -L. -lmkct
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

./mkct6a
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

exit $rc
