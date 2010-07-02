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

doshelltest $0 $@
setechovars

OPTFILE=options.dat
while test $# -gt 1; do
  case $1 in
    -c)
      shift
      CACHEFILE=$1
      shift
      ;;
    -i)
      shift
      OPTFILE=$1
      shift
      ;;
    *)
      break
      ;;
  esac
done

CONFH=$1
cmd=$2
opt=$3

ok=1
if [ ! -f "${CONFH}" ]; then
  echo "Unable to locate ${CONFH}"
  ok=0
fi
if [ $ok -eq 0 ]; then
  exit 1
fi

exec 7<&0 < ${OPTFILE}
while read oline; do
  set $oline
  if [ "$1" = "$opt" ]; then
    shift
    count=$#
    defs=$@
    break
  fi
done
exec <&7 7<&-

dcount=0

initifs
setifs

if [ "$cmd" = "disable" ]; then
  exec 8>>${CONFH}.new
fi

# handle backslashes in $CONFH
sed 's,\\,\\\\,' ${CONFH} > ${CONFH}.tmp
exec 7<&0 < ${CONFH}.tmp

while read cline; do
  case $cline in
    "#define"*)
      ;;
    *)
      if [ "$cmd" = "disable" ]; then
        echo $cline >&8
      fi
      continue
      ;;
  esac

  resetifs
  set $cline
  nm=$2
  dval=$3

  for d in $defs; do
    if [ "$d" = "$nm" -a "$dval" = "1" ]; then
      dval=0
      domath dcount "$dcount + 1"
    fi
  done

  if [ "$cmd" = "disable" ]; then
    echo "#define $nm $dval" >&8
  fi
  setifs
done
exec <&7 7<&-
if [ "$cmd" = "disable" ]; then
  exec 8>&-
fi
resetifs

# have is zero if enabled...
have=1
if [ $count -eq $dcount ]; then
  have=0
fi

rc=0
case $cmd in
  check)
    rc=$have
    ;;
  status)
    if [ $have -eq 0 ]; then
      echo "# $opt is enabled"
    else
      echo "# $opt is disabled"
    fi
    rc=$have
    ;;
  disable)
    mv ${CONFH}.new ${CONFH}
    rc=0
    ;;
esac

test -f ${CONFH}.tmp && rm -f ${CONFH}.tmp
test -f ${CONFH}.new && rm -f ${CONFH}.new
exit $rc
