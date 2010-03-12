#!/bin/sh
#
# $Id$
# $Source$
#
# Copyright 2010 Brad Lanam, Walnut Creek, California USA
#

require_unit env-main
# optional unit: cflags

check_cmd_msgfmt () {
  name="$1"

  name=XMSGFMT

  printlabel $name "command: locate msgfmt"
  checkcache_val ${_MKCONFIG_PREFIX} $name
  if [ $? -eq 0 ]; then return; fi

  xmsgfmt=`locatecmd msgfmt`
  xgmsgfmt=`locatecmd gmsgfmt`

  mfmt="${xmsgfmt}"
  if [ "$_MKCONFIG_USING_GCC" = "Y" ]
  then
      mfmt="${xgmsgfmt:-${xmsgfmt}}"
      if [ -x "${xccpath}/msgfmt" ]
      then
          mfmt="${xccpath}/msgfmt"
      fi
      if [ -x "${xccpath}/gmsgfmt" ]
      then
          mfmt="${xccpath}/gmsgfmt"
      fi
  fi

  printyesno_val XMSGFMT $xmsgfmt
  setdata ${_MKCONFIG_PREFIX} "XMSGFMT" "${xmsgfmt}"
  doexport "XMSGFMT" "${xmsgfmt}"
}
