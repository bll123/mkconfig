#!/bin/sh
#
# Copyright 2010 Brad Lanam Walnut Creek CA USA
#
#
#   The four headers: stdio.h, stdlib.h, sys/types.h, and sys/param.h
#   are always checked.  FreeBSD has header inclusion bugs and requires
#   sys/param.h.
#
#   The keywords 'void' and 'const' are always tested.
#
#   Prototype support is always tested.
#
#   The following code is present in the final config.h file:
#
#       #if ! _key_void || ! _proto_stdc
#       # define void int
#       #endif
#       #if ! _key_const || ! _proto_stdc
#       # define const
#       #endif
#
#       #ifndef _
#       # if _proto_stdc
#       #  define _(args) args
#       # else
#       #  define _(args) ()
#       # endif
#       #endif
#

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

preconfigfile () {
  pc_configfile=$1
  cat  << _HERE_ >> ${pc_configfile}
#ifndef __INC_CONFIG_H
#define __INC_CONFIG_H 1

_HERE_
}

stdconfigfile () {
  pc_configfile=$1
  cat << _HERE_ >> ${pc_configfile}

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
}

postconfigfile () {
  pc_configfile=$1
  cat << _HERE_ >> ${pc_configfile}

#endif /* __INC_CONFIG_H */
_HERE_
}

standard_checks () {
    check_hdr hdr "stdio.h"
    check_hdr hdr "stdlib.h"
    check_hdr sys "types.h"
    check_hdr sys "param.h"
    check_key key "void"
    check_key key "const"
    check_proto "_proto_stdc"
}

_print_headers () {
    if [ "${incheaders}" = "all" -o "${incheaders}" = "std" ]; then
        for tnm in '_hdr_stdio' '_hdr_stdlib' '_sys_types' '_sys_param'; do
            tval=`getdata cfg ${tnm}`
            if [ "${tval}" != "0" -a "${tval}" != "" ]; then
                echo "#include <${tval}>"
            fi
        done
    fi

    if [ "${incheaders}" = "all" -a -f "$VARSFILE" ]; then
        for cfgvar in `cat $VARSFILE`; do
            hdval=`getdata cfg ${cfgvar}`
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
                    if [ "${hdval}" != "0" -a "${hdval}" != "" ]; then
                        echo "#include <${hdval}>"
                    fi
                    ;;
            esac
        done
    fi
}

