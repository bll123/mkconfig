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

# not working
#if [ "${SHLDNAMEFLAG}" != "" ]; then
#  SHLDFLAGS="${SHLDFLAGS} ${SHLDNAMEFLAG}${libnm}"
#fi

libfnm=lib${libnm}${SHLIB_EXT}
${CC} ${LDFLAGS} ${SHLDFLAGS} -o $libfnm ${members}
rc=$?

exit $rc
