#!/bin/sh
#
# $Id$
# $Source$
#
# Copyright 2001-2012 Brad Lanam, Walnut Creek, California USA
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
_MKCONFIG_32BIT_FLAGS=F

_dogetconf () {
  if [ "$env_dogetconf" = T ]; then
    return
  fi
  if [ ${_MKCONFIG_32BIT_FLAGS} = T ]; then
    lfccflags=""
    lfldflags=""
    lflibs=""
    env_dogetconf=T
    return
  fi

  locatecmd xgetconf getconf
  if [ "${xgetconf}" != "" ]
  then
      echo "using flags from getconf" >&9
      lfccflags="`${xgetconf} LFS_CFLAGS 2>/dev/null`"
      if [ "$lfccflags" = undefined ]; then
        lfccflags=""
      fi
      lfldflags="`${xgetconf} LFS_LDFLAGS 2>/dev/null`"
      if [ "$lfldflags" = undefined ]; then
        lfldflags=""
      fi
      lflibs="`${xgetconf} LFS_LIBS 2>/dev/null`"
      if [ "$lflibs" = undefined ]; then
        lflibs=""
      fi
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
      -d /usr/local/lib ]; then
    hpccincludes="-I/usr/local/include"
    hpldflags="-L/usr/local/lib"
    if [ -d /usr/local/lib/hpux32 ]; then
      hpldflags="$hpldflags -L/usr/local/lib/hpux32"
    fi
  fi
  env_dohpflags=T
}

check_32bitflags () {
  _MKCONFIG_32BIT_FLAGS=T

  printlabel _MKCONFIG_32BIT_FLAGS "32 bit flags"
  printyesno_val _MKCONFIG_32BIT_FLAGS "${_MKCONFIG_32BIT_FLAGS}"
  setdata ${_MKCONFIG_PREFIX} _MKCONFIG_32BIT_FLAGS "${_MKCONFIG_32BIT_FLAGS}"
}

check_cc () {
  _read_option CC cc
  CC=${CC:-${oval}}

  printlabel CC "C compiler"

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
  if [ ${_MKCONFIG_32BIT_FLAGS} = F ]; then
    setdata ${_MKCONFIG_PREFIX} _MKCONFIG_32BIT_FLAGS "${_MKCONFIG_32BIT_FLAGS}"
  fi
}

check_using_gcc () {
  usinggcc="N"

  printlabel _MKCONFIG_USING_GCC "Using gcc/g++"

  # check for gcc...
  ${CC} -v 2>&1 | grep 'gcc version' > /dev/null 2>&1
  rc=$?
  if [ $rc -eq 0 ]; then
      echo "found gcc" >&9
      usinggcc="Y"
  fi

  case ${CC} in
      *gcc*|*g++*)
          usinggcc="Y"
          ;;
  esac

  printyesno_val _MKCONFIG_USING_GCC "${usinggcc}"
  setdata ${_MKCONFIG_PREFIX} _MKCONFIG_USING_GCC "${usinggcc}"
}

check_using_clang () {
  usingclang="N"

  printlabel _MKCONFIG_USING_CLANG "Using clang"

  # check for clang...
  ${CC} -v 2>&1 | grep 'clang version' > /dev/null 2>&1
  rc=$?
  if [ $rc -eq 0 ]; then
      echo "found clang" >&9
      usingclang="Y"
  fi

  case ${CC} in
      *clang*)
          usingclang="Y"
          ;;
  esac

  printyesno_val _MKCONFIG_USING_CLANG "${usingclang}"
  setdata ${_MKCONFIG_PREFIX} _MKCONFIG_USING_CLANG "${usingclang}"
}

check_using_gnu_ld () {
  usinggnuld="N"

  printlabel _MKCONFIG_USING_GNU_LD "Using gnu ld"

  # check for gnu ld...
  ld -v 2>&1 | grep 'GNU ld' > /dev/null 2>&1
  rc=$?
  if [ $rc -eq 0 ]; then
      echo "found gnu ld" >&9
      usinggnuld="Y"
  fi

  printyesno_val _MKCONFIG_USING_GNU_LD "${usinggnuld}"
  setdata ${_MKCONFIG_PREFIX} _MKCONFIG_USING_GNU_LD "${usinggnuld}"
}

