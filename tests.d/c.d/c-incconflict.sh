#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " include conflict${EC}"
  exit 0
fi

stag=$1
shift
script=$@

grc=0

CFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${CFLAGS}"
LDFLAGS="-L${_MKCONFIG_TSTRUNTMPDIR} ${LDFLAGS}"
export CFLAGS LDFLAGS

> incconf1.h echo '

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
extern int incconf1 ();
CPP_EXTERNS_END
'
> incconf2.h echo '

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
extern char *incconf1 ();
CPP_EXTERNS_END
'
> incconf3.h echo '

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
extern int incconf1 ();
CPP_EXTERNS_END
'

case ${script} in
  *mkconfig.sh)
    ${_MKCONFIG_SHELL} ${script} -d `pwd` -C ${_MKCONFIG_RUNTESTDIR}/incconflict.dat
    ;;
  *)
    perl ${script} -C ${_MKCONFIG_RUNTESTDIR}/incconflict.dat
    ;;
esac
grep "^#define _inc_conflict__hdr_incconf1__hdr_incconf2 0$" incconflict.ctest
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi
grep "^#define _inc_conflict__hdr_incconf1__hdr_incconf3 1$" incconflict.ctest
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

if [ "$stag" != "" ]; then
  mv incconflict.ctest incconflict.ctest${stag}
  mv mkconfig.log mkconfig.log${stag}
  mv mkconfig.cache mkconfig.cache${stag}
  mv mkconfig_c.vars mkconfig_c.vars${stag}
fi

exit $grc
