#!/bin/sh
#
# $Id$
#
# Copyright 2010 Brad Lanam Walnut Creek, CA USA
#


RUNTOPDIR=`pwd`
mypath=`echo $0 | sed -e 's,/[^/]*$,,'`
cd $mypath
_MKCONFIG_DIR=`pwd`
export _MKCONFIG_DIR
cd $RUNTOPDIR
. ${_MKCONFIG_DIR}/shellfuncs.sh

memfile=""
if [ "$1" = "-f" ]; then
  shift
  memfile=$1
  shift
fi
libnm=$1
shift
if [ "$memfile" != "" ]; then
  members=`cat $memfile`
else
  members=$@
fi

MKC_SHLIB_OPT=-shared
MKC_SHLIB_NM="-soname $libnm"
if [ "_MKCONFIG_USING_GCC" != "Y" ]; then
  case ${_MKCONFIG_SYS} in
    SunOS)
      MKC_SHLIB_OPT=-G
      MKC_SHLIB_NM="-h $libnm"
      ;;
    HP-UX)
      MKC_SHLIB_OPT=-b
      MKC_SHLIB_NM="+h $libnm"
      ;;
    OSF1)
      ;;
    AIX)
      MKC_SHLIB_OPT="-bM:SRE"
      MKC_SHLIB_NM=""
      ;;
  esac
fi

libfnm=lib${libnm}.${SHLIB_EXT}
${CC} ${MKC_SHLIB_OPT} ${MKC_SHLIB_NM} -o $libfnm ${members}

exit 0
