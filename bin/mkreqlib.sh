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

CONFH=$1
CACHEFILE="mkconfig.cache"

getdata () {
    var=$1
    gdname=$2

    cmd="${var}=\${di_c_lib_${gdname}}"
    eval $cmd
}

doshelltest $0 $@
setechovars
mkconfigversion

ofile="reqlibs.txt"
while test $# -gt 1; do
  case $1 in
    -o)
      shift
      ofile=$1
      shift
      ;;
  esac
done

reqlibs=""
echo "####"
ls -1 ..
echo "####"
echo "####"
ls -1
echo "####"
echo "RUNTOPDIR:$RUNTOPDIR"
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

  dosubst cline '#define ' '' ' 1' ''
  getdata var $cline
  if [ "$var" != "" ]; then
    doappend reqlibs " $var"
  fi
done
exec <&7 7<&-
echo $reqlibs > $RUNTOPDIR/$ofile
