#!/bin/sh
#
# $Id$
#
# Copyright 2009-2010 Brad Lanam Walnut Creek, CA USA
#

LOG="mkconfig.log"
CONFH="config.h"
REQLIB="reqlibs.txt"
TMP="_tmp_mkconfig"
CACHEFILE="mkconfig.cache"
datafile=""

INC="include.txt"                   # temporary
EN='-n'
EC=''
datachg=0

precc='
#if defined(__STDC__) || defined(__cplusplus) || defined(c_plusplus)
# define _ARG_(x) x
# define _VOID_ void
#else
# define _ARG_(x) ()
# define _VOID_ char
#endif
#if defined(__cplusplus)
# define _BEGIN_EXTERNS_ extern "C" {
# define _END_EXTERNS_ }
#else
# define _BEGIN_EXTERNS_
# define _END_EXTERNS_
#endif
'

exitmkconfig () {
    rc=$1
    exit 1
}

savedata () {
    # And save the data for re-use.
    # Some shells don't quote the values in the set
    # command like bash does.  So we do it.
    # Then we have to undo it for bash.
    # And then there's: x='', which gets munged.
    if [ $datachg -eq 1 ]; then
      set | grep "^di_cfg" | \
        sed "s/=/='/" | \
        sed "s/$/'/" | \
        sed "s/''/'/g" | \
        sed "s/='$/=''/" \
        > "${CACHEFILE}"
      datachg=0
    fi
}

cleardata () {
    prefix=$1
    cmd="echo \${di_${prefix}_vars}"
    for tval in `eval $cmd`; do
        eval unset di_${prefix}_${tval}
    done
    eval "di_${prefix}_vars="
}

setdata () {
    prefix=$1
    sdname=$2
    sdval=$3

    if [ "$prefix" != "args" ]; then datachg=1; fi

    cmd="echo \$di_${prefix}_vars | grep ${sdname} > /dev/null 2>&1"
    eval "$cmd"
    rc=$?
    # if already in the list of vars, don't add it again.
    if [ $rc -ne 0 ]; then
      cmd="di_${prefix}_vars=\"\${di_${prefix}_vars} ${sdname}\""
      eval "$cmd"
    fi
    cmd="di_${prefix}_${sdname}=\"${sdval}\""
    eval "$cmd"
}

getdata () {
    prefix=$1
    gdname=$2

    gdval=`eval echo "\\${di_${prefix}_${gdname}}"`
    echo $gdval
}

printlabel () {
  tname="$1"
  tlabel="$2"

  echo "## [${tname}] ${tlabel} ... " >> $LOG
  echo ${EN} "${tlabel} ... ${EC}"
}

printyesno_val () {
  ynname=$1
  ynval=$2
  yntag="${3:-}"

  if [ "$ynval" != "0" ]; then
    echo "## [${ynname}] $ynval ${yntag}" >> $LOG
    echo "$ynval ${yntag}"
  else
    echo "## [${ynname}] no ${yntag}" >> $LOG
    echo "no ${yntag}"
  fi
}

printyesno () {
    ynname=$1
    ynval=$2
    yntag="${3:-}"

    if [ "$ynval" != "0" ]; then
      ynval="yes"
    fi
    printyesno_val $ynname $ynval "$yntag"
}

checkcache_val () {
  tname=$1

  tval=`getdata cfg $tname`
  rc=1
  if [ "$tval" != "" ]; then
    printyesno_val $tname $tval " (cached)"
    rc=0
  fi
  return $rc
}

checkcache () {
  tname=$1

  tval=`getdata cfg $tname`
  rc=1
  if [ "$tval" != "" ]; then
    printyesno $tname $tval " (cached)"
    rc=0
  fi
  return $rc
}


