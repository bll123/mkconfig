#!/bin/sh
#
# $Id$
#
# Copyright 2009-2010 Brad Lanam Walnut Creek, CA USA
#

set -f

# this is a workaround for ksh93 on solaris
if [ "$1" = "-d" ]; then
  cd $2
  shift
  shift
fi
unset CDPATH
unset GREP_OPTIONS
unset ENV
RUNTOPDIR=`pwd`
mypath=`echo $0 | sed -e 's,/[^/]*$,,'`
_MKCONFIG_DIR=`(cd $mypath;pwd)`
export _MKCONFIG_DIR
. ${_MKCONFIG_DIR}/shellfuncs.sh

doshelltest $0 $@
setechovars

CACHEFILE="mkconfig.cache"

getlibdata () {
    var=$1
    gdname=$2
    lang=$3

    cmd="${var}=\${mkc_${lang}_lib_${gdname}}"
    eval $cmd
}

mkconfigversion

OUTLIBFILE="mkconfig.reqlibs"
while test $# -gt 1; do
  case $1 in
    -c)
      shift
      CACHEFILE=$1
      shift
      ;;
    -l)
      shift
      OUTLIBFILE=$1
      shift
      ;;
  esac
done

CONFH=$1

ok=1
if [ ! -f "${CONFH}" ]; then
  echo "Unable to locate ${CONFH}"
  ok=0
fi
if [ ! -f "$RUNTOPDIR/$CACHEFILE" ]; then
  echo "Unable to locate $RUNTOPDIR/$CACHEFILE"
  ok=0
fi
if [ $ok -eq 0 ]; then
  exit 1
fi

reqlibs=""
. $RUNTOPDIR/$CACHEFILE

exec 7<&0 < ${CONFH}
dver=0
while read cline; do
  #echo $cline   # debug
  case $cline in
    "#define _lib_"*1)
      lang=c
      ;;
    "enum bool _clib_"*" = true;")
      lang=d
      dver=2
      ;;
    "enum : bool { _clib_"*" = true };")
      lang=d
      dver=1
      ;;
    *)
      continue
      ;;
  esac

  # bash2 can't handle # in subst
  if [ $lang = "d" -a $dver -eq 1 ]; then
    dosubst cline ': ' '' '{ ' '' ' }' ''
  fi
  dosubst cline '#define ' '' ' 1' '' ' = true;' '' 'enum bool ' ''
  getlibdata var $cline $lang
  if [ "$var" != "" ]; then
    echo $reqlibs | grep -- $var > /dev/null 2>&1
    rc=$?
    if [ $rc -ne 0 ]; then
      doappend reqlibs " $var"
    fi
  fi
done
exec <&7 7<&-
echo $reqlibs > $OUTLIBFILE