check_cflags () {
  _read_option CFLAGS ""
  ccflags="${CFLAGS:-${oval}}"
  _read_option CINCLUDES ""
  ccincludes="${CINCLUDES:-${oval}}"

  printlabel CFLAGS "C flags"

  _dogetconf

  gccflags=""

  if [ "${_MKCONFIG_USING_GCC}" = Y ]; then
      echo "set gcc flags" >&9
      gccflags="-Wall -Waggregate-return -Wconversion -Wformat -Wmissing-prototypes -Wmissing-declarations -Wnested-externs -Wpointer-arith -Wshadow -Wstrict-prototypes -Wunused -Wno-unknown-pragmas"
      # -Wextra -Wno-unused-but-set-variable -Wno-unused-parameter
  fi
  if [ "${_MKCONFIG_USING_CLANG}" = Y ]; then
     ccflags="-Wno-unknown-warning-option -Weverything -Wno-padded -Wno-format-nonliteral -Wno-cast-align -Wno-system-headers -Wno-disabled-macro-expansion $ccflags"
  fi

  TCC=${CC}
  if [ "${_MKCONFIG_USING_GCC}" = Y ]; then
    TCC=gcc
  fi

  case ${_MKCONFIG_SYSTYPE} in
      AIX)
        if [ "${_MKCONFIG_USING_GCC}" = N ]; then
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
        if [ "${lfccflags}" = "" -a "${_MKCONFIG_32BIT_FLAGS}" = F ]; then
            ccflags="-D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64 $ccflags"
        fi
        case ${TCC} in
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
    g++|c++)
      if [ "${_MKCONFIG_USING_GCC}" = Y ]; then
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

check_addcflag () {
  name=$1
  flag=$2
  ccflags="${CFLAGS:-}"

  printlabel CFLAGS "Add C flag: ${flag}"

  echo "#include <stdio.h>
main () { return 0; }" > t.c
  echo "# test ${flag}" >&9
  # need to set w/all cflags; gcc doesn't always error out otherwise
  TMPF=t$$.txt
  ${CC} ${ccflags} ${flag} -o t t.c > $TMPF 2>&1
  rc=$?
  if [ $rc -ne 0 ]; then
    flag=0
  fi
  grep -i "warning.*${flag}" $TMPF > /dev/null 2>&1
  rc=$?
  if [ $rc -eq 0 ]; then
    flag=0
  fi
  cat $TMPF >&9
  rm -f $TMPF > /dev/null 2>&1
  printyesno $name ${flag}
  if [ $flag = 0 ]; then
    flag=""
  fi
  setdata ${_MKCONFIG_PREFIX} CFLAGS "$ccflags ${flag}"
}

check_addldflag () {
  name=$1
  flag=$2
  ccflags="${CFLAGS:-}"
  ldflags="${LDFLAGS:-}"

  printlabel LDFLAGS "Add LD flag: ${flag}"

  echo "#include <stdio.h>
main () { return 0; }" > t.c
  echo "# test ${flag}" >&9
  # need to set w/all cflags/ldflags; gcc doesn't always error out otherwise
  TMPF=t$$.txt
  ${CC} ${ccflags} ${ldflags} ${flag} -o t t.c > $TMPF 2>&1
  rc=$?
  if [ $rc -ne 0 ]; then
    flag=0
  fi
  grep -i "warning.*${flag}" $TMPF > /dev/null 2>&1
  rc=$?
  if [ $rc -eq 0 ]; then
    flag=0
  fi
  cat $TMPF >&9
  rm -f $TMPF > /dev/null 2>&1
  printyesno $name ${flag}
  if [ $flag = 0 ]; then
    flag=""
  fi
  setdata ${_MKCONFIG_PREFIX} LDFLAGS "$ldflags ${flag}"
}

check_ldflags () {
  _read_option LDFLAGS ""
  ldflags="${LDFLAGS:-${oval}}"

  printlabel LDFLAGS "C Load flags"

  _dogetconf

  TCC=${CC}
  if [ "${_MKCONFIG_USING_GCC}" = Y ]; then
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
  _read_option LIBS ""
  libs="${LIBS:-${oval}}"

  printlabel LIBS "C Libraries"

  _dogetconf

  gccflags=""

  TCC=${CC}
  if [ "${_MKCONFIG_USING_GCC}" = Y ]; then
    TCC=gcc
  fi

  case ${_MKCONFIG_SYSTYPE} in
      BeOS|Haiku)
        # uname -m does not reflect actual architecture
        libs="-lroot -lbe $libs"
        ;;
  esac

  # largefile flags
  libs="$libs $lflibs"

  echo "libs:${libs}" >&9

  printyesno_val LIBS "$libs"
  setdata ${_MKCONFIG_PREFIX} LIBS "$libs"
}

