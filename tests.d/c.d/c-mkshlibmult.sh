#!/bin/sh
if [ "$1" = "-d" ]; then
  echo ${EN} " create shared libs w/deps${EC}"
  exit 0
fi

stag=$1
shift
script=$@

${_MKCONFIG_DIR}/mkconfig.sh -d `pwd` -C $_MKCONFIG_RUNTESTDIR/mkshlibmult.dat
. ./mkshlibmult.env

if [ "${_MKCONFIG_SYSTYPE}" = "BSD" ]; then
  echo ${EN} " skipped${EC}" >&5
  exit 0
fi
if [ "${_MKCONFIG_USING_GCC}" = "N" -a \
    "${_MKCONFIG_SYSTYPE}" = "HP-UX" ]; then
  ${CC} -v 2>&1 | grep 'Bundled'
  rc=$?
  if [ $rc -eq 0 ]; then
    echo ${EN} " skipped${EC}" >&5
    exit 0
  fi
fi


i=1
cat > t${i}.c <<_HERE_
#include <stdio.h>
#include <stdlib.h>
#if defined(__STDC__) || defined(__cplusplus) || defined(c_plusplus)
# define _(x) x
#else
# define _(x) ()
# define void char
#endif

int t${i} () { return 1; }
_HERE_
${CC} ${CPPFLAGS} ${CFLAGS} ${SHCFLAGS} -c t${i}.c

i=2
cat > t${i}.c <<_HERE_
#include <stdio.h>
#include <stdlib.h>
#if defined(__STDC__) || defined(__cplusplus) || defined(c_plusplus)
# define _(x) x
#else
# define _(x) ()
# define void char
#endif

extern int t1 _((void));
int t${i} () { int i; i = 0;
    i += t1(); i += 2;
    return i; }
_HERE_
${CC} ${CPPFLAGS} ${CFLAGS} ${SHCFLAGS} -c t${i}.c

i=3
cat > t${i}.c <<_HERE_
#include <stdio.h>
#include <stdlib.h>
#if defined(__STDC__) || defined(__cplusplus) || defined(c_plusplus)
# define _(x) x
#else
# define _(x) ()
# define void char
#endif

extern int t2 _((void));
int t${i} () { int i; i = 0;
    i += t2(); i += 3;
    return i; }
_HERE_
${CC} ${CPPFLAGS} ${CFLAGS} ${SHCFLAGS} -c t${i}.c

i=4
cat > t${i}.c <<_HERE_
#include <stdio.h>
#include <stdlib.h>
#if defined(__STDC__) || defined(__cplusplus) || defined(c_plusplus)
# define _(x) x
#else
# define _(x) ()
# define void char
#endif

extern int t3 _((void));
int t${i} () { int i; i = 0;
    i += t3(); i += 4;
    return i; }
_HERE_
${CC} ${CPPFLAGS} ${CFLAGS} ${SHCFLAGS} -c t${i}.c

i=5
cat > t${i}.c <<_HERE_
#include <stdio.h>
#include <stdlib.h>
#if defined(__STDC__) || defined(__cplusplus) || defined(c_plusplus)
# define _(x) x
#else
# define _(x) ()
# define void char
#endif

extern int t4 _((void));
int t${i} () { int i; i = 0;
    i += t4();
    return i; }
_HERE_
${CC} ${CPPFLAGS} ${CFLAGS} ${SHCFLAGS} -c t${i}.c

i=6
cat > t${i}.c <<_HERE_
#include <stdio.h>
#include <stdlib.h>
#if defined(__STDC__) || defined(__cplusplus) || defined(c_plusplus)
# define _(x) x
#else
# define _(x) ()
# define void char
#endif

extern int t5 _((void));
main () { int i, j; i = t5(); j = 1; if (i == 10) { j = 0; } return j; }
_HERE_
${CC} ${CPPFLAGS} ${CFLAGS} ${SHCFLAGS} -c t${i}.c

grc=0

${_MKCONFIG_DIR}/mksharedlib.sh -e t1 t1${OBJ_EXT}
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

${_MKCONFIG_DIR}/mksharedlib.sh -e t2 t2${OBJ_EXT} -L. -lt1
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

${_MKCONFIG_DIR}/mksharedlib.sh -e t3 t3${OBJ_EXT} -L. -lt2
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

${_MKCONFIG_DIR}/mksharedlib.sh -e t4 t4${OBJ_EXT} -L. -lt3
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

${_MKCONFIG_DIR}/mksharedlib.sh -e t5 t5${OBJ_EXT} -L. -lt4
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

shrunpath=""
if [ "${SHRUNPATH}" != "" ]; then
  shrunpath="${SHRUNPATH}."
fi
cmd="${CC} ${LDFLAGS} ${SHEXECLINK} -o t6a${EXE_EXT} t6${OBJ_EXT} \
    ${shrunpath} -L. -lt5"
echo $cmd
eval $cmd
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

./t6a
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

exit $rc
