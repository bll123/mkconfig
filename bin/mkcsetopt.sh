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

doshelltest $0 $@
setechovars

OPTFILE=options.dat
while test $# -gt 1; do
  case $1 in
    -o)
      shift
      OPTFILE=$1
      shift
      ;;
    *)
      break
      ;;
  esac
done

opt=$1
val=$2

set -f
OPTNEW=options.new
exec 8>>${OPTNEW}
exec 7<&0 < ${OPTFILE}
while read oline; do
  case $oline in
    ${opt}=*)
      oline=`echo $oline | sed "s/=.*/=${val}/"`
      ;;
  esac
  echo $oline >&8
done
exec <&7 7<&-
set +f

mv ${OPTNEW} ${OPTFILE}
test -f ${OPTNEW} && rm -f ${OPTNEW}

exit $rc
