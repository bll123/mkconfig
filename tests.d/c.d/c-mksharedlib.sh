#!/bin/sh
if [ "$1" = "-d" ]; then
  echo ${EN} " create shared library${EC}"
  exit 0
fi

stag=$1
shift
script=$@

${_MKCONFIG_DIR}/mkconfig.sh -d `pwd` -C $_MKCONFIG_RUNTESTDIR/mksharedlib.dat
. ./mksharedlib.env

for i in 1 2 3 4; do
  cat > t${i}.c <<_HERE_
#include <stdio.h>
#include <stdlib.h>
int t${i} () { return ${i}; }
_HERE_
  ${CC} ${CPPFLAGS} ${CFLAGS} ${SHCFLAGS} -c t${i}.c
done

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
#if defined(__cplusplus) || defined (c_plusplus)
# define CPP_EXTERNS_BEG extern "C" {
# define CPP_EXTERNS_END }
CPP_EXTERNS_BEG
extern int printf (const char *, ...);
CPP_EXTERNS_END
#else
# define CPP_EXTERNS_BEG
# define CPP_EXTERNS_END
#endif

CPP_EXTERNS_BEG
extern int t1 _((void));
extern int t2 _((void));
extern int t3 _((void));
extern int t4 _((void));
CPP_EXTERNS_END
int t${i} () { int i; i = 0;
    i += t1(); i += t2(); i += t3(); i += t4();
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
#if defined(__cplusplus) || defined (c_plusplus)
# define CPP_EXTERNS_BEG extern "C" {
# define CPP_EXTERNS_END }
CPP_EXTERNS_BEG
extern int printf (const char *, ...);
CPP_EXTERNS_END
#else
# define CPP_EXTERNS_BEG
# define CPP_EXTERNS_END
#endif

CPP_EXTERNS_BEG
extern int t5 _((void));
CPP_EXTERNS_END
main () { int i, j; i = t5(); j = 1; if (i == 10) { j = 0; } return j; }
_HERE_
${CC} ${CPPFLAGS} ${CFLAGS} ${SHCFLAGS} -c t${i}.c

grc=0
${_MKCONFIG_DIR}/mksharedlib.sh t t[51234]${OBJ_EXT}
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

shrunpath=""
if [ "${SHRUNPATH}" != "" ]; then
  shrunpath="${SHRUNPATH}."
fi
${CC} ${LDFLAGS} ${SHEXECLINK} -o t6a${EXE_EXT} t6${OBJ_EXT} ${shrunpath} -L. -lt
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

./t6a
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

exit $rc
