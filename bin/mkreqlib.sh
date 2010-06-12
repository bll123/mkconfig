#!/bin/sh
#
# $Id$
#
# Copyright 2009-2010 Brad Lanam Walnut Creek, CA USA
#

RUNTOPDIR=`pwd`
mypath=`echo $0 | sed -e 's,/[^/]*$,,'`
cd $mypath
_MKCONFIG_DIR=`pwd`
export _MKCONFIG_DIR
cd $RUNTOPDIR
. ${_MKCONFIG_DIR}/shellfuncs.sh

CACHEFILE="mkconfig.cache"

getlibdata () {
    var=$1
    gdname=$2

    cmd="${var}=\${di_c_lib_${gdname}}"
    eval $cmd
}

doshelltest $0 $@
setechovars
mkconfigversion

OFILE="reqlibs.txt"
while test $# -gt 1; do
  case $1 in
    -c)
      shift
      CACHEFILE=$1
      shift
      ;;
    -o)
      shift
      OFILE=$1
      shift
      ;;
  esac
done

CONFH=$1

ok=0
if [ ! -f "${CONFH}" ]; then
  echo "Unable to locate ${CONFH}"
  ok=1
fi
if [ ! -f "${RUNTOPDIR}/$CACHEFILE" ]; then
  echo "Unable to locate ${RUNTOPDIR}/$CACHEFILE"
  ok=1
fi
if [ $ok -ne 0 ]; then
  exit 1
fi

reqlibs=""
. ${RUNTOPDIR}/$CACHEFILE

exec 7<&0 < ${CONFH}
while read cline; do
  case $cline in
    "#define _lib_"*1)
      ;;
    *)
      continue
      ;;
  esac

  # bash2 can't handle # in subst
  dosubst cline '#define ' '' ' 1' ''
  getlibdata var $cline
  if [ "$var" != "" ]; then
    echo $reqlibs | grep -- $var > /dev/null 2>&1
    rc=$?
    if [ $rc -ne 0 ]; then
      doappend reqlibs " $var"
    fi
  fi
done
exec <&7 7<&-
echo $reqlibs > $RUNTOPDIR/$OFILE