check_shcflags () {
  _read_option SHCFLAGS ""
  shcflags="${SHCFLAGS:-${oval}}"

  printlabel SHCFLAGS "shared library cflags"

  shcflags="-fPIC $SHCFLAGS"
  if [ "$_MKCONFIG_USING_GCC" != Y ]; then
    case ${_MKCONFIG_SYSTYPE} in
      CYGWIN*)
        shcflags="$SHCFLAGS"
        ;;
      Darwin)
        shcflags="-fno-common $SHCFLAGS"
        ;;
      HP-UX)
        shcflags="+Z $SHCFLAGS"
        ;;
      IRIX*)
        shcflags="-KPIC $SHCFLAGS"
        ;;
      OSF1)
        # none
        ;;
      SCO_SV)
        shcflags="-KPIC $SHCFLAGS"
        ;;
      SunOS)
        shcflags="-KPIC $SHCFLAGS"
        ;;
      UnixWare)
        shcflags="-KPIC $SHCFLAGS"
        ;;
    esac
  fi

  printyesno_val SHCFLAGS "$shcflags"
  setdata ${_MKCONFIG_PREFIX} SHCFLAGS "$shcflags"
}

check_shldflags () {
  _read_option SHLDFLAGS ""
  shldflags="${SHLDFLAGS:-${oval}}"
  printlabel SHLDFLAGS "shared library ldflags"

  shldflags="$SHLDFLAGS -shared"
  if [ "$_MKCONFIG_USING_GCC" != Y ]; then
    case ${_MKCONFIG_SYSTYPE} in
      AIX)
        shldflags="$SHLDFLAGS -G"
        ;;
      HP-UX)
        shldflags="$SHLDFLAGS -b"
        ;;
      IRIX*)
        # "-shared"
        ;;
      OSF1)
        shldflags="-shared -msym -no_archive"
        ;;
      SCO_SV)
        shldflags="$SHLDFLAGS -G"
        ;;
      SunOS)
        shldflags="$SHLDFLAGS -G"
        ;;
      UnixWare)
        shldflags="$SHLDFLAGS -G"
        ;;
    esac
  fi

  case ${_MKCONFIG_SYSTYPE} in
    Darwin)
      shldflags="$SHLDFLAGS -dynamiclib"
      ;;
  esac

  printyesno_val SHLDFLAGS "$shldflags"
  setdata ${_MKCONFIG_PREFIX} SHLDFLAGS "$shldflags"
}

check_sharednameflag () {
  printlabel SHLDNAMEFLAG "shared lib name flag"

  SHLDNAMEFLAG="-Wl,-soname="
  if [ "$_MKCONFIG_USING_GNU_LD" != Y ]; then
    case ${_MKCONFIG_SYSTYPE} in
      Darwin)
        # -compatibility_version -current_version
        ;;
      HP-UX)
        SHLDNAMEFLAG="-Wl,+h "
        ;;
      IRIX*)
        # -soname
        ;;
      OSF1)
        # -soname
        ;;
      SunOS)
        SHLDNAMEFLAG="-Wl,-h "
        ;;
    esac
  fi

  printyesno_val SHLDNAMEFLAG "$SHLDNAMEFLAG"
  setdata ${_MKCONFIG_PREFIX} SHLDNAMEFLAG "$SHLDNAMEFLAG"
}

check_shareexeclinkflag () {
  printlabel SHEXECLINK "shared executable link flag "

  SHEXECLINK="-Bdynamic "
  if [ "$_MKCONFIG_USING_GCC" != Y ]; then
    case ${_MKCONFIG_SYSTYPE} in
      AIX)
        SHEXECLINK="-brtl -bdynamic "
        ;;
      Darwin)
        SHEXECLINK=""
        ;;
      HP-UX)
        SHEXECLINK="+Z"
        ;;
      OSF1)
        SHEXECLINK="-msym -no_archive "
        ;;
      SCO_SV)
        SHEXECLINK=""
        ;;
      SunOS)
        # -Bdynamic
        ;;
      UnixWare)
        SHEXECLINK=""
        ;;
    esac
  fi

  printyesno_val SHEXECLINK "$SHEXECLINK"
  setdata ${_MKCONFIG_PREFIX} SHEXECLINK "$SHEXECLINK"
}

check_sharerunpathflag () {
  printlabel SHRUNPATH "shared run path flag "

  SHRUNPATH="-Wl,-rpath="
  if [ "$_MKCONFIG_USING_GNU_LD" != Y ]; then
    case ${_MKCONFIG_SYSTYPE} in
      AIX)
        SHRUNPATH=""
        ;;
      Darwin)
        SHRUNPATH=""
        ;;
      HP-UX)
        SHRUNPATH="-Wl,+b "
        ;;
      IRIX*)
        SHRUNPATH="-Wl,-rpath "
        ;;
      OSF1)
        SHRUNPATH="-rpath "
        ;;
      SCO_SV)
        SHRUNPATH="-Wl,-R "
        ;;
      SunOS)
        SHRUNPATH="-Wl,-R"
        ;;
      UnixWare)
        SHRUNPATH="-Wl,-R "
        ;;
    esac
  fi

  printyesno_val SHRUNPATH "$SHRUNPATH"
  setdata ${_MKCONFIG_PREFIX} SHRUNPATH "$SHRUNPATH"
}
