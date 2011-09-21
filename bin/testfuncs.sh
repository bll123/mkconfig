#!/bin/sh
#
# $Id$
# $Revision$
#
# Copyright 2011 Brad Lanam Walnut Creek, CA, USA
#

maindodisplay () {
  snm=$2
  if [ "$1" = "-d" ]; then
    echo $snm
    exit 0
  fi
}

maindoquery () {
  if [ "$1" = "-q" ]; then
    exit $2
  fi
}

chkccompiler () {
  if [ "${CC}" = "" ]; then
    echo ${EN} " no C compiler; skipped${EC}" >&5
    exit 0
  fi
}

chkdcompiler () {
  if [ "${DC}" = "" ]; then
    echo ${EN} " no D compiler; skipped${EC}" >&5
    exit 0
  fi
}

getsname () {
  tsnm=$1
  tsnm=`echo $tsnm | sed -e 's,.*/,,' -e 's,\.sh$,,'`
  scriptnm=${tsnm}
}

dosetup () {
  grc=0
  stag=$1
  shift
  script=$@
  set -f
}

dorunmkc () {
  drmclear="-C"
  if [ "$1" = "-nc" ];then
    drmclear=""
    shift
  fi
  case ${script} in
    *mkconfig.sh)
      ${_MKCONFIG_SHELL} ${script} -d `pwd` \
          ${drmclear} ${_MKCONFIG_RUNTESTDIR}/${scriptnm}.dat
      ;;
    *)
      perl ${script} ${drmclear} ${_MKCONFIG_RUNTESTDIR}/${scriptnm}.dat
      ;;
  esac
  if [ "$1" = "reqlibs" ]; then
    case $script in
      *mkconfig.sh)
        ${_MKCONFIG_SHELL} ${_MKCONFIG_RUNTOPDIR}/mkreqlib.sh $2
        ;;
    esac
  fi
}

chkccompile () {
  fn=$1
  ${CC} -c ${CPPFLAGS} ${CFLAGS} ${fn}
  if [ $? -ne 0 ]; then
    echo "## compile of ${fn} failed"
    grc=1
  fi
}

chkouthcompile () {
  if [ $grc -eq 0 ]; then
    > testouth.c echo '
#include <stdio.h>
#include <out.h>
int main (int argc, char *argv []) { return 0; }
'
    chkccompile testouth.c
  fi
}

chkdcompile () {
  fn=$1
  ${DC} -c ${DFLAGS} ${fn}
  if [ $? -ne 0 ]; then
    echo "## compile of ${fn} failed"
    grc=1
  fi
}

chkdiff () {
  f1=$1
  f2=$2

  echo "## diff of $f1 $f2"
  diff -b $f1 $f2
  rc=$?
  if [ $rc -ne 0 ]; then
    echo "## diff of $f1 $f2 failed"
    grc=$rc;
  fi
}

chkgrep () {
  pat=$1
  fn=$2
  arg=$3
  arg2=$4

  if [ "$arg" = "wc" ]; then
    tl=`egrep -l "$pat" ${fn} 2>/dev/null | wc -l`
    rc=$?
    if [ ${tl} -ne ${arg2} ]; then
      grc=1
    fi
  else
    egrep -l "$pat" ${fn} >/dev/null 2>&1
    rc=$?
  fi
  if [ "$arg" = "" -a $rc -ne 0 ]; then
    grc=$rc
    echo "## ${fn}: grep for '$pat' failed"
  fi
  if [ "$arg" = "neg" -a $rc -eq 0 ]; then
    grc=$rc
    echo "## ${fn}: grep for '$pat' succeeded when it should not"
  fi
}

chkouth () {
  chkgrep "$1" out.h $2
}

chkoutd () {
  chkgrep "$1" out.d $2
}

chkcache () {
  chkgrep "$1" mkconfig.cache $2
}

chkenv () {
  chkgrep "$1" test.env $2
}

testcleanup () {
  if [ "$stag" != "none" ]; then
    for x in out.h out.d testouth.c opts test.env mkconfig.log \
        mkconfig.cache mkconfig_c.vars \
        mkconfig_d.vars mkconfig_env.vars mkconfig.reqlibs c.env $@; do
      test -f ${x} && mv ${x} ${x}${stag}
    done
  fi
}
