#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " create static library${EC}"
  exit 0
fi

stag=$1
shift
script=$@

${_MKCONFIG_DIR}/mkconfig.sh -d `pwd` -C $_MKCONFIG_RUNTESTDIR/mkstaticlib.dat
. ./mkstaticlib.env

for i in 1 2 3 4; do
  cat > t${i}.c <<_HERE_
#include <stdio.h>
#include <stdlib.h>
int t${i} () { return ${i}; }
_HERE_
  ${CC} ${CPPFLAGS} ${CFLAGS} -c t${i}.c
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

extern int t1 _((void));
extern int t2 _((void));
extern int t3 _((void));
extern int t4 _((void));
int t${i} () { int i; i = 0;
    i += t1(); i += t2(); i += t3(); i += t4();
    return i; }
_HERE_
${CC} ${CPPFLAGS} ${CFLAGS} -c t${i}.c

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
extern int t5 _((void));
main () { int i, j; i = t5(); j = 1; if (i == 10) { j = 0; } return j; }
_HERE_
${CC} ${CPPFLAGS} ${CFLAGS} -c t${i}.c

grc=0
${_MKCONFIG_DIR}/mkstaticlib.sh t t[51234]${OBJ_EXT}
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

ar t libt.a
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

${CC} ${LDFLAGS} -o t6a${EXE_EXT} t6${OBJ_EXT} libt.a
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

./t6a${EXE_EXT}
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

${CC} ${LDFLAGS} -o t6b${EXE_EXT} t6${OBJ_EXT} -L. -lt
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

./t6b${EXE_EXT}
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

exit $rc
