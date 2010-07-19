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

grc=0
for f in ${members}; do
  if [ ! -f ${f} ]; then
    echo "## Unable to locate ${f}"
    grc=1
  fi
done

locatecmd ranlibcmd ranlib
locatecmd arcmd ar
locatecmd lordercmd lorder
locatecmd tsortcmd tsort

if [ "$arcmd" = "" ]; then
  echo "## Unable to locate 'ar' command"
  grc=1
fi

if [ $grc -eq 0 ]; then
  libfnm=lib${libnm}.a
  # for really old systems...
  if [ "$ranlibcmd" = "" -a "$lordercmd" != "" -a "$tsortcmd" != "" ]; then
    members=`$lordercmd ${members} | $tsortcmd`
  fi
  test -f $libfnm && rm -f $libfnm
  $arcmd cq $libfnm ${members}
  rc=$?
  if [ $rc -ne 0 ]; then grc=$rc; fi
  if [ "$ranlibcmd" != "" ]; then
    $ranlibcmd $libfnm
    rc=$?
    if [ $rc -ne 0 ]; then grc=$rc; fi
  fi
fi

exit $grc
