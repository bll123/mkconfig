#!/bin/sh
#
# $Id$
#
# Copyright 2010 Brad Lanam Walnut Creek, CA USA
#

# this is a workaround for ksh93 on solaris
if [ "$1" = "-d" ]; then
  cd $2
  shift
  shift
fi
mypath=`echo $0 | sed -e 's,/[^/]*$,,'`
_MKCONFIG_DIR=`(cd $mypath;pwd)`
export _MKCONFIG_DIR
. ${_MKCONFIG_DIR}/shellfuncs.sh

doshelltest $0 $@
setechovars

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
