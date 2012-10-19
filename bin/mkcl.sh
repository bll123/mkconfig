#!/bin/sh
#
# $Id$
#
# Copyright 2010-2012 Brad Lanam Walnut Creek, CA USA
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

addlib () {
  lfn=$1

  found=F
  nlibnames=
  for tf in $libnames; do
    if [ $lfn = $tf ]; then
      found=T   # a match will be moved to the end of the list
    else
      doappend nlibnames " $tf"
    fi
  done
  doappend nlibnames " ${lfn}"
  libnames=${nlibnames}
}

addlibpath () {
  lp=$1

  found=F
  for tp in $libpathnames; do
    if [ $lp = $tp ]; then
      found=T   # a match will be kept.
      break
    fi
  done
  if [ $found = F ]; then
    doappend libpathnames " ${lp}"
  fi
}

doecho=F
comp=${CC}
reqlibfile=
c=T
d=F
while test $# -gt 0; do
  case $1 in
    -c)
      shift
      comp=$1
      shift
      case ${comp} in
        *gdc*|*ldc*|*dmd*)
          d=T
          c=F
          ;;
      esac
      ;;
    -e)
      doecho=T
      shift
      ;;
    -o)
      shift
      outfile=$1
      shift
      ;;
    -r)
      shift
      reqlibfile=$1
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

# DC_LINK should be in environment already.
OUTFLAG="-o "
DC_LINK=
case ${comp} in
  *dmd*|*ldc*)   # catches ldmd, ldmd2 also
    OUTFLAG=${DC_OF:-"-of"}
    DC_LINK=-L
    ;;
  *gdc*)
    OUTFLAG=${DC_OF:-"-o "}
    ;;
  *gcc*|*cc*)
    DC_LINK=
    ;;
esac

files=
objects=
libnames=
libpathnames=
islib=0
ispath=0
olibs=
componly=F
havesource=F

if [ "$reqlibfile" != "" ]; then
  olibs=`cat $reqlibfile`
fi

grc=0
for f in $@ $olibs; do
  case $f in
    "-L")
      ispath=1
      ;;
    "-L"*)
      tf=$f
      dosubst tf '-L' ''
      if [ ! -d "$tf" ]; then
        echo "## unable to locate dir $tf"
        grc=1
      else
        addlibpath $tf
      fi
      ;;
    "-l")
      islib=1
      ;;
    "-l"*)
      addlib $f
      ;;
    lib*)
      addlib $f
      ;;
    *${OBJ_EXT})
      if [ ! -f "$f" ]; then
        echo "## unable to locate $f"
        grc=1
      else
        doappend objects " $f"
      fi
      ;;
    *.c|*.d)
      if [ ! -f "$f" ]; then
        echo "## unable to locate $f"
        grc=1
      else
        doappend files " $f"
        havesource=T
      fi
      ;;
    "-"*)
      doappend flags " $f"
      if [ $f = "-c" ]; then
        componly=T
      fi
      ;;
    *)
      if [ $islib -eq 1 ]; then
        addlib "-l$f"
      elif [ $ispath -eq 1 ]; then
        if [ ! -d "$f" ]; then
          echo "## unable to locate dir $f"
          grc=1
        else
          addlibpath $f
        fi
      fi
      islib=0
      ispath=0
      ;;
  esac
done

libs=
for lfn in $libnames; do
  doappend libs " ${DC_LINK}${lfn}"
done

libpath=
for lp in $libpathnames; do
  doappend libpath ":${lp}"
done
dosubst libpath '^:' ''

if [ "$outfile" = "" ]; then
  flags="${flags} -c"
  componly=T
else
  case ${outfile} in
    *.o|*.obj)
      flags="${flags} -c"
      componly=T
      ;;
  esac
fi

shrunpath=
shlibpath=
shexeclink=
ldflags=

if [ $componly = F ]; then
  shrunpath=""
  if [ "${libs}" != "" -a "${SHRUNPATH}" != "" ]; then
    dosubst libpath '^:' ''
    shrunpath="${SHRUNPATH}${libpath}"
  fi
  shlibpath=""
  if [ "${libs}" != "" -a "${libpath}" != "" ]; then
    shlibpath="${DC_LINK}-L${libpath}"
  fi
  shexeclink=""
  if [ "${SHEXECLINK}" != "" ]; then
    shexeclink="${SHEXECLINK}"
  fi

  if [ "${DC_LINK}" != "" ]; then
    ldflags=""
    for flag in ${LDFLAGS}; do
      doappend ldflags " ${DC_LINK}${flag}"
    done
  else
    doappend ldflags " ${LDFLAGS}"
  fi
fi

allflags=
if [ $havesource = T ]; then
  if [ $c = T ];then
    doappend allflags " ${CPPFLAGS}"
    doappend allflags " ${CFLAGS}"
    doappend allflags " ${SHCFLAGS}"
  fi
  if [ $d = T ];then
    doappend allflags " ${DFLAGS}"
  fi
fi

cmd="${comp} ${allflags} ${flags} ${ldflags} ${shexeclink} \
    ${OUTFLAG}$outfile $objects \
    ${files} ${shrunpath} ${shlibpath} $libs"
if [ $doecho = T ]; then
  echo $cmd
fi
eval $cmd
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

exit $grc
