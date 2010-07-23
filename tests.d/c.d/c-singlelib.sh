#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " w/single lib${EC}"
  exit 0
fi

stag=$1
shift
script=$@

grc=0

CFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${CFLAGS}"
LDFLAGS="-L${_MKCONFIG_TSTRUNTMPDIR} ${LDFLAGS}"
export CFLAGS LDFLAGS

> tst1lib.h echo '

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
extern int tst1lib ();
CPP_EXTERNS_END
'

cat > tst1lib.c <<_HERE_
#include <stdio.h>
#include <stdlib.h>
#include <tst1lib.h>
int tst1lib () { printf ("hello world\n"); return 0; }
_HERE_

${CC} -c ${CFLAGS} ${CPPFLAGS} tst1lib.c
if [ $? -ne 0 ]; then
  echo "compile tst1lib.c failed"
  exit 1
fi
ar cq libtst1lib.a tst1lib.o

case ${script} in
  *mkconfig.sh)
    ${_MKCONFIG_SHELL} ${script} -d `pwd` -C ${_MKCONFIG_RUNTESTDIR}/singlelib.dat
    ;;
  *)
    perl ${script} -C ${_MKCONFIG_RUNTESTDIR}/singlelib.dat
    ;;
esac
case $script in
  *mkconfig.sh)
    ${_MKCONFIG_RUNTOPDIR}/mkreqlib.sh singlelib.ctest
    ;;
esac

sed -e '/^#define _key_/d' -e '/^#define _proto_/d' \
    -e '/^#define _param_/d' singlelib.ctest > t
mv t singlelib.ctest

echo "## diff 1"
diff -b singlelib.ctmp singlelib.ctest
rc=$?
if [ $rc -ne 0 ];then grc=$rc; fi

echo "## diff 2"
diff -b ${_MKCONFIG_RUNTESTDIR}/singlelib.reqlibs mkconfig.reqlibs
rc=$?
if [ $rc -ne 0 ];then grc=$rc; fi

if [ "$stag" != "" ]; then
  mv singlelib.ctest singlelib.ctest${stag}
  mv mkconfig.log mkconfig.log${stag}
  mv mkconfig.cache mkconfig.cache${stag}
  mv mkconfig_c.vars mkconfig_c.vars${stag}
fi

exit $grc