_chk_run () {
    name=$1
    code=$2

    _chk_link_libs "${name}" "${code}" > /dev/null
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

_chk_link_libs () {
    name=$1
    code=$2
    shift;shift

    ocounter=0
    clotherlibs=$otherlibs
    if [ "${clotherlibs}" != "" ]; then
        set -- $clotherlibs
        ocount=$#
    else
        ocount=0
    fi

    > ${name}.c
    echo "${precc}" >> ${name}.c
    _print_headers >> ${name}.c
    echo "${code}" >> ${name}.c
    cat ${name}.c >> $LOG

    dlibs=""
    otherlibs=""
    _chk_link $name
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
            otherlibs="$olibs"
            _chk_link $name
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

_chk_link () {
    name=$1

    cmd="${CC} ${CFLAGS} "
    if [ "${cflags}" != "" ]; then
        cmd="${cmd} ${cflags} "
    fi
    cmd="${cmd} -o ${name}.exe ${name}.c "
    cmd="${cmd} ${LDFLAGS} ${LIBS} "
    _clotherlibs="$otherlibs"
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


_chk_compile () {
    name=$1
    code=$2

    > ${name}.c
    echo "${precc}" >> ${name}.c
    _print_headers >> ${name}.c
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

    incheaders=${inc}
    _chk_compile "${name}" "${code}"
    rc=$?
    try="0"
    if [ $rc -eq 0 ]; then
        try="1"
    fi
    printyesno $name $try
    setdata cfg "${name}" "${try}"
}

check_hdr () {
    type=$1
    hdr=$2
    shift;shift
    reqhdr="$*"
    # input may be:  ctype.h kernel/fs_info.h
    #    storage/Directory.h
    nm1=`echo ${hdr} | sed -e 's,/.*,,'`
    nm2="_`echo $hdr | sed -e \"s,^${nm1},,\" -e 's,^/*,,'`"
    nm="_${type}_${nm1}"
    if [ "$nm2" != "_" ]; then
      doappend nm $nm2
    fi
    nm=`dosubst "${nm}" '[/:]' '_' '\.h' ''`
    case ${type} in
      sys)
        hdr="sys/${hdr}"
        ;;
    esac

    name=$nm
    file=$hdr

    printlabel $name "header: ${file}"
    checkcache $name
    if [ $rc -eq 0 ]; then return; fi

    code=""
    if [ "${reqhdr}" != "" ]; then
        set ${reqhdr}
        while test $# -gt 0; do
            doappend code "
#include <$1>
"
            shift
        done
    fi
    doappend code "
#include <$file>
main () { exit (0); }
"
    rc=1
    incheaders=std
    _chk_compile "${name}" "${code}"
    rc=$?
    val="0"
    if [ $rc -eq 0 ]; then
        val=${file}
    fi
    printyesno $name $val
    setdata cfg "${name}" "${val}"
}

check_sys () {
  check_hdr $@
}

check_const () {
    constant=$2
    shift;shift
    reqhdr="$*"
    nm="_const_${constant}"

    name=$nm

    printlabel $name "constant: ${constant}"
    checkcache $name
    if [ $rc -eq 0 ]; then return; fi

    code=""
    if [ "${reqhdr}" != "" ]; then
        set ${reqhdr}
        while test $# -gt 0; do
            doappend code "
#include <$1>
"
            shift
        done
    fi
    doappend code "
main () { if (${constant} == 0) { 1; } exit (0); }
"
    do_check_compile "${name}" "${code}" all
}

check_key () {
    keyword=$2
    name="_key_${keyword}"

    printlabel $name "keyword: ${keyword}"
    checkcache $name
    if [ $rc -eq 0 ]; then return; fi

    code="main () { int ${keyword}; ${keyword} = 1; exit (0); }"

    incheaders=std
    _chk_compile "${name}" "${code}"
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

check_typ () {
    type=$2
    nm="_typ_${type}"

    name=$nm

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
    struct=$2
    member=$3
    nm="_mem_${member}_${struct}"

    name=$nm

    printlabel $name "exists: ${struct}.${member}"
    checkcache $name
    if [ $rc -eq 0 ]; then return; fi

    code="main () { struct ${struct} s; int i; i = sizeof (s.${member}); }"

    do_check_compile "${name}" "${code}" all
}


check_size () {
    shift
    type="$*"
    nm="_siz_${type}"
    nm=`dosubst "${nm}" ' ' '_'`

    name=$nm

    printlabel $name "sizeof: ${type}"
    checkcache_val $name
    if [ $rc -eq 0 ]; then return; fi

    code="main () { printf(\"%u\", sizeof(${type})); exit (0); }"
    val=0
    val=`_chk_run "${name}" "${code}"`
    printyesno_val $name $val
    setdata cfg "${name}" "${val}"
}

check_dcl () {
    type=$2
    var=$3

    nm="_dcl_${var}"
    if [ "$type" = "int" ]; then
      check_int_declare $nm $var
    elif [ "$type" = "ptr" ]; then
      check_ptr_declare $nm $var
    fi
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
    func=$2
    req=$3
    has=1
    if [ "${req}" != "" ]; then
      has=`getdata cfg "${req}"`
    fi
    nm="_npt_${func}"

    name=$nm
    proto=$func

    printlabel $name "need prototype: ${proto}"
    checkcache $name
    if [ $rc -eq 0 ]; then return; fi

    if [ ${has} -eq 0 ]; then
      setdata cfg "${name}" "0"
      printyesno $name 0
      return
    fi

    code="
_BEGIN_EXTERNS_
struct _TEST_struct { int _TEST_member; };
extern struct _TEST_struct* ${proto} _ARG_((struct _TEST_struct*));
_END_EXTERNS_
"
    do_check_compile "${name}" "${code}" all
}

check_lib () {
    func=$2
    shift;shift
    libs=$*
    nm="_lib_${func}"
    otherlibs="${libs}"

    name=$nm

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

    incheaders=all
    dlibs=`_chk_link_libs "${name}" "${code}"`
    rc=$?
    if [ $rc -eq 0 ]; then
        trc=1
    fi
    tag=""
    if [ $rc -eq 0 -a "$dlibs" != "" ]; then
      tag=" with ${dlibs}"
      reqlibs="${reqlibs} ${dlibs}"
    fi
    printyesno $name $trc "$tag"
    setdata cfg "${name}" "${trc}"
    return $trc
}

check_class () {
    class=$2
    shift;shift
    libs="$*"
    nm="_class_${class}"
    nm=`dosubst "${nm}" '[/:]' '_'`
    otherlibs="${libs}"

    name=$nm

    trc=0
    code=" main () { ${class} testclass; } "

    if [ "$otherlibs" != "" ]; then
        printlabel $name "class: ${class} [${otherlibs}]"
    else
        printlabel $name "class: ${class}"
        checkcache $name
        if [ $rc -eq 0 ]; then return; fi
    fi

    incheaders=all
#    otherlibs="${otherlibs}"
    _chk_link_libs "${name}" "${code}" > /dev/null
    rc=$?
    if [ $rc -eq 0 ]; then
        trc=1
    fi
    tag=""
    if [ $rc -eq 0 -a "${dlibs}" != "" ]; then
        tag=" with ${dlibs}"
        reqlibs="${reqlibs} ${dlibs}"
    fi
    printyesno $name $trc "$tag"
    setdata cfg "${name}" "${trc}"
}

