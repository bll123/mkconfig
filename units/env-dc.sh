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

env_dogetconf=F

_dogetconf () {
  if [ "$env_dogetconf" = T ]; then
    return
  fi

  locatecmd xgetconf getconf
  if [ "${xgetconf}" != "" ]
  then
      echo "using flags from getconf" >&9
      lfdflags="`${xgetconf} LFS_CFLAGS 2>/dev/null`"
      if [ "$lfdflags" = "undefined" ]; then
        lfdflags=""
      fi
      lfldflags="`${xgetconf} LFS_LDFLAGS 2>/dev/null`"
      if [ "$lfldflags" = "undefined" ]; then
        lfldflags=""
      fi
      lflibs="`${xgetconf} LFS_LIBS 2>/dev/null`"
      if [ "$lflibs" = "undefined" ]; then
        lflibs=""
      fi
  fi
  env_dogetconf=T
}

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

check_ldflags () {
  ldflags="${LDFLAGS:-}"

  printlabel LDFLAGS "D Load flags"

  _dogetconf

  TDC=${DC}
  if [ "${_MKCONFIG_USING_GCC}" = "Y" ]
  then
    TDC=gcc
  fi

  case ${_MKCONFIG_SYSTYPE} in
      FreeBSD)
        # FreeBSD has many packages that get installed in /usr/local
        ldflags="-L/usr/local/lib $ldflags"
        ;;
      HP-UX)
        _dohpflags
        ldflags="$hpldflags $ldflags"
        case ${TDC} in
          cc)
            ldflags="-Wl,+s $ldflags"
            ;;
        esac
        ;;
      OS/2)
        ldflags="-Zexe"
        ;;
      SunOS)
        case ${_MKCONFIG_SYSREV} in
          5.*)
            case ${TDC} in
              cc)
                echo $CFLAGS | grep -- '-xO3' >/dev/null 2>&1
                case $rc in
                    0)
                        ldflags="-fast $ldflags"
                        ;;
                esac
                ;;
            esac
            ;;
        esac
        ;;
  esac

  ldflags="$ldflags $lfldflags"

  echo "ldflags:${ldflags}" >&9

  printyesno_val LDFLAGS "$ldflags"
  setdata ${_MKCONFIG_PREFIX} LDFLAGS "$ldflags"
}

check_libs () {
  libs="${LIBS:-}"

  printlabel LIBS "D Libraries"

  _dogetconf

  gdcflags=""

  TDC=${DC}
  if [ "${_MKCONFIG_USING_GDC}" = "Y" ]
  then
    TDC=gdc
  fi

  # largefile flags
  libs="$libs $lflibs"

  echo "libs:${libs}" >&9

  printyesno_val LIBS "$libs"
  setdata ${_MKCONFIG_PREFIX} LIBS "$libs"
}
