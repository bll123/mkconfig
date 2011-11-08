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

libnm=""
objects=""
libs=""
libpath=""
islib=0
ispath=0
grc=0
doecho=F
comp=${CC}

for f in $@; do
  case $f in
    "-e")
      doecho=T
      ;;
    "-c")
      shift
      comp=$1
      shift
      ;;
    "--")
      ;;
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
      doappend libs " -l$tf"
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
      if [ "$libnm" = "" ]; then
        libnm=$f
        continue
      fi
      if [ $islib -eq 1 ]; then
        doappend libs " -l$f"
      fi
      if [ $ispath -eq 1 ]; then
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

# not working
#if [ "${SHLDNAMEFLAG}" != "" ]; then
#  SHLDFLAGS="${SHLDFLAGS} ${SHLDNAMEFLAG}${libnm}"
#fi

if [ $grc -eq 0 ]; then
  dosubst libnm '${SHLIB_EXT}$' '' '^lib' ''
  libfnm=lib${libnm}${SHLIB_EXT}
  shrunpath=""
  if [ "${libs}" != "" -a "${SHRUNPATH}" != "" ]; then
    shrunpath=${libpath}
    dosubst shrunpath '^:' "${SHRUNPATH}"
  fi
  shlibpath=""
  if [ "${libs}" != "" -a "${libpath}" != "" ]; then
    shlibpath=${libpath}
    dosubst shlibpath '^:' '-L'
  fi
  cmd="${comp} ${LDFLAGS} ${SHLDFLAGS} -o $libfnm ${shrunpath} ${shlibpath} ${objects} ${libs}"
  if [ "$doecho" = "T" ]; then
    echo $cmd
  fi
  eval $cmd
  rc=$?
  if [ $rc -ne 0 ]; then grc=$rc; fi
fi

exit $grc
