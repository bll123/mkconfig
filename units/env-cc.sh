#!/bin/sh
#
# $Id$
# $Source$
#
# Copyright 2001-2010 Brad Lanam, Walnut Creek, California USA
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
env_dohpflags=F

_dogetconf () {
  if [ "$env_dogetconf" = T ]; then
    return
  fi

  locatecmd xgetconf getconf
  if [ "${xgetconf}" != "" ]
  then
      echo "using flags from getconf" >&9
      lfccflags="`${xgetconf} LFS_CFLAGS 2>/dev/null`"
      lfldflags="`${xgetconf} LFS_LDFLAGS 2>/dev/null`"
      lflibs="`${xgetconf} LFS_LIBS 2>/dev/null`"
  fi
  env_dogetconf=T
}

_dohpflags () {
  if [ "$env_dohpflags" = T ]; then
    return
  fi

  hpccincludes=""
  hpldflags=""

  # check for libintl in other places...
  if [ -d /usr/local/include -a \
      -d /usr/local/lib ]
  then
    hpccincludes="-I/usr/local/include"
    hpldflags="-L/usr/local/lib"
    if [ -d /usr/local/lib/hpux32 ]; then
      hpldflags="$hpldflags -L/usr/local/lib/hpux32"
    fi
  fi
  env_dohpflags=T
}

check_cc () {
  CC=${CC:-cc}

  printlabel CC "C compiler"
  checkcache_val ${_MKCONFIG_PREFIX} CC
  if [ $? -eq 0 ]; then return; fi

  case ${_MKCONFIG_SYSTYPE} in
      BeOS|Haiku)
        case ${CC} in
          cc|gcc)
            CC=g++
            ;;
        esac
        ;;
      syllable)
        case ${CC} in
          cc|gcc)
            CC=g++
            ;;
        esac
        ;;
  esac

  echo "cc:${CC}" >&9

  printyesno_val CC "${CC}"
  setdata ${_MKCONFIG_PREFIX} CC "${CC}"
}

check_using_gcc () {
  usinggcc="N"

  printlabel _MKCONFIG_USING_GCC "Using GCC"
  checkcache_val ${_MKCONFIG_PREFIX} _MKCONFIG_USING_GCC
  if [ $? -eq 0 ]; then return; fi

  # check for gcc...
  ${CC} -v 2>&1 | grep 'gcc version' > /dev/null 2>&1
  rc=$?
  if [ $rc -eq 0 ]
  then
      echo "found gcc" >&9
      usinggcc="Y"
  fi

  case ${CC} in
      *gcc*)
          usinggcc="Y"
          ;;
  esac

  printyesno_val _MKCONFIG_USING_GCC "${usinggcc}"
  setdata ${_MKCONFIG_PREFIX} _MKCONFIG_USING_GCC "${usinggcc}"
}

check_cflags () {
  ccflags="${CFLAGS:-}"
  ccincludes="${CINCLUDES:-}"

  printlabel CFLAGS "C flags"
  checkcache_val ${_MKCONFIG_PREFIX} CFLAGS
  if [ $? -eq 0 ]; then return; fi

  _dogetconf

  gccflags=""

  if [ "${_MKCONFIG_USING_GCC}" = "Y" ]
  then
      echo "set gcc flags" >&9
      gccflags="-Wall -Waggregate-return -Wconversion -Wformat -Wmissing-prototypes -Wmissing-declarations -Wnested-externs -Wpointer-arith -Wshadow -Wstrict-prototypes -Wunused"
  fi

  TCC=${CC}
  if [ "${_MKCONFIG_USING_GCC}" = "Y" ]
  then
    TCC=gcc
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
        case ${TCC} in
          cc)
            case ${_MKCONFIG_SYSREV} in
              *.10.*)
                ccflags="+DAportable $ccflags"
                ;;
            esac
            ccflags="-Ae $ccflags"
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
            case ${TCC} in
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
    g++)
      echo "set g++ flags" >&9
      gccflags="-Wall -Waggregate-return -Wconversion -Wformat -Wpointer-arith -Wshadow -Wunused"
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
  checkcache_val ${_MKCONFIG_PREFIX} LDFLAGS
  if [ $? -eq 0 ]; then return; fi

  _dogetconf

  TCC=${CC}
  if [ "${_MKCONFIG_USING_GCC}" = "Y" ]
  then
    TCC=gcc
  fi

  case ${_MKCONFIG_SYSTYPE} in
      FreeBSD)
        # FreeBSD has many packages that get installed in /usr/local
        ldflags="-L/usr/local/lib $ldflags"
        ;;
      HP-UX)
        _dohpflags
        ldflags="$hpldflags $ldflags"
        case ${TCC} in
          cc)
            ldflags="+s $ldflags"
            ;;
        esac
        ;;
      OS/2)
        ldflags="-Zexe"
        ;;
      SunOS)
        case ${_MKCONFIG_SYSREV} in
          5.*)
            case ${TCC} in
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
  checkcache_val ${_MKCONFIG_PREFIX} LIBS
  if [ $? -eq 0 ]; then return; fi

  _dogetconf

  gccflags=""

  TCC=${CC}
  if [ "${_MKCONFIG_USING_GCC}" = "Y" ]
  then
    TCC=gcc
  fi

  case ${_MKCONFIG_SYSTYPE} in
      BeOS|Haiku)
        # uname -m does not reflect actual architecture
        libs="-lroot -lbe $libs"
        ;;
      DYNIX)
        libs="-lseq $libs"
        ;;
      DYNIX/ptx)
        libs="-lseq $libs"
        ;;
      IRIX*)
        case ${_MKCONFIG_SYSREV} in
          [45].*)
            libs="-lsun"
            ;;
        esac
        ;;
  esac

  # largefile flags
  libs="$libs $lflibs"

  echo "libs:${libs}" >&9

  printyesno_val LIBS "$libs"
  setdata ${_MKCONFIG_PREFIX} LIBS "$libs"
}