print_headers () {
    incheaders=`getdata args incheaders`
    if [ "${incheaders}" = "all" -o "${incheaders}" = "std" ]; then
        for tnm in '_hdr_stdio' '_hdr_stdlib' '_sys_types' '_sys_param'; do
            tval=`getdata cfg ${tnm}`
            if [ "${tval}" != "0" -a "${tval}" != "" ]; then
                echo "#include <${tval}>"
            fi
        done
    fi

    if [ "${incheaders}" = "all" ]; then
        for cfgvar in ${di_cfg_vars}; do
            case ${cfgvar} in
                _hdr_stdio|_hdr_stdlib|_sys_types|_sys_param)
                    ;;
                _hdr_malloc)
                    imval=`getdata cfg '_include_malloc'`
                    if [ "${imval}" != "0" ]; then
                      echo "#include <${hdval}>"
                    fi
                    ;;
                _hdr_strings)
                    hsval=`getdata cfg '_hdr_string'`
                    isval=`getdata cfg '_include_string'`
                    if [ "${hsval}" = "0" -o "${isval}" != "0" ]; then
                      echo "#include <${hdval}>"
                    fi
                    ;;
                _sys_time)
                    htval=`getdata cfg '_hdr_time'`
                    itval=`getdata cfg '_include_time'`
                    if [ "${htval}" = "0" -o "${itval}" != "0" ]; then
                      echo "#include <${hdval}>"
                    fi
                    ;;
                _hdr_*|_sys_*)
                    hdval=`getdata cfg ${cfgvar}`
                    if [ "${hdval}" != "0" -a "${hdval}" != "" ]; then
                        echo "#include <${hdval}>"
                    fi
                    ;;
            esac
        done
    fi
}

check_run () {
    name=$1
    code=$2

    check_link "${name}" "${code}" > /dev/null
    rc=$?
    echo "##  run test: link: $rc" >> $LOG
    rval=0
    if [ $rc -eq 0 ]; then
        rval=`./${name}.exe`
        rc=$?
        echo "##  run test: run: $rc" >> $LOG
        if [ $rc -lt 0 ]; then
            exitmkconfig $rc
        fi
    fi
    echo $rval
    return $rc
}

check_link () {
    name=$1
    code=$2
    shift;shift

    ocounter=0
    clotherlibs=`getdata args otherlibs`
    if [ "${clotherlibs}" != "" ]; then
        set -- $clotherlibs
        ocount=$#
    else
        ocount=0
    fi

    > ${name}.c
    echo "${precc}" >> ${name}.c
    print_headers >> ${name}.c
    echo "${code}" >> ${name}.c
    cat ${name}.c >> $LOG

    dlibs=""
    setdata args otherlibs ""
    _check_link $name
    rc=$?
    echo "##      link test (none): $rc" >> $LOG
    if [ $rc -ne 0 ]; then
        while test $ocounter -lt $ocount; do
            ocounter=`expr $ocounter + 1`
            set -- $clotherlibs
            tcounter=0
            olibs=""
            while test $tcounter -lt $ocounter; do
                olibs="${olibs} $1"
                shift
                tcounter=`expr $tcounter + 1`
            done
            dlibs="${olibs}"
            setdata args otherlibs "$olibs"
            _check_link $name
            rc=$?
            echo "##      link test (${olibs}): $rc" >> $LOG
            if [ $rc -eq 0 ]; then
                break
            fi
        done
    fi
    echo $dlibs
    return $rc
}

_check_link () {
    name=$1

    cmd="${CC} ${CFLAGS} "
    cflags=`getdata args cflags`
    if [ "${cflags}" != "" ]; then
        cmd="${cmd} ${cflags} "
    fi
    cmd="${cmd} -o ${name}.exe ${name}.c "
    cmd="${cmd} ${LDFLAGS} ${LIBS} "
    _clotherlibs=`getdata args otherlibs`
    if [ "${_clotherlibs}" != "" ]; then
        cmd="${cmd} ${_clotherlibs} "
    fi
    echo "##  _link test: $cmd" >> $LOG
    eval $cmd >> $LOG 2>&1
    rc=$?
    if [ $rc -lt 0 ]; then
        exitmkconfig $rc
    fi
    echo "##      _link test: $rc" >> $LOG
    if [ $rc -eq 0 ]; then
      if [ ! -x "${name}.exe" ]; then  # not executable
        rc=1
      fi
    fi
    return $rc
}


check_compile () {
    name=$1
    code=$2

    > ${name}.c
    echo "${precc}" >> ${name}.c
    print_headers >> ${name}.c
    echo "${code}" >> ${name}.c

    cmd="${CC} ${CFLAGS} -c ${name}.c"
    echo "##  compile test: $cmd" >> $LOG
    cat ${name}.c >> $LOG
    eval ${cmd} >> $LOG 2>&1
    rc=$?
    echo "##  compile test: $rc" >> $LOG
    return $rc
}


