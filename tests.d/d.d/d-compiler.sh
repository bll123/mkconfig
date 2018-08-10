#!/bin/sh

. $_MKCONFIG_DIR/bin/testfuncs.sh

maindodisplay $1 'D compiler works'
maindoquery $1 $_MKC_ONCE

chkdcompiler
getsname $0
dosetup $@

${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkconfig.sh -d `pwd` \
    -C $_MKCONFIG_RUNTESTDIR/d.env.dat
. ./d.env

case $DVERSION in
  1|2|3|4)
    ;;
  *)
    grc=1
    ;;
esac
if [ $grc -ne 0 ]; then
  echo "## invalid D version"
fi

if [ $grc -eq 0 ]; then
  > d_compiler.d echo '
int main (char[][] args) { return 0; }
'

  ${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkc.sh -d `pwd` -compile \
      -log mkc_compile.log${stag} -e -c ${DC} \
      -o d_compiler.exe d_compiler.d >&9
  rc=$?
  if [ $rc -ne 0 ]; then
    grc=$rc;
    echo "## compilation failed"
  fi
  if [ -x d_compiler.exe ]; then
    ./d_compiler.exe
    rc=$?
    if [ $rc -ne 0 ]; then grc=$rc; fi
  else
    echo "## unable to locate executable"
    ls -l >&9
    grc=1
  fi
fi

testcleanup

exit $grc
