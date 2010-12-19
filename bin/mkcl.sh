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

doecho=F
comp=""
while test $# -gt 0; do
  case $1 in
    -e)
      doecho=T
      shift
      ;;
    -c)
      shift
      comp=$1
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

OUTFLAG=-o
DC_LINK=
case ${comp} in
  *dmd)
    OUTFLAG=-of
    DC_LINK=-L
    ;;
esac

objects=""
libs=""
libpath=""
islib=0
ispath=0

grc=0
for f in $@; do
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
        doappend libpath ":$tf"
      fi
      ;;
    "-l")
      islib=1
      ;;
    "-l"*)
      tf=$f
      dosubst tf '-l' ''
      doappend libs " ${DC_LINK}-l$tf"
      ;;
    *${OBJ_EXT})
      if [ ! -f "$f" ]; then
        echo "## unable to locate $f"
        grc=1
      else
        doappend objects " $f"
      fi
      ;;
    *)
      if [ $islib -eq 1 ]; then
        doappend libs " ${DC_LINK}-l$f"
      elif [ $ispath -eq 1 ]; then
        if [ ! -d "$f" ]; then
          echo "## unable to locate dir $f"
          grc=1
        fi
        doappend libpath ":$f"
      fi
      islib=0
      ispath=0
      ;;
  esac
done

libpath=`echo $libpath | sed 's/^://'`
shrunpath=""
if [ "${libs}" != "" -a "${SHRUNPATH}" != "" ]; then
  shrunpath="${SHRUNPATH}${libpath}"
  dosubst shrunpath '^:' ''
fi
shlibpath=""
if [ "${libs}" != "" -a "${libpath}" != "" ]; then
  shlibpath="${DC_LINK}-L${libpath}"
  dosubst shlibpath '^:' ''
fi
shexeclink=""
if [ "${SHEXECLINK}" != "" ]; then
  shexeclink="${SHEXECLINK}"
fi

if [ "${DC_LINK}" != "" ]; then
  ldflags=""
  for flag in ${LDFLAGS}; do
    ldflags="${ldflags} ${DC_LINK}${flag}"
  done
else
  ldflags="${LDFLAGS}"
fi
cmd="${comp} ${ldflags} ${shexeclink} ${OUTFLAG}$outfile $objects \
    ${shrunpath} ${shlibpath} $libs"
if [ $doecho = "T" ]; then
  echo $cmd
fi
eval $cmd
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

exit $grc