do_check_compile () {
    name="$1"
    code="$2"
    inc="$3"

    cleardata args
    setdata args incheaders ${inc}
    check_compile "${name}" "${code}"
    rc=$?
    try="0"
    if [ $rc -eq 0 ]; then
        try="1"
    fi
    printyesno $name $try
    setdata cfg "${name}" "${try}"
}

do_check_link () {
    name="$1"
    code="$2"
    inc="$3"

    cleardata args
    setdata args incheaders ${inc}
    setdata args otherlibs ""
    check_link "${name}" "${code}" > /dev/null
    rc=$?
    trc=0
    if [ $rc -eq 0 ]; then
        trc=1
    fi
    printyesno $name $trc
    setdata cfg "${name}" "${trc}"
}

check_header () {
    name=$1
    file=$2

    printlabel $name "header: ${file}"
    checkcache $name
    if [ $rc -eq 0 ]; then return; fi

    reqhdr=`getdata args reqhdr`
    code=""
    if [ "${reqhdr}" != "" ]; then
        set ${reqhdr}
        while test $# -gt 0; do
            code="${code}
#include <$1>
"
            shift
        done
    fi
    code="${code}
#include <$file>
main () { exit (0); }
"
    rc=1
    cleardata args
    setdata args incheaders std
    check_compile "${name}" "${code}"
    rc=$?
    val="0"
    if [ $rc -eq 0 ]; then
        val=${file}
    fi
    printyesno $name $val
    setdata cfg "${name}" "${val}"
}

check_constant () {
    name=$1
    constant=$2

    printlabel $name "constant: ${constant}"
    checkcache $name
    if [ $rc -eq 0 ]; then return; fi

    reqhdr=`getdata args reqhdr`
    code=""
    if [ "${reqhdr}" != "" ]; then
        set ${reqhdr}
        while test $# -gt 0; do
            code="${code}
#include <$1>
"
            shift
        done
    fi
    code="${code}
main () { if (${constant} == 0) { 1; } exit (0); }
"
    do_check_compile "${name}" "${code}" all
}

check_keyword () {
    name=$1
    keyword=$2

    printlabel $name "keyword: ${keyword}"
    checkcache $name
    if [ $rc -eq 0 ]; then return; fi

    code="main () { int ${keyword}; ${keyword} = 1; exit (0); }"

    cleardata args
    setdata args incheaders std
    check_compile "${name}" "${code}"
    rc=$?
    trc=0
    if [ $rc -ne 0 ]; then  # failure means it is reserved...
      trc=1
    fi
    printyesno $name $trc
    setdata cfg "${name}" "${trc}"
}

check_proto () {
    name=$1

    printlabel $name "supported: prototypes"
    checkcache $name
    if [ $rc -eq 0 ]; then return; fi

    code='
_BEGIN_EXTERNS_
extern int foo (int, int);
_END_EXTERNS_
int bar () { int rc; rc = foo (1,1); return 0; }
'

    do_check_compile "${name}" "${code}" all
}

check_type () {
    name=$1
    type=$2

    printlabel $name "type: ${type}"
    checkcache $name
    if [ $rc -eq 0 ]; then return; fi

    code="
struct xxx { ${type} mem; };
static struct xxx v;
struct xxx* f() { return &v; }
main () { struct xxx *tmp; tmp = f(); exit (0); }
"

    do_check_compile "${name}" "${code}" all
}

check_member () {
    name=$1
    struct=$2
    member=$3

    printlabel $name "exists: ${struct}.${member}"
    checkcache $name
    if [ $rc -eq 0 ]; then return; fi

    code="main () { struct ${struct} s; int i; i = sizeof (s.${member}); }"

    do_check_compile "${name}" "${code}" all
}

check_setmntent_1arg () {
    name=$1

    printlabel $name "setmntent(): 1 argument"
    checkcache $name
    if [ $rc -eq 0 ]; then return; fi

    code="main () { setmntent (\"/etc/mnttab\"); }"

    do_check_link "${name}" "${code}" all
}

