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
  cat > mkct${i}.c <<_HERE_
#include <stdio.h>
#include <stdlib.h>
int mkct${i} () { return ${i}; }
_HERE_
  ${CC} ${CPPFLAGS} ${CFLAGS} -c mkct${i}.c
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
${CC} ${CPPFLAGS} ${CFLAGS} -c mkct${i}.c

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
${CC} ${CPPFLAGS} ${CFLAGS} -c mkct${i}.c

grc=0
${_MKCONFIG_DIR}/mkstaticlib.sh -e mkct mkct[51234]${OBJ_EXT}
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

ar t libmkct.a
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

${CC} ${LDFLAGS} -o mkct6a${EXE_EXT} mkct6${OBJ_EXT} libmkct.a
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

./mkct6a${EXE_EXT}
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

${CC} ${LDFLAGS} -o mkct6b${EXE_EXT} mkct6${OBJ_EXT} -L. -lmkct
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

./mkct6b${EXE_EXT}
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

exit $rc
