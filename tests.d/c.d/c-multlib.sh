#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " w/multiple libs${EC}"
  exit 0
fi

script=$@

grc=0

CFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${CFLAGS}"
LDFLAGS="-L${_MKCONFIG_TSTRUNTMPDIR} ${LDFLAGS}"
export CFLAGS LDFLAGS

> tst2libb.h echo '

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
extern int tst2libb ();
CPP_EXTERNS_END
'
> tst2libc.h echo '

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
extern int tst2libc ();
CPP_EXTERNS_END
'

> tst2libb.c echo '
#include <stdio.h>
#include <stdlib.h>
#include <tst2libb.h>
#include <tst2libc.h>
int tst2libb () { tst2libc(); return 0; }
'

${CC} -c ${CFLAGS} ${CPPFLAGS} tst2libb.c
if [ $? -ne 0 ]; then
  echo "compile tst2libb.c failed"
  exit 1
fi
ar cq libtst2libb.a tst2libb.o

cat > tst2libc.c <<_HERE_
#include <stdio.h>
#include <stdlib.h>
#include <tst2libc.h>
int tst2libc () { printf ("hello world\n"); return 0; }
_HERE_

${CC} -c ${CFLAGS} ${CPPFLAGS} tst2libc.c
if [ $? -ne 0 ]; then
  echo "compile tst2libb.c failed"
  exit 1
fi
ar cq libtst2libc.a tst2libc.o

${script} -C ${_MKCONFIG_RUNTESTDIR}/multlib.dat
case $script in
  *mkconfig.sh)
    ${_MKCONFIG_RUNTOPDIR}/mkreqlib.sh multlib.ctest
    ;;
esac

sed -e '/^#define _key_/d' -e '/^#define _proto_/d' \
    -e '/^#define _param_/d' multlib.ctest > t
mv t multlib.ctest

echo "## diff 1"
diff -b multlib.ctmp multlib.ctest
rc=$?
if [ $rc -ne 0 ];then grc=$rc; fi

echo "## diff 2"
diff -b ${_MKCONFIG_RUNTESTDIR}/multlib.reqlibs reqlibs.txt
rc=$?
if [ $rc -ne 0 ];then grc=$rc; fi

if [ "$stag" != "" ]; then
  mv multlib.ctest multlib.ctest${stag}
  mv mkconfig.log mkconfig.log${stag}
  mv mkconfig.cache mkconfig.cache${stag}
  mv mkconfig_c.vars mkconfig_c.vars${stag}
fi

exit $grc
