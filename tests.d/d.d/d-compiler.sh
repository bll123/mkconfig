#!/bin/sh

. $_MKCONFIG_DIR/testfuncs.sh

maindodisplay $1 'D compiler works'
maindoquery $1 $_MKC_ONCE

chkdcompiler
getsname $0
dosetup $@

${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkconfig.sh -d `pwd` \
    -C $_MKCONFIG_RUNTESTDIR/d.env.dat
. ./d.env

> d_compiler.d echo '
int main (char[][] args) { return 0; }
'

${DC} d_compiler.d >&9
rc=$?
if [ $rc -ne 0 ]; then
  grc=$rc;
  echo "## compilation failed"
fi
if [ -x a.out ]; then
  ./a.out
  rc=$?
  if [ $rc -ne 0 ]; then grc=$rc; fi
elif [ -x d_compiler ]; then
  ./d_compiler
  rc=$?
  if [ $rc -ne 0 ]; then grc=$rc; fi
elif [ -x d_compiler.exe ]; then
  ./d_compiler.exe
  rc=$?
  if [ $rc -ne 0 ]; then grc=$rc; fi
else
  echo "## unable to locate executable"
  ls -l >&9
  grc=1
fi

testcleanup

exit $grc