check_setmntent_2arg () {
    name=$1

    printlabel $name "setmntent(): 2 arguments"
    checkcache $name
    if [ $rc -eq 0 ]; then return; fi

    code="main () { setmntent (\"/etc/mnttab\", \"r\"); }"
    do_check_link "${name}" "${code}" all
}

check_statfs_2arg () {
    name=$1

    printlabel $name "statfs(): 2 arguments"
    checkcache $name
    if [ $rc -eq 0 ]; then return; fi

    code="
main () {
    struct statfs statBuf; char *name; name = \"/\";
    statfs (name, &statBuf);
}
"
    do_check_link "${name}" "${code}" all
}

check_statfs_3arg () {
    name=$1

    printlabel $name "statfs(): 3 arguments"
    checkcache $name
    if [ $rc -eq 0 ]; then return; fi

    code="
main () {
    struct statfs statBuf; char *name; name = \"/\";
    statfs (name, &statBuf, sizeof (statBuf));
}
"
    do_check_link "${name}" "${code}" all
}

check_statfs_4arg () {
    name=$1

    printlabel $name "statfs(): 4 arguments"
    checkcache $name
    if [ $rc -eq 0 ]; then return; fi

    code="
main () {
    struct statfs statBuf; char *name; name = \"/\";
    statfs (name, &statBuf, sizeof (statBuf), 0);
}
"
    do_check_link "${name}" "${code}" all
}


check_size () {
    name=$1
    type=$2

    printlabel $name "sizeof: ${type}"
    checkcache_val $name
    if [ $rc -eq 0 ]; then return; fi

    code="main () { printf(\"%u\", sizeof(${type})); exit (0); }"
    val=0
    val=`check_run "${name}" "${code}"`
    printyesno_val $name $val
    setdata cfg "${name}" "${val}"
}

check_int_declare () {
    name=$1
    function=$2

    printlabel $name "declared: ${function}"
    checkcache $name
    if [ $rc -eq 0 ]; then return; fi

    code="main () { int x; x = ${function}; }"
    do_check_compile "${name}" "${code}" all
}

check_ptr_declare () {
    name=$1
    function=$2

    printlabel $name "declared: ${function}"
    checkcache $name
    if [ $rc -eq 0 ]; then return; fi

    code="main () { _VOID_ *x; x = ${function}; }"
    do_check_compile "${name}" "${code}" all
}

check_npt () {
    name=$1
    proto=$2

    printlabel $name "need prototype: ${proto}"
    checkcache $name
    if [ $rc -eq 0 ]; then return; fi

    code="
_BEGIN_EXTERNS_
struct _TEST_struct { int _TEST_member; };
extern struct _TEST_struct* ${proto} _ARG_((struct _TEST_struct*));
_END_EXTERNS_
"
    do_check_compile "${name}" "${code}" all
}

check_command () {
    name=$1
    cmd=$2

    printlabel $name "command: ${cmd}"
    checkcache $name
    if [ $rc -eq 0 ]; then return; fi

    trc=0
    pth="`echo ${PATH} | sed 's/[;:]/ /g'`"
    for p in $pth; do
        if [ -x "$p/$cmd" ]; then
            trc="$p/$cmd"
            break
        fi
    done
    printyesno $name $trc
    setdata cfg "${name}" "${trc}"
}

check_lib () {
    name=$1
    func=$2

    otherlibs=`getdata args otherlibs`

    if [ "${otherlibs}" != "" ]; then
        printlabel $name "function: ${func} [${otherlibs}]"
    else
        printlabel $name "function: ${func}"
        checkcache $name
        if [ $rc -eq 0 ]; then return; fi
    fi

    trc=0
    # unfortunately, this does not work if the function
    # is not declared.
    code="
typedef int (*_TEST_fun_)();
static _TEST_fun_ i=(_TEST_fun_) ${func};
main () {  i(); return (i==0); }
"

    cleardata args
    setdata args incheaders all
    setdata args otherlibs "${otherlibs}"
    dlibs=`check_link "${name}" "${code}"`
    rc=$?
    if [ $rc -eq 0 ]; then
        trc=1
    fi
    tag=""
    if [ $rc -eq 0 -a "$dlibs" != "" ]; then
      tag=" with ${dlibs}"
      reqlibs=`getdata data reqlibs`
      reqlibs="${reqlibs} ${dlibs}"
      setdata data reqlibs "${reqlibs}"
    fi
    printyesno $name $trc "$tag"
    setdata cfg "${name}" "${trc}"
    return $trc
}

