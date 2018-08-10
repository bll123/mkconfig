#!/bin/sh

. $_MKCONFIG_DIR/bin/testfuncs.sh

maindodisplay $1 'compile shell scripts'
maindoquery $1 $_MKC_SH

getsname $0
dosetup $@

if [ "$_MKCONFIG_SHELL" = "" ]; then
  _MKCONFIG_SHELL=$SHELL
fi
if [ "$_MKCONFIG_SHELL" = "" ]; then
  _MKCONFIG_SHELL=/bin/sh
fi

DASH_N_SUPPORTED=T
# test for -n not supported.
(
  TMPF=chkdashn$$
  rm -f $TMPF $TMPF.out > /dev/null 2>&1
  echo 'while test $# -gt 1; do echo $1; shift; done; exit 1' > $TMPF
  chmod a+rx $TMPF
  cmd="$_MKCONFIG_SHELL -n $TMPF;echo \$? > $TMPF.out"
  eval $cmd &
  job=$!
  sleep 1
  rc=1
  if [ ! -f $TMPF.out ]; then
    kill $job
  else
    rc=`cat $TMPF.out`
  fi
  rm -f $TMPF $TMPF.out > /dev/null 2>&1
  exit $rc
)
rc=$?
if [ $rc -ne 0 ]; then
  DASH_N_SUPPORTED=F
fi

if [ "$DASH_N_SUPPORTED" = F ]; then
  putsnonl "(skip)" >&5
  exit 0
fi

# need globbing on.
set +f

cd $_MKCONFIG_DIR
for f in mkc.sh mkconfig.sh runtests.sh; do
  $_MKCONFIG_SHELL -n $f
  rc=$?
  if [ $rc -ne 0 ];then grc=$rc; fi
done
cd $_MKCONFIG_DIR/bin
for f in *.sh; do
  $_MKCONFIG_SHELL -n $f
  rc=$?
  if [ $rc -ne 0 ];then grc=$rc; fi
done
cd $_MKCONFIG_DIR/units
for f in *.sh; do
  $_MKCONFIG_SHELL -n $f
  rc=$?
  if [ $rc -ne 0 ];then grc=$rc; fi
done
cd $_MKCONFIG_DIR/util
for f in *.sh; do
  $_MKCONFIG_SHELL -n $f
  rc=$?
  if [ $rc -ne 0 ];then grc=$rc; fi
done
cd $_MKCONFIG_DIR/tests.d
for f in *.sh; do
  $_MKCONFIG_SHELL -n $f
  rc=$?
  if [ $rc -ne 0 ];then grc=$rc; fi
done
cd $_MKCONFIG_DIR/tests.d/c.d
for f in *.sh; do
  $_MKCONFIG_SHELL -n $f
  rc=$?
  if [ $rc -ne 0 ];then grc=$rc; fi
done
cd $_MKCONFIG_DIR/tests.d/d.d
for f in *.sh; do
  $_MKCONFIG_SHELL -n $f
  rc=$?
  if [ $rc -ne 0 ];then grc=$rc; fi
done
cd $_MKCONFIG_DIR/tests.d/env.d
for f in *.sh; do
  $_MKCONFIG_SHELL -n $f
  rc=$?
  if [ $rc -ne 0 ];then grc=$rc; fi
done

testcleanup
exit $grc
