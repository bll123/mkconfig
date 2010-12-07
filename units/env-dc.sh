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
      lfccflags="`${xgetconf} LFS_CFLAGS 2>/dev/null`"
      if [ "$lfccflags" = "undefined" ]; then
        lfccflags=""
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
  setdata ${_MKCONFIG_PREFIX} DC "${DC}"
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

check_using_gnu_ld () {
  usinggnuld="N"

  printlabel _MKCONFIG_USING_GNU_LD "Using gnu ld"

  # check for gdc...
  ${DC} -v 2>&1 | grep 'GNU ld' > /dev/null 2>&1
  rc=$?
  if [ $rc -eq 0 ]
  then
      echo "found gnu ld" >&9
      usinggnuld="Y"
  fi

  printyesno_val _MKCONFIG_USING_GNU_LD "${usinggnuld}"
  setdata ${_MKCONFIG_PREFIX} _MKCONFIG_USING_GNU_LD "${usinggnuld}"
}

check_dflags () {
  dflags="${DFLAGS:-}"
  dincludes="${DINCLUDES:-}"

  printlabel DFLAGS "D flags"

  _dogetconf

  gccflags=""

  if [ "${_MKCONFIG_USING_GDC}" = "Y" ]
  then
      echo "set gdc flags" >&9
      gdcflags="-Wall -Waggregate-return -Wconversion -Wformat -Wmissing-prototypes -Wmissing-declarations -Wnested-externs -Wpointer-arith -Wshadow -Wstrict-prototypes -Wunused"
  fi

  TDC=${CC}
  if [ "${_MKCONFIG_USING_GCC}" = "Y" ]
  then
    TDC=gcc
  fi

  case ${_MKCONFIG_SYSTYPE} in
      AIX)
        if [ "${_MKCONFIG_USING_GCC}" = "N" ]; then
          ccflags="-qhalt=e $ccflags"
          ccflags="$ccflags -qmaxmem=-1"
          case ${_MKCONFIG_SYSREV} in
            4.*)
              ccflags="-DUSE_ETC_FILESYSTEMS=1 $ccflags"
              ;;
          esac
        fi
        ;;
      FreeBSD)
        # FreeBSD has many packages that get installed in /usr/local
        ccincludes="-I/usr/local/include $ccincludes"
        ;;
      HP-UX)
        if [ "${lfccflags}" = "" ]
        then
            ccflags="-D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64 $ccflags"
        fi
        case ${TDC} in
          cc)
            case ${_MKCONFIG_SYSREV} in
              *.10.*)
                ccflags="+DAportable $ccflags"
                ;;
            esac
            cc -v 2>&1 | grep -l Bundled > /dev/null 2>&1
            rc=$?
            if [ $rc -ne 0 ]; then
              ccflags="-Ae $ccflags"
            fi
            _MKCONFIG_USING_GCC="N"
            ;;
        esac

        _dohpflags
        ccincludes="$hpccincludes $ccincludes"
        ;;
      OSF1)
        ccflags="-std1 $ccflags"
        ;;
      SunOS)
        case ${_MKCONFIG_SYSREV} in
          5.*)
            case ${TDC} in
              cc)
                # If solaris is compile w/strict ansi, we get
                # a work-around for the long long type with
                # large files.  So we compile w/extensions.
                ccflags="-Xa -v $ccflags"
                # optimization; -xO3 is good. -xO4 must be set by user.
                ccflags="`echo $ccflags | sed 's,-xO. *,-xO3 ,'`"
                ccflags="`echo $ccflags | sed 's,-O *,-xO3 ,'`"
                echo $ccflags | grep -- '-xO3' >/dev/null 2>&1
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

  case ${CC} in
    g++|c++)
      if [ "${_MKCONFIG_USING_GCC}" = "Y" ]; then
        echo "set g++ flags" >&9
        gccflags="-Wall -Waggregate-return -Wconversion -Wformat -Wpointer-arith -Wshadow -Wunused"
      fi
      ;;
  esac

  ccflags="$gccflags $ccflags"

  # largefile flags
  ccflags="$ccflags $lfccflags"

  echo "ccflags:${ccflags}" >&9

  printyesno_val CFLAGS "$ccflags $ccincludes"
  setdata ${_MKCONFIG_PREFIX} CFLAGS "$ccflags $ccincludes"
}

check_ldflags () {
  ldflags="${LDFLAGS:-}"

  printlabel LDFLAGS "C Load flags"

  _dogetconf

  TDC=${CC}
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

  printlabel LIBS "C Libraries"

  _dogetconf

  gccflags=""

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