check_class () {
    name=$1
    class=$2

    trc=0
    code=" main () { ${class} testclass; } "
    otherlibs=`getdata args otherlibs`

    if [ "$otherlibs" != "" ]; then
        printlabel $name "class: ${class} [${otherlibs}]"
    else
        printlabel $name "class: ${class}"
        checkcache $name
        if [ $rc -eq 0 ]; then return; fi
    fi

    cleardata args
    setdata args incheaders all
    setdata args otherlibs "${otherlibs}"
    check_link "${name}" "${code}" > /dev/null
    rc=$?
    if [ $rc -eq 0 ]; then
        trc=1
    fi
    tag=""
    if [ $rc -eq 0 -a "${dlibs}" != "" ]; then
        tag=" with ${dlibs}"
        reqlibs=`getdata data reqlibs`
        reqlibs="${reqlibs} ${dlibs}"
        setdata data reqlibs "${reqlibs}"
    fi
    printyesno $name $trc "$tag"
    setdata cfg "${name}" "${trc}"
}

# malloc.h conflicts w/string.h on some systems.
check_include_malloc () {
    name=$1

    trc=0
    _hdr_malloc=`getdata cfg _hdr_malloc`
    _hdr_string=`getdata cfg _hdr_string`
    if [ "${_hdr_string}" = "string.h" -a "${_hdr_malloc}" = "malloc.h" ]; then
      printlabel $name "header: include malloc.h"
      checkcache $name
      if [ $rc -eq 0 ]; then return; fi

      code="
#include <string.h>
#include <malloc.h>
main () { char *x; x = (char *) malloc (20); }"
      do_check_compile "${name}" "${code}" std
    else
      setdata cfg "${name}" "${trc}"
    fi
}

