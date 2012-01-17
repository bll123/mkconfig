#!/bin/sh
#
# $Id$
#
# Copyright 2010 Brad Lanam Walnut Creek, CA USA
#

unset CDPATH
# this is a workaround for ksh93 on solaris
if [ "$1" = "-d" ]; then
  cd $2
  shift
  shift
fi
. ${_MKCONFIG_DIR}/bin/shellfuncs.sh
doshelltest $0 $@

doecho=F
c=T
d=F
comp=${CC}
while test $# -gt 0; do
  case $1 in
    -e)
      doecho=T
      shift
      ;;
    -c)
      shift
      comp=$1
      case ${comp} in
        *gdc|*dmd|*ldc|*ldc2)
          d=T
          c=F
          ;;
      esac
      shift
      ;;
    -o)
      shift
      outfile=$1
      shift
      ;;
    --)
      shift
      break
      ;;
    *)
      break
      ;;
  esac
done

files=""
flags=""

grc=0
for f in $@; do
  case $f in
    *.c|*.d)
      if [ ! -f "$f" ]; then
        echo "## unable to locate $f"
        grc=1
      else
        doappend files " $f"
      fi
      ;;
    *)
      doappend flags " $f"
      ;;
  esac
done

OUTFLAG="-o "
case ${comp} in
  *dmd|*dmd2|*ldc|*ldc2)   # catches ldmd, ldmd2 also
    if [ "$DC_OF" = "" ]; then
      DC_OF="-of"
    fi
    OUTFLAG=${DC_OF}
    ;;
  *gdc)
    if [ "$DC_OF" = "" ]; then
      DC_OF="-o "
    fi
    OUTFLAG=${DC_OF}
    ;;
esac

if [ $c = T ]; then
  cflags=${CFLAGS}
  cppflags=${CPPFLAGS}
  shcflags=
  if [ "${SHCFLAGS}" != "" ]; then
    shcflags=${SHCFLAGS}
  fi
  allflags="$cppflags $cflags $shcflags"
fi
if [ $d = T ]; then
  dflags=${DFLAGS}
  allflags=$dflags
fi
if [ "$outfile" = "" ]; then
  cmd="${comp} ${allflags} ${flags} -c ${files}"
else
  copt=""
  case ${outfile} in
    *.o|*.obj)
      copt=-c
      ;;
  esac
  cmd="${comp} ${allflags} ${flags} ${copt} ${OUTFLAG}$outfile ${files}"
fi

if [ $doecho = "T" ]; then
  echo $cmd
fi
eval $cmd
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

exit $grc
