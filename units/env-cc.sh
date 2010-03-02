#!/bin/sh
#
# $Id$
# $Source$
# Copyright 2001-2010 Brad Lanam, Walnut Creek, California USA
#

CC=${CC:-cc}
ccflags=""
ldflags=""
libs=""
includes=""
usinggcc="N"
path=$PATH

## need path separator...
tpath=`echo $PATH | sed 's/:/ /g'`
set ${tpath}
for i in $@
do
    if [ -x "$i/sed" ]
    then
        xsed="$i/sed"
        echo "found sed at ${xsed}" >&2
    fi
    if [ -x "$i/grep" ]
    then
        xgrep="$i/grep"
        echo "found grep at ${xgrep}" >&2
    fi
    if [ -x "$i/uname" ]
    then
        xuname="$i/uname"
        echo "found uname at ${xuname}" >&2
    fi
    if [ -x "$i/getconf" ]
    then
        xgetconf="$i/getconf"
        echo "found getconf at ${xgetconf}" >&2
    fi
    # first located
    if [ -x "$i/msgfmt" -a "$xmsgfmt" = "" ]
    then
        xmsgfmt="$i/msgfmt"
        echo "found msgfmt at ${xmsgfmt}" >&2
    fi
    # first located
    if [ -x "$i/gmsgfmt" -a "$xgmsgfmt" = "" ]
    then
        xgmsgfmt="$i/gmsgfmt"
        echo "found gmsgfmt at ${xgmsgfmt}" >&2
    fi
    if [ -x "$i/${CC}" ]
    then
        xccpath="$i"
        echo "found cc at ${xccpath}" >&2
    fi
done

case ${CC} in
    /*)
        xccpath=`echo ${CC} | ${xsed} 's,.*/,,'`
        echo "change xccpath to ${xccpath}" >&2
        ;;
esac

if [ "${xuname}" != "" ]
then
    SYSTYPE=`${xuname} -s`
    SYSREV=`${xuname} -r`
    SYSARCH=`${xuname} -m`

    case ${SYSTYPE} in
        AIX)
            tmp=`( (oslevel) 2>/dev/null || echo "not found") 2>&1`
            case "$tmp" in
                'not found') SYSREV="$4"."$3" ;;
                '<3240'|'<>3240') SYSREV=3.2.0 ;;
                '=3240'|'>3240'|'<3250'|'<>3250') SYSREV=3.2.4 ;;
                '=3250'|'>3250') SYSREV=3.2.5 ;;
                *) SYSREV=$tmp;;
            esac
            ;;
    esac

    echo "type: ${SYSTYPE}" >&2
    echo "rev: ${SYSREV}" >&2
    echo "arch: ${SYSARCH}" >&2
fi

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

# -Wtraditional
case ${CC} in
    *gcc*)
        usinggcc="Y"
        ;;
esac

if [ "$usinggcc" = "Y" ]
then
    echo "set gcc flags" >&2
    gccflags="-Wall -Waggregate-return -Wconversion -Wformat -Wmissing-prototypes -Wmissing-declarations -Wnested-externs -Wpointer-arith -Wshadow -Wstrict-prototypes -Wunused"
    case "${bit64}" in
        1)
            ccflags="-m64 $ccflags"
            ;;
    esac
fi

TCC=${CC}
if [ "${usinggcc}" = "Y" ]
then
  TCC=gcc
fi

case ${SYSTYPE} in
    AIX)
        usinggcc="N"
        ccflags="-qhalt=e $ccflags"
        ccflags="$ccflags -qmaxmem=-1"
        case ${SYSREV} in
            4.*)
                ccflags="-DUSE_ETC_FILESYSTEMS=1 $ccflags"
                ;;
        esac
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
                case ${SYSREV} in
                    *.10.*)
                        ccflags="+DAportable $ccflags"
                        ;;
                esac
                ccflags="-Ae $ccflags"
                usinggcc="N"
                ;;
        esac
        if [ $DI_BUILD_NO_NLS -eq 0 -a \
            -d /usr/local/include -a \
            -d /usr/local/lib -a \
            -f /usr/local/lib/libintl.sl -a \
            -f /usr/local/lib/libiconv.sl ]
        then
            includes="-I/usr/local/include $includes"
            ldflags="-L/usr/local/lib $ldflags"
            libs="-lintl $libs"
            if [ $xmsgfmt != "/usr/local/bin/msgfmt" ]
            then
                path="/usr/local/bin:${path}"
            fi
        elif [ $DI_BUILD_NO_NLS -eq 0 -a \
            -d /opt/gnome/include -a \
            -d /opt/gnome/lib -a \
            -f /opt/gnome/lib/libintl.sl -a \
            -f /opt/gnome/lib/libiconv.sl ]
        then
            includes="-I/opt/gnome/include $includes"
            ldflags="-L/opt/gnome/lib $ldflags"
            libs="-lintl $libs"
            if [ $xmsgfmt != "/usr/local/bin/msgfmt" ]
            then
                path="/opt/gnome/bin:${path}"
            fi
        fi
        ;;
    IRIX*)
        case ${SYSREV} in
            [45].*)
                libs="-lsun"
                ;;
        esac
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
        case ${SYSREV} in
            5.*)
                case ${TCC} in
                    cc)
                        # If solaris is compile w/strict ansi, we get
                        # a work-around for the long long type with
                        # large files.  So we compile w/extensions.
                        ccflags="-Xa -v $ccflags"
                        # optimization
                        ccflags="`echo $ccflags | ${xsed} 's,-xO. *,-xO4 ,'`"
                        ccflags="`echo $ccflags | ${xsed} 's,-O *,-xO4 ,'`"
                        echo $ccflags | ${xgrep} -- '-xO4' >/dev/null 2>&1
                        case $rc in
                            0)
                                ldflags="-fast $ldflags"
                                ;;
                        esac

                        case "${bit64}" in
                            1)
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

# largefile stuff
ccflags="$ccflags $tccflags"
ldflags="$ldflags $tldflags"
libs="$libs $tlibs"
echo "ccflags:${ccflags}" >&2
echo "ldflags:${ldflags}" >&2
echo "libs:${libs}" >&2

mfmt="${xmsgfmt}"
if [ "$usinggcc" = "Y" ]
then
    mfmt="${xgmsgfmt:-${xmsgfmt}}"
    if [ -f "${xccpath}/msgfmt" ]
    then
        mfmt="${xccpath}/msgfmt"
    fi
    if [ -f "${xccpath}/gmsgfmt" ]
    then
        mfmt="${xccpath}/gmsgfmt"
    fi
fi

echo "CC=\"${CC}\""
echo "CFLAGS=\"$ccflags $includes\""
echo "CINCLUDES=\"$includes\""
echo "LDFLAGS=\"$ldflags\""
echo "LIBS=\"$libs\""
echo "XMSGFMT=\"$mfmt\""
echo "PATH=\"$path\""
echo "export CC"
echo "export CFLAGS"
echo "export CINCLUDES"
echo "export LDFLAGS"
echo "export LIBS"
echo "export PATH"
echo "export XMSGFMT"

exit 0
