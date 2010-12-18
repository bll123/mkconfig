#!/bin/sh
if [ "$1" = "-d" ]; then
  echo ${EN} " create shared libs w/deps${EC}"
  exit 0
fi

if [ "${CC}" = "" ]; then
  echo ${EN} " no cc; skipped${EC}" >&5
  exit 0
fi

stag=$1
shift
script=$@

${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkconfig.sh -d `pwd` -C $_MKCONFIG_RUNTESTDIR/c-mkshlibmult.dat
. ./mkshlibmult.env

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
cat > mkct${i}.c <<_HERE_
#include <stdio.h>
#include <stdlib.h>
#if defined(__STDC__) || defined(__cplusplus) || defined(c_plusplus)
# define _(x) x
#else
# define _(x) ()
# define void char
#endif

int mkct${i} () { return 1; }
_HERE_
${CC} ${CPPFLAGS} ${CFLAGS} ${SHCFLAGS} -c mkct${i}.c

i=2
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
int mkct${i} () { int i; i = 0;
    i += mkct1(); i += 2;
    return i; }
_HERE_
${CC} ${CPPFLAGS} ${CFLAGS} ${SHCFLAGS} -c mkct${i}.c

i=3
cat > mkct${i}.c <<_HERE_
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
_HERE_
${CC} ${CPPFLAGS} ${CFLAGS} ${SHCFLAGS} -c mkct${i}.c

i=4
cat > mkct${i}.c <<_HERE_
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
_HERE_
${CC} ${CPPFLAGS} ${CFLAGS} ${SHCFLAGS} -c mkct${i}.c

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

extern int mkct4 _((void));
int mkct${i} () { int i; i = 0;
    i += mkct4();
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

${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mksharedlib.sh -e mkct1 mkct1${OBJ_EXT}
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mksharedlib.sh -e mkct2 mkct2${OBJ_EXT} -L. -lmkct1
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mksharedlib.sh -e mkct3 mkct3${OBJ_EXT} -L. -lmkct2
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mksharedlib.sh -e mkct4 mkct4${OBJ_EXT} -L. -lmkct3
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mksharedlib.sh -e mkct5 mkct5${OBJ_EXT} -L. -lmkct4
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

shrunpath=""
if [ "${SHRUNPATH}" != "" ]; then
  shrunpath="${SHRUNPATH}."
fi
cmd="${CC} ${LDFLAGS} ${SHEXECLINK} -o mkct6a${EXE_EXT} mkct6${OBJ_EXT} \
    ${shrunpath} -L. -lmkct5"
echo $cmd
eval $cmd
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

./mkct6a
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

exit $rc