check_include_string () {
    name=$1

    trc=0
    _hdr_string=`getdata cfg _hdr_string`
    _hdr_strings=`getdata cfg _hdr_strings`
    if [ "${_hdr_string}" = "string.h" -a "${_hdr_strings}" = "strings.h" ]; then
      printlabel $name "header: include both string.h & strings.h"
      checkcache $name
      if [ $rc -eq 0 ]; then return; fi

      code="#include <string.h>
#include <strings.h>
main () { char *x; x = \"xyz\"; strcat (x, \"abc\"); }
"
      do_check_compile "${name}" "${code}" std
    else
      setdata cfg "${name}" "${trc}"
    fi
}

check_include_time () {
    name=$1

    trc=0
    _hdr_time=`getdata cfg _hdr_time`
    _sys_time=`getdata cfg _sys_time`
    if [ "${_hdr_time}" = "time.h" -a "${_sys_time}" = "sys/time.h" ]; then
      printlabel $name "header: include both time.h & sys/time.h"
      checkcache $name
      if [ $rc -eq 0 ]; then return; fi

      code="#include <time.h>
#include <sys/time.h>
main () { struct tm x; }
"
      do_check_compile "${name}" "${code}" std
    else
      setdata cfg "${name}" "${trc}"
    fi
}

create_config () {
    configfile=$1
    cleardata cfg

    setdata data reqlibs ""

    > ${CONFH}
    cat <<_HERE_ >> ${CONFH}
#ifndef __INC_CONFIG_H
#define __INC_CONFIG_H 1

_HERE_

    if [ -f $CACHEFILE ]; then
      . $CACHEFILE
    fi
    cleardata data          # don't use cache for required libs

    cleardata args
    setdata args reqhdr ""
    check_header "_hdr_stdlib" "stdlib.h"
    check_header "_hdr_stdio" "stdio.h"
    check_header "_sys_types" "sys/types.h"
    check_header "_sys_param" "sys/param.h"

    check_keyword "_key_void" "void"
    check_keyword "_key_const" "const"
    check_proto "_proto_stdc"

    ininclude=0
    inheaders=1
    OIFS="$IFS"
    > $INC
    # This while loop reads data from stdin, so it has
    # a subshell of its own.  This requires us to save the
    # configuration data in files for re-use.  See setdata()
    while read tdatline; do
        if [ $ininclude -eq 1 ]; then
            if [ "${tdatline}" = "endinclude" ]; then
                echo "end include" >> $LOG
                ininclude=0
                IFS="$OIFS"
            else
                echo "${tdatline}" >> $INC
            fi
        else
            case ${tdatline} in
                "")
                    ;;
                \#*)
                    ;;
                hdr*|sys*)
                    ;;
                *)
                    if [ $inheaders -eq 1 ]; then
                        check_include_malloc '_include_malloc'
                        check_include_string '_include_string'
                        check_include_time '_include_time'
                    fi
                    inheaders=0
                    ;;
            esac
        fi

        if [ $ininclude -eq 0 ]; then
          case ${tdatline} in
            hdr*|sys*)
                set $tdatline
                type=$1
                hdr=$2
                shift;shift
                reqhdr="$*"
                nm1=`echo ${hdr} | sed 's,/.*,,' | tr '[A-Z]' '[a-z]' `
                nm2=`echo ${hdr} | sed "s/^${nm1}//" | sed 's,^/*,,'`
                nm=`echo "_${type}_${nm1}_${nm2}" | sed 's,[/:],_,g' |
                    sed 's/\.h_*$//'`
                case ${type} in
                    sys)
                        hdr="sys/${hdr}"
                        ;;
                esac
                setdata args reqhdr "$reqhdr"
                check_header $nm $hdr
                ;;
            const*)
                set $tdatline
                name=$2
                constant=$2
                shift;shift
                reqhdr="$*"
                name=`echo ${name} | tr '[A-Z]' '[a-z]'`
                name="_const_${name}"
                setdata args reqhdr "$reqhdr"
                check_constant $name $constant
                ;;
            typ*)
                set $tdatline
                name=$2
                type=$2
                name=`echo ${name} | tr '[A-Z]' '[a-z]'`
                name="_typ_${name}"
                check_type $name $type
                ;;
            lib*)
                set $tdatline
                func=$2
                shift;shift
                libs=$*
                nm="_lib_${func}"
                cleardata args
                setdata args otherlibs "${libs}"
                check_lib $nm "${func}"
                rc=$?
                if [ $func = 'setmntent' -a $rc -eq 1 ]; then
                    check_setmntent_1arg '_setmntent_1arg'
                    check_setmntent_2arg '_setmntent_2arg'
                fi
                if [ $func = 'statfs' -a $rc -eq 1 ]; then
                    check_statfs_2arg '_statfs_2arg'
                    check_statfs_3arg '_statfs_3arg'
                    check_statfs_4arg '_statfs_4arg'
                fi
                ;;
            class*)
                set $tdatline
                class=$2
                shift;shift
                libs="$*"
                nm=`echo "_class_${class}" | sed 's/:/_/g'`
                cleardata args
                setdata args otherlibs "${libs}"
                check_class "${nm}" "${class}"
                ;;
            command*)
                set $tdatline
                cmd=$2
                nm=`echo "_command_${cmd}" | tr '[A-Z]' '[a-z]'`
                check_command "${nm}" "${cmd}"
                ;;
            npt*)
                set $tdatline
                func=$2
                req=$3
                has=1
                if [ "${req}" != "" ]; then
                    has=`getdata cfg "${req}"`
                fi
                nm=`echo "_npt_${func}" | tr '[A-Z]' '[a-z]'`
                if [ ${has} -eq 1 ]; then
                    check_npt "${nm}" "${func}"
                else
                    setdata cfg "${nm}" "0"
                fi
                ;;
            dcl*)
                set $tdatline
                type=$2
                var=$3
                nm=`echo "_dcl_${var}" | tr '[A-Z]' '[a-z]'`
                if [ "$type" = "int" ]; then
                    check_int_declare $nm $var
                elif [ "$type" = "ptr" ]; then
                    check_ptr_declare $nm $var
                fi
                ;;
            member*)
                set $tdatline
                struct=$2
                member=$3
                nm=`echo "_mem_${member}_${struct}" | tr '[A-Z]' '[a-z]'`
                check_member $nm $struct $member
                ;;
            size*)
                set $tdatline
                shift
                type="$*"
                nm=`echo "_siz_${type}" | tr '[A-Z]' '[a-z]' | sed 's/ /_/g'`
                check_size $nm "${type}"
                ;;
            include*)
                echo "start include" >> $LOG
                ininclude=1
                IFS="
