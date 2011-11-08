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
grc=0
doecho=F

for f in $@; do
  case $f in
    "-e")
      doecho=T
      ;;
    "--")
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
      ;;
  esac
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
  dosubst libnm '${SHLIB_EXT}$' '' '^lib' ''
  libfnm=lib${libnm}.a
  # for really old systems...
  if [ "$ranlibcmd" = "" -a "$lordercmd" != "" -a "$tsortcmd" != "" ]; then
    objects=`$lordercmd ${objects} | $tsortcmd`
  fi
  test -f $libfnm && rm -f $libfnm
  cmd="$arcmd cq $libfnm ${objects}"
  if [ $doecho = "T" ]; then
    echo $cmd
  fi
  eval $cmd
  rc=$?
  if [ $rc -ne 0 ]; then grc=$rc; fi
  if [ "$ranlibcmd" != "" ]; then
    cmd="$ranlibcmd $libfnm"
    echo $cmd
    eval $cmd
    rc=$?
    if [ $rc -ne 0 ]; then grc=$rc; fi
  fi
fi

exit $grc
