#!/bin/sh
#
# $Id$
# $Source$
#
# Copyright 2001-2010 Brad Lanam, Walnut Creek, California USA
#

require_unit systype

CC=${CC:-cc}
ccflags=""
ldflags=""
libs=""
includes=""
usinggcc="N"

xgetconf=`locatecmd getconf`
if [ "${xgetconf}" != "" ]
then
    echo "using flags from getconf" >&2
    tccflags="`${xgetconf} LFS_CFLAGS 2>/dev/null`"
    tldflags="`${xgetconf} LFS_LDFLAGS 2>/dev/null`"
    tlibs="`${xgetconf} LFS_LIBS 2>/dev/null`"
fi

gccflags=""

# check for gcc...
${CC} -v 2>&1 | $xgrep 'gcc version' > /dev/null 2>&1
rc=$?
if [ $rc -eq 0 ]
then
    echo "found gcc" >&2
    usinggcc="Y"
fi

case ${CC} in
    *gcc*)
        usinggcc="Y"
        ;;
esac

if [ "$usinggcc" = "Y" ]
then
    echo "set gcc flags" >&2
    gccflags="-Wall -Waggregate-return -Wconversion -Wformat -Wmissing-prototypes -Wmissing-declarations -Wnested-externs -Wpointer-arith -Wshadow -Wstrict-prototypes -Wunused"
fi

TCC=${CC}
if [ "${usinggcc}" = "Y" ]
then
  TCC=gcc
fi

case ${_MKCONFIG_SYSTYPE} in
    AIX)
      if [ "${usinggcc}" = "N" ]; then
        ccflags="-qhalt=e $ccflags"
        ccflags="$ccflags -qmaxmem=-1"
        case ${_MKCONFIG_SYSREV} in
          4.*)
            ccflags="-DUSE_ETC_FILESYSTEMS=1 $ccflags"
            ;;
        esac
      fi
      ;;
    BeOS|Haiku)
      case ${TCC} in
        cc|gcc)
          CC=g++
          ;;
      esac
      # uname -m does not reflect actual architecture
      libs="-lroot -lbe $libs"
      ;;
    CYGWIN*)
      ;;
    FreeBSD)
      # FreeBSD has many packages that get installed in /usr/local
      includes="-I/usr/local/include $includes"
      ldflags="-L/usr/local/lib $ldflags"
      ;;
    DYNIX)
      libs="-lseq $libs"
      ;;
    DYNIX/ptx)
      libs="-lseq $libs"
      ;;
    HP-UX)
      if [ "${tccflags}" = "" ]
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
          usinggcc="N"
          ;;
      esac

      # check for libintl in other places...
      if [ -d /usr/local/include -a \
          -d /usr/local/lib -a \
          -f /usr/local/lib/libintl.sl -a \
          -f /usr/local/lib/libiconv.sl ]
      then
          includes="-I/usr/local/include $includes"
          ldflags="-L/usr/local/lib $ldflags"
          libs="-lintl $libs"
      elif [ -d /opt/gnome/include -a \
          -d /opt/gnome/lib -a \
          -f /opt/gnome/lib/libintl.sl -a \
          -f /opt/gnome/lib/libiconv.sl ]
      then
          includes="-I/opt/gnome/include $includes"
          ldflags="-L/opt/gnome/lib $ldflags"
          libs="-lintl $libs"
      fi
      ;;
    IRIX*)
      case ${_MKCONFIG_SYSREV} in
        [45].*)
          libs="-lsun"
          ;;
      esac
      ;;
    Linux)
      ;;
    NetBSD)
      ;;
    OS/2)
      ldflags="-Zexe"
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
              ccflags="`echo $ccflags | ${xsed} 's,-xO. *,-xO3 ,'`"
              ccflags="`echo $ccflags | ${xsed} 's,-O *,-xO3 ,'`"
              echo $ccflags | ${xgrep} -- '-xO3' >/dev/null 2>&1
              case $rc in
                  0)
                      ldflags="-fast $ldflags"
                      ;;
              esac
              ;;
            *gcc*)
              ;;
          esac
          ;;
      esac
      ;;
    syllable)
      case ${TCC} in
        cc|gcc)
          CC=g++
          ;;
      esac
      ;;
    # unixware
    UNIX_SV)
      ;;
esac

case ${CC} in
  g++)
    echo "set g++ flags" >&2
    gccflags="-Wall -Waggregate-return -Wconversion -Wformat -Wpointer-arith -Wshadow -Wunused"
    ;;
esac

ccflags="$gccflags $ccflags"

# largefile flags
ccflags="$ccflags $tccflags"
ldflags="$ldflags $tldflags"
libs="$libs $tlibs"

echo "cc:${CC}" >&2
echo "ccflags:${ccflags}" >&2
echo "ldflags:${ldflags}" >&2
echo "libs:${libs}" >&2

echo "CC=\"${CC}\""
echo "export CC"
echo "CFLAGS=\"$ccflags $includes\""
echo "export CFLAGS"
echo "CINCLUDES=\"$includes\""
echo "export CINCLUDES"
echo "LDFLAGS=\"$ldflags\""
echo "export LDFLAGS"
echo "LIBS=\"$libs\""
echo "export LIBS"

echo "_MKCONFIG_USING_GCC=${usinggcc}"
echo "export _MKCONFIG_USING_GCC"