"
                ;;
          esac
          savedata
        fi
    done < ../${configfile}

    # refetch the configuration data
    . ${CACHEFILE}

    for cfgvar in ${di_cfg_vars}; do
        val=`getdata cfg $cfgvar`
        tval=0
        if [ "$val" != "0" ]; then
          tval=1
        fi
        case ${cfgvar} in
            _siz_*)
                echo "#define ${cfgvar} ${val}" >> ${CONFH}
                ;;
            *)
                echo "#define ${cfgvar} ${tval}" >> ${CONFH}
                ;;
        esac
    done

    > $REQLIB
    val=`getdata data reqlibs`;
    val=`for tval in $val; do
            echo $tval
        done | sort | uniq`
    echo $val >> $REQLIB

    # standard header for all...
    cat << _HERE_ >> ${CONFH}

#if ! _key_void || ! _proto_stdc
# define void int
#endif
#if ! _key_const || ! _proto_stdc
# define const
#endif

#ifndef _
# if _proto_stdc
#  define _(args) args
# else
#  define _(args) ()
# endif
#endif

_HERE_

    cat $INC >> ${CONFH}

    cat << _HERE_ >> ${CONFH}

#define _mkconfig_sh 1
#define _mkconfig_pl 0

#endif /* __INC_CONFIG_H */
_HERE_

}

usage () {
  echo "Usage: $0 [-c <cache-file>] [-o <output-file>]"
  echo "       [-l <log-file>] [-t <tmp-dir>] [-r <reqlib-file>]"
  echo "       [-C] <config-file>"
  echo "  -C : clear cache-file"
  echo "<tmp-dir> must not exist."
  echo "defaults:"
  echo "  <output-file>: config.h"
  echo "  <cache-file> : mkconfig.cache"
  echo "  <log-file>   : mkconfig.log"
  echo "  <tmp-dir>    : _tmp_mkconfig"
  echo "  <reqlib-file>: reqlibs.txt"
}

# main

echo -n 'test' | grep -- '-n' > /dev/null 2>&1
rc=$?
if [ $rc -eq 0 ]; then
    EN=''
    EC='\c'
fi

clearcache=0
while test $# -gt 1; do
  case "$1" in
    -C)
      shift
      clearcache=1
      ;;
    -c)
      shift
      CACHEFILE="$1"
      shift
      ;;
    -o)
      shift
      CONFH="$1"
      shift
      ;;
    -l)
      shift
      LOG="$1"
      shift
      ;;
    -t)
      shift
      TMP="$1"
      shift
      ;;
    -r)
      shift
      REQLIB="$1"
      shift
      ;;
  esac
done

configfile=$1
if [ $# -ne 1 -o ! -f $configfile ]; then
  usage
  exit 1
fi
if [ -d $TMP -a $TMP != "_tmp_mkconfig" ]; then
  usage
  exit 1
fi

LOG="../$LOG"
CONFH="../$CONFH"
REQLIB="../$REQLIB"
CACHEFILE="../$CACHEFILE"

test -d $TMP && rm -rf $TMP > /dev/null 2>&1
mkdir $TMP
cd $TMP

if [ $clearcache -eq 1 ]; then
  rm -f $CACHEFILE > /dev/null 2>&1
fi

echo "$0 using $configfile"
rm -f $LOG > /dev/null 2>&1
CFLAGS="${CFLAGS} ${CINCLUDES}"
echo "CC: ${CC}" >> $LOG
echo "CFLAGS: ${CFLAGS}" >> $LOG
echo "LDFLAGS: ${LDFLAGS}" >> $LOG
echo "LIBS: ${LIBS}" >> $LOG

create_config $configfile

cd ..
test -d $TMP && rm -rf $TMP > /dev/null 2>&1
exit 0
