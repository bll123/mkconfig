#!/bin/sh
#
# $Id$
# $Source$
#
# Copyright 2010 Brad Lanam, Walnut Creek, California USA
#

#
# speed at the cost of maintainability...
# File Descriptors:
#    9 - >>$LOG                     (mkconfig.sh)
#    8 - >>$VARSFILE, >>$CONFH      (mkconfig.sh)
#    7 - temporary for mkconfig.sh  (mkconfig.sh)
#    6 - temporary for c-main.sh    (c-main.sh)
#    5 - temporary for c-main.sh    (c-main.sh)
#

require_unit env-main
require_unit env-systype

check_dc () {
  DC=${DC:-gdc}

  printlabel DC "D compiler"

  echo "dc:${DC}" >&9

  printyesno_val DC "${DC}"

  case ${DC} in
    *dmd)
      setdata ${_MKCONFIG_PREFIX} DC "${DC}"
      setdata ${_MKCONFIG_PREFIX} DC_OF "-of"
      setdata ${_MKCONFIG_PREFIX} DC_UNITTEST "-unittest"
      setdata ${_MKCONFIG_PREFIX} DC_DEBUG "-debug"
      setdata ${_MKCONFIG_PREFIX} DC_COV "-cov"
      setdata ${_MKCONFIG_PREFIX} DC_LINK "-L"
      setdata ${_MKCONFIG_PREFIX} _MKCONFIG_USING_GDC "N"
      ;;
    *gdc)
      setdata ${_MKCONFIG_PREFIX} DC_OF "-o"
      setdata ${_MKCONFIG_PREFIX} DC_UNITTEST "--unittest"
      setdata ${_MKCONFIG_PREFIX} DC_DEBUG "--debug"
      setdata ${_MKCONFIG_PREFIX} DC_COV ""
      setdata ${_MKCONFIG_PREFIX} DC_LINK ""
      setdata ${_MKCONFIG_PREFIX} _MKCONFIG_USING_GDC "Y"
      ;;
  esac
}

check_using_gdc () {
  usinggdc="N"

  printlabel _MKCONFIG_USING_GDC "Using gdc"

  # check for gdc...
  ${DC} -v 2>&1 | grep 'gdc version' > /dev/null 2>&1
  rc=$?
  if [ $rc -eq 0 ]
  then
      echo "found gdc" >&9
      usinggdc="Y"
  fi

  case ${DC} in
      *gdc*)
          usinggdc="Y"
          ;;
  esac

  printyesno_val _MKCONFIG_USING_GDC "${usinggdc}"
  setdata ${_MKCONFIG_PREFIX} _MKCONFIG_USING_GDC "${usinggdc}"
}

check_dflags () {
  dflags="${DFLAGS:-}"
  dincludes="${DINCLUDES:-}"

  printlabel DFLAGS "D flags"

  _dogetconf

  gdcflags=""

  if [ "${_MKCONFIG_USING_GDC}" = "Y" ]
  then
      echo "set gdc flags" >&9
      gdcflags=""
  fi

  TDC=${DC}
  if [ "${_MKCONFIG_USING_GDC}" = "Y" ]
  then
    TDC=gdc
  fi

  dflags="$gdcflags $dflags"

  echo "dflags:${dflags}" >&9

  printyesno_val DFLAGS "$dflags"
  setdata ${_MKCONFIG_PREFIX} DFLAGS "$dflags"
}
