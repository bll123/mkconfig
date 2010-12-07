#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " need prototype${EC}"
  exit 0
fi

if [ "${CC}" = "" ]; then
  echo ${EN} " no cc; skipped${EC}" >&5
  exit 0
fi

stag=$1
shift
script=$@

grc=0

CFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${CFLAGS}"
LDFLAGS="-L${_MKCONFIG_TSTRUNTMPDIR} ${LDFLAGS}"
export CFLAGS LDFLAGS

> nptlib.h echo '

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
/* extern int npt1lib (); */
extern int npt2lib _((void));
CPP_EXTERNS_END
'

cat > nptlib.c <<_HERE_
#include <stdio.h>
#include <stdlib.h>
#include <nptlib.h>
int npt1lib () { printf ("hello world\n"); return 0; }
int npt2lib () { printf ("hello world\n"); return 0; }
_HERE_

${CC} -c ${CFLAGS} ${CPPFLAGS} nptlib.c
if [ $? -ne 0 ]; then
  echo "compile nptlib.c failed"
  exit 1
fi
ar cq libnptlib.a nptlib.o

case ${script} in
  *mkconfig.sh)
    ${_MKCONFIG_SHELL} ${script} -d `pwd` -C ${_MKCONFIG_RUNTESTDIR}/c-npt.dat
    ;;
  *)
    perl ${script} -C ${_MKCONFIG_RUNTESTDIR}/c-npt.dat
    ;;
esac
grep "^#define _npt_npt1lib 1$" npt.ctest
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi
grep "^#define _npt_npt2lib 0$" npt.ctest
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

if [ "$stag" != "" ]; then
  mv npt.ctest npt.ctest${stag}
  mv mkconfig.log mkconfig.log${stag}
  mv mkconfig.cache mkconfig.cache${stag}
  mv mkconfig_c.vars mkconfig_c.vars${stag}
fi

exit $grc
