#!/bin/sh
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

standard_checks () {
    check_header "_hdr_stdlib" "stdlib.h"
    check_header "_hdr_stdio" "stdio.h"
    check_header "_sys_types" "sys/types.h"
    check_header "_sys_param" "sys/param.h"

    check_keyword "_key_void" "void"
    check_keyword "_key_const" "const"
    check_proto "_proto_stdc"
}

print_headers () {
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
    clotherlibs=$otherlibs
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
    otherlibs=""
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
            otherlibs="$olibs"
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

    incheaders=${inc}
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

    incheaders=${inc}
    otherlibs=""
    check_link "${name}" "${code}" > /dev/null
    rc=$?
    trc=0
    if [ $rc -eq 0 ]; then
        trc=1
    fi
    printyesno $name $trc
    setdata cfg "${name}" "${trc}"
    return $trc
}


check_header () {
    name=$1
    file=$2

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

check_keyword () {
    name=$1
    keyword=$2

    printlabel $name "keyword: ${keyword}"
    checkcache $name
    if [ $rc -eq 0 ]; then return; fi

    code="main () { int ${keyword}; ${keyword} = 1; exit (0); }"

    incheaders=std
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

check_lib () {
    name=$1
    func=$2

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
    dlibs=`check_link "${name}" "${code}"`
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
    name=$1
    class=$2

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
    check_link "${name}" "${code}" > /dev/null
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
