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
pcmd=$2
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
    defs=$@
    boolclean defs
    break
  fi
done
exec <&7 7<&-

initifs
setifs

donew=F
if [ "$pcmd" = "disable" ]; then
  donew=T
fi
if [ $donew = "T" ]; then
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
      if [ $donew = "T" ]; then
        set -f
        echo $cline >&8
        set +f
      fi
      continue
      ;;
  esac

  resetifs
  set $cline
  nm=$2
  dval=$3

  for d in $defs; do
    case $d in
      \(|\)|-a|-o|!)
        ;;
      *)
        eval $d=$dval
        if [ "$d" = "$nm" -a "$dval" = "1" ]; then
          dval=0
        fi
        ;;
    esac
  done

  if [ $donew = "T" ]; then
    set -f
    echo "#define $nm $dval" >&8
    set +f
  fi
  setifs
done
exec <&7 7<&-
if [ $donew = "T" ]; then
  exec 8>&-
fi
resetifs

ndefs="test "
for d in $defs; do
  case $d in
    \(|\)|-a|-o|!)
      doappend ndefs " $d"
      ;;
    *)
      eval tvar=\$$d
      if [ "$tvar" != "0" ]; then tvar=1; fi
      tvar="( $tvar = 1 )"
      doappend ndefs " $tvar"
      ;;
  esac
done

have=F
dosubst ndefs '(' '\\\\\\(' ')' '\\\\\\)'
eval $ndefs
trc=$?
if [ $trc -eq 0 ]; then
  have=T
fi

rc=0
case $pcmd in
  check)
    rc=1
    if [ $have = "T" ]; then
      rc=0
    fi
    ;;
  status)
    rc=1
    if [ $have = "T" ]; then
      echo "# $opt is enabled"
      rc=0
    else
      echo "# $opt is disabled"
    fi
    ;;
  disable)
    mv ${CONFH}.new ${CONFH}
    rc=0
    ;;
esac

test -f ${CONFH}.tmp && rm -f ${CONFH}.tmp
test -f ${CONFH}.new && rm -f ${CONFH}.new
exit $rc
