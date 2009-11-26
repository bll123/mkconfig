#!/bin/sh

LOG="../mkconfig.log"
TMP="_tmp"
ARGS="args.tmp"
VALUE="value.tmp"
CFG="config.tmp"
CONFH="../config.h"
REQLIB="../reqlibs.txt"
EN='-n'
EC=''

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

cleardata () {
    cdfile=$1
    > $cdfile
}

setdata () {
    sdfile=$1
    sdname=$2
    sdval=$3

    cat $sdfile | egrep -v "^${sdname} " > ${sdfile}.tmp 2>/dev/null
    mv -f ${sdfile}.tmp ${sdfile}
    echo "${sdname} ${sdval}" >> ${sdfile}
}

getdata () {
    gdfile=$1
    gdname=$2

    tgdval=`egrep "^${gdname} " ${gdfile}`
    rc=$?
    gdval=""
    if [ $rc -eq 0 ]
    then
        set $tgdval
        gdval=$2
    fi
    echo ${gdval}
}

print_headers () {

    incheaders=`getdata $ARGS incheaders`

    if [ "${incheaders}" = "all" -o "${incheaders}" = "std" ]
    then
        for tnm in '_hdr_stdio' '_hdr_stdlib' '_sys_types' '_sys_param'
        do
            tval=`getdata $CFG $tnm`
            if [ "${tval}" != "0" -a "${tval}" != "" ]
            then
                echo "#include <${tval}>"
            fi
        done
    fi

    if [ "${incheaders}" = "all" ]
    then
        while read thdline
        do
            set $thdline
            hdnm=$1
            hdval=$2
            case ${hdnm} in
                _hdr_stdio|_hdr_stdlib|_sys_types|_sys_param)
                    ;;
                _hdr_*|_sys_*)
                    if [ "${hdval}" != "0" -a "${hdval}" != "" ]
                    then
                        echo "#include <${hdval}>"
                    fi
                    ;;
            esac
        done < $CFG
    fi
}

check_run () {
    name=$1
    code=$2

    dlibs=`check_link "${name}" "${code}"`
    rc=$?
    echo "##  run test: link: $rc" >> $LOG
    rval=0
    if [ $rc -eq 0 ]
    then
        rval=`./${name}.exe`
        rc=$?
        echo "##  run test: run: $rc" >> $LOG
        if [ $rc -lt 0 ]
        then
            exitmkconfig $rc
        fi
    fi
    rm -f ${name}.exe ${name}.c ${name}.out ${name}.o > /dev/null 2>&1
    echo $rval
    return $rc
}

check_link () {
    name=$1
    code=$2
    shift;shift

    ocounter=0
    clotherlibs=`getdata $ARGS otherlibs`
    if [ "${clotherlibs}" != "" ]
    then
        set $clotherlibs
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
    setdata $ARGS otherlibs ""
    _check_link $name
    rc=$?
    echo "##      link test (none): $rc" >> $LOG
    if [ $rc -ne 0 ]
    then
        while test $ocounter -lt $ocount
        do
            ocounter=`eval $ocounter + 1`
            set $clotherlibs
            tcounter=0
            olibs=""
            while test $tcounter -lt $ocounter
            do
                olibs="${olibs} $1"
                shift
            done
            dlibs="${olibs}"
            setdata $ARGS otherlibs "$olibs"
            _check_link $name
            echo "##      link test (${olibs}): $rc" >> $LOG
            rc=$?
            if [ $rc -eq 0 ]
            then
                reqlibs=`getdata $CFG reqlibs`
                reqlibs="${reqlibs} ${olibs}"
                setdata $CFG reqlibs $reqlibs
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
    cflags=`getdata $ARGS cflags`
    if [ "${cflags}" != "" ]
    then
        cmd="${cmd} ${cflags} "
    fi
    cmd="${cmd} -o ${name}.exe ${name}.c "
    cmd="${cmd} ${LDFLAGS} ${LIBS} "
    _clotherlibs=`getdata $ARGS otherlibs`
    if [ "${_clotherlibs}" != "" ]
    then
        cmd="${cmd} ${_clotherlibs} "
    fi
    echo "##  _link test: $cmd" >> $LOG
    eval $cmd >> $LOG 2>&1
    rc=$?
    if [ $rc -lt 0 ]
    then
        exitmkconfig $rc
    fi
    echo "##      _link test: $rc" >> $LOG
    if [ $rc -eq 0 ]
    then
        if [ ! -x "${name}.exe" ]  # not executable.
        then
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
    rm -f ${name}.c ${name}.o ${name}.obj > /dev/null 2>&1
    return $rc
}


check_header () {
    name=$1
    file=$2

    echo "## [${name}] header: ${file} ..." >> $LOG
    echo ${EN} "header: ${file} ...${EC}"
    reqhdr=`getdata $ARGS reqhdr`
    code=""
    if [ "${reqhdr}" != "" ]
    then
        set ${reqhdr}
        while test $# -gt 0
        do
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
    cleardata $ARGS
    setdata $ARGS incheaders std
    check_compile "${name}" "${code}"
    rc=$?
    val="0"
    if [ $rc -eq 0 ]
    then
        val=${file}
        echo "## [${name}] yes" >> $LOG
        echo "yes"
    else
        echo "## [${name}] no" >> $LOG
        echo "no"
    fi
    setdata $CFG "${name}" "${val}"
}

check_keyword () {
    name=$1
    keyword=$2

    echo "## [$name] keyword: $keyword ... " >> $LOG
    echo ${EN} "keyword: $keyword ... ${EC}"
    trc=0
    code="main () { int ${keyword}; ${keyword} = 1; exit (0); }"
    setdata $ARGS incheaders std
    check_compile "${name}" "${code}"
    rc=$?
    if [ $rc -ne 0 ]  # failure means it is reserved...
    then
        trc=1
        echo "## [$name] yes" >> $LOG
        echo "yes"
    else
        echo "## [$name] no" >> $LOG
        echo "no"
    fi
    setdata $CFG ${name} $trc
}

check_proto () {
    name=$1

    echo "## [$name] supported: prototypes ... " >> $LOG
    echo ${EN} "supported: prototypes ... ${EC}"
    code='
_BEGIN_EXTERNS_
extern int foo (int, int);
_END_EXTERNS_
int bar () { int rc; rc = foo (1,1); return 0; }
'
    setdata $ARGS incheaders all
    check_compile "${name}" "${code}"
    rc=$?
    trc=0
    if [ $rc -eq 0 ]
    then
        trc=1
        echo "## [$name] yes" >> $LOG
        echo "yes"
    else
        echo "## [$name] no" >> $LOG
        echo "no"
    fi
    setdata $CFG $name $trc
}

check_type () {
    name=$1
    type=$2

    echo "## [$name] type: $type ... " >> $LOG
    echo ${EN} "type: $type ... ${EC}"
    trc=0
    code="
struct xxx { ${type} mem; };
static struct xxx v;
struct xxx* f() { return &v; }
main () { struct xxx *tmp; tmp = f(); exit (0); }
"
    cleardata $ARGS
    setdata $ARGS incheaders all
    check_compile "${name}" "${code}"
    rc=$?
    if [ $rc -eq 0 ]
    then
        trc=1
        echo "## [$name] yes" >> $LOG
        echo "yes"
    else
        echo "## [$name] no" >> $LOG
        echo "no"
    fi
    setdata $CFG $name $trc
}

check_member () {
    name=$1
    struct=$2
    member=$3

    echo "## [$name] exists: $struct.$member ... " >> $LOG
    echo ${EN} "exists: $struct.$member ... ${EC}"
    trc=0
    code="main () { struct ${struct} s; int i; i = sizeof (s.${member}); }"
    cleardata $ARGS
    setdata $ARGS incheaders all
    check_compile "${name}" "${code}"
    if [ $rc -eq 0 ]
    then
        trc=1
        echo "## [$name] yes" >> $LOG
        echo "yes"
    else
        echo "## [$name] no" >> $LOG
        echo "no"
    fi
    setdata $CFG $name $trc
}

check_setmntent_1arg () {
    name=$1

    echo "## [$name] setmntent(): 1 argument ... " >> $LOG
    echo ${EN} "setmntent(): 1 argument ... ${EC}"
    trc=0
    code="main () { setmntent (\"/etc/mnttab\"); }"
    cleardata $ARGS
    setdata $ARGS incheaders all
    setdata $ARGS nounlink 0
    setdata $ARGS otherlibs ""
    setdata $ARGS tryextern 0
    check_link "${name}" "${code}"
    rc=$?
    if [ $rc -eq 0 ]
    then
        trc=1
        echo "## [$name] yes" >> $LOG
        echo "yes"
    else
        echo "## [$name] no" >> $LOG
        echo "no"
    fi
    setdata $CFG $name $trc
}

check_setmntent_2arg () {
    name=$1

    echo "## [$name] setmntent(): 2 arguments ... " >> $LOG
    echo ${EN} "setmntent(): 2 arguments ... ${EC}"

    trc=0
    code="main () { setmntent (\"/etc/mnttab\", \"r\"); }"
    cleardata $ARGS
    setdata $ARGS incheaders all
    setdata $ARGS nounlink 0
    setdata $ARGS otherlibs ""
    setdata $ARGS tryextern 0
    check_link "${name}" "${code}"
    rc=$?
    if [ $rc -eq 0 ]
    then
        trc=1
        echo "## [$name] yes" >> $LOG
        echo "yes"
    else
        echo "## [$name] no" >> $LOG
        echo "no"
    fi
    setdata $CFG $name $trc
}

check_statfs_2arg () {
    name=$1

    echo "## [$name] statfs(): 2 arguments ... " >> $LOG
    echo ${EN} "statfs(): 2 arguments ... ${EC}"

    trc=0
    code="
main () {
    struct statfs statBuf; char *name; name = \"/\";
    statfs (name, &statBuf);
}
"
    cleardata $ARGS
    setdata $ARGS incheaders all
    setdata $ARGS nounlink 0
    setdata $ARGS otherlibs ""
    setdata $ARGS tryextern 0
    check_link "${name}" "${code}"
    rc=$?
    if [ $rc -eq 0 ]
    then
        trc=1
        echo "## [$name] yes" >> $LOG
        echo "yes"
    else
        echo "## [$name] no" >> $LOG
        echo "no"
    fi
    setdata $CFG $name $trc
}

check_statfs_3arg () {
    name=$1

    echo "## [$name] statfs(): 3 arguments ... " >> $LOG
    echo ${EN} "statfs(): 3 arguments ... ${EC}"

    trc=0
    code="
main () {
    struct statfs statBuf; char *name; name = \"/\";
    statfs (name, &statBuf, sizeof (statBuf));
}
"
    cleardata $ARGS
    setdata $ARGS incheaders all
    setdata $ARGS nounlink 0
    setdata $ARGS otherlibs ""
    setdata $ARGS tryextern 0
    check_link "${name}" "${code}"
    rc=$?
    if [ $rc -eq 0 ]
    then
        trc=1
        echo "## [$name] yes" >> $LOG
        echo "yes"
    else
        echo "## [$name] no" >> $LOG
        echo "no"
    fi
    setdata $CFG $name $trc
}

check_statfs_4arg () {
    name=$1

    echo "## [$name] statfs(): 4 arguments ... " >> $LOG
    echo ${EN} "statfs(): 4 arguments ... ${EC}"

    trc=0
    code="
main () {
    struct statfs statBuf; char *name; name = \"/\";
    statfs (name, &statBuf, sizeof (statBuf), 0);
}
"
    cleardata $ARGS
    setdata $ARGS incheaders all
    setdata $ARGS nounlink 0
    setdata $ARGS otherlibs ""
    setdata $ARGS tryextern 0
    check_link "${name}" "${code}"
    rc=$?
    if [ $rc -eq 0 ]
    then
        trc=1
        echo "## [$name] yes" >> $LOG
        echo "yes"
    else
        echo "## [$name] no" >> $LOG
        echo "no"
    fi
    setdata $CFG $name $trc
}


check_size () {
    name=$1
    type=$2

    echo "## [$name] sizeof: $type ... " >> $LOG
    echo ${EN} "sizeof: $type ... ${EC}"
    code="main () { printf(\"%u\\\\n\", sizeof(${type})); exit (0); }"
    val=0
    val=`check_run "${name}" "${code}"`
    rc=$?
    if [ $rc -eq 0 ]
    then
        echo "## [$name] $val" >> $LOG
        echo "$val"
    else
        echo "## [$name] no" >> $LOG
        echo "no"
    fi
    setdata $CFG "${name}" "${val}"
}

check_int_declare () {
    name=$1
    function=$2

    echo "## [$name] declared: $function ... " >> $LOG
    echo ${EN} "declared: $function ... ${EC}"
    trc=0
    code="main () { int x; x = ${function}; }"
    cleardata $ARGS
    setdata $ARGS incheaders all
    check_compile "${name}" "${code}"
    rc=$?
    if [ $rc -eq 0 ]
    then
        trc=1
        echo "## [$name] yes" >> $LOG
        echo "yes"
    else
        echo "## [$name] no" >> $LOG
        echo "no"
    fi
    setdata $CFG $name $trc
}

check_ptr_declare () {
    name=$1
    function=$2

    echo "## [$name] declared: $function ... " >> $LOG
    echo ${EN} "declared: $function ... ${EC}"
    trc=0
    code="main () { _VOID_ *x; x = ${function}; }"
    cleardata $ARGS
    setdata $ARGS incheaders all
    check_compile "${name}" "${code}"
    rc=$?
    if [ $rc -eq 0 ]
    then
        trc=1
        echo "## [$name] yes" >> $LOG
        echo "yes"
    else
        echo "## [$name] no" >> $LOG
        echo "no"
    fi
    setdata $CFG $name $trc
}

check_npt () {
    name=$1
    proto=$2

    echo "## [$name] need prototype: $proto ... " >> $LOG
    echo ${EN} "need prototype: $proto ... ${EC}"
    trc=0
    code="
_BEGIN_EXTERNS_
struct _TEST_struct { int _TEST_member; };
extern struct _TEST_struct* ${proto} _ARG_((struct _TEST_struct*));
_END_EXTERNS_
"
    cleardata $ARGS
    setdata $ARGS incheaders all
    check_compile "${name}" "${code}"
    rc=$?
    if [ $rc -eq 0 ]
    then
        trc=1
        echo "## [$name] yes" >> $LOG
        echo "yes"
    else
        echo "## [$name] no" >> $LOG
        echo "no"
    fi
    setdata $CFG $name $trc
}

check_command () {
    name=$1
    cmd=$2

    echo "## [$name] command $cmd ... " >> $LOG
    echo ${EN} "command: $cmd ... ${EC}"

    trc=0
    pth="`echo ${PATH} | sed 's/[;:]/ /g'`"
    for p in $pth
    do
        if [ $trc -eq  0 -a -x "$p/$cmd" ]
        then
            trc=1
            echo "## [$name] yes" >> $LOG
            echo "yes"
        fi
    done
    if [ $trc -eq 0 ]
    then
        echo "## [$name] no" >> $LOG
        echo "no"
    fi
    setdata $CFG $name $trc
}

check_lib () {
    name=$1
    func=$2

    trc=0
    code="
typedef int (*_TEST_fun_)();
#ifdef _TRY_extern_
_BEGIN_EXTERNS_
extern int ${func}();
_END_EXTERNS_
#endif
static _TEST_fun_ i=(_TEST_fun_) ${func};
main () {  return (i==0); }
"
    otherlibs=`getdata $ARGS otherlibs`

    if [ "${otherlibs}" != "" ]
    then
        echo "## [$name] function: $func [$otherlibs] ... " >> $LOG
        echo ${EN} "function: $func [$otherlibs] ... ${EC}"
    else
        echo "## [$name] function: $func ... " >> $LOG
        echo ${EN} "function: $func ... ${EC}"
    fi

    cleardata $ARGS
    setdata $ARGS incheaders all
    setdata $ARGS nounlink 0
    setdata $ARGS otherlibs "${otherlibs}"
    setdata $ARGS tryextern 0
    dlibs=`check_link "${name}" "${code}"`
    rc=$?
    if [ $rc -eq 0 ]
    then
        trc=1
        echo ${EN} "## [$name] yes${EC}" >> $LOG
        echo ${EN} "yes${EC}"
        if [ "$dlibs" != "" ]
        then
            echo ${EN} " with ${dlibs} ${EC}" >> $LOG
            echo ${EN} " with ${dlibs} ${EC}"
        fi
        echo "" >> $LOG
        echo ""
    else
        echo "## [$name] no" >> $LOG
        echo "no"
    fi
    setdata $CFG $name $trc
    return $trc
}

check_class () {
    name=$1
    class=$2

    trc=0
    code=" main () { ${class} testclass; } "
    otherlibs=`getdata $ARGS otherlibs`

    if [ "$otherlibs" != "" ]
    then
        echo "## [$name] class: $class [$val] ... " >> $LOG
        echo ${EN} "class: $class [$val] ... ${EC}"
    else
        echo "## [$name] class: $class ... " >> $LOG
        echo ${EN} "class: $class ... ${EC}"
    fi

    cleardata $ARGS
    setdata $ARGS incheaders all
    setdata $ARGS nounlink 0
    setdata $ARGS otherlibs "${otherlibs}"
    setdata $ARGS tryextern 0
    dlibs=`check_link ${name} ${code}`
    rc=$?
    if [ $rc -eq 0 ]
    then
        trc=1
        echo ${EN} "## [$name] yes${EC}" >> $LOG
        echo ${EN} "yes${EC}"
        if [ "${dlibs}" != "" ]
        then
            echo ${EN} " with ${dlibs}${EC}" >> $LOG
            echo ${EN} " with ${dlibs}${EC}"
        fi
        echo "" >> $LOG
        echo ""
    else
        echo "## [$name] no" >> $LOG
        echo "no"
    fi
    setdata $CFG $name $trc
}

# malloc.h conflicts w/string.h on some systems.
check_include_malloc () {
    name=$1

    trc=0
    _hdr_malloc=`getdata $CFG _hdr_malloc`
    _hdr_string=`getdata $CFG _hdr_string`
    if [ "${_hdr_string}" = "string.h" -a "${_hdr_malloc}" = "malloc.h" ]
    then
        echo "## [$name] header: include malloc.h ... " >> $LOG
        echo ${EN} "header: include malloc.h ... ${EC}"

        code="
#include <string.h>
#include <malloc.h>
main () { char *x; x = (char *) malloc (20); }"
        cleardata $ARGS
        setdata $ARGS incheaders std
        check_compile "${name}" "${code}"
        rc=$?
        if [ $rc -eq 0 ]
        then
            trc=1
            echo "## [$name] yes" >> $LOG
            echo "yes"
        else
            echo "## [$name] no" >> $LOG
            echo "no"
        fi
    fi
    setdata $CFG "${name}" $trc
}

check_include_string () {
    name=$1

    trc=0
    _hdr_string=`getdata $CFG _hdr_string`
    _hdr_strings=`getdata $CFG _hdr_strings`
    if [ "${_hdr_string}" = "string.h" -a "${_hdr_strings}" = "strings.h" ]
    then
        echo "## [$name] header: include both string.h & strings.h ... " >> $LOG
        echo ${EN} "header: include both string.h & strings.h ... ${EC}"

        code="#include <string.h>
#include <strings.h>
main () { char *x; x = \"xyz\"; strcat (x, \"abc\"); }
"
        cleardata $ARGS
        setdata $ARGS incheaders std
        check_compile "${name}" "${code}"
        rc=$?
        if [ $rc -eq 0 ]
        then
            trc=1
            echo "## [$name] yes" >> $LOG
            echo "yes"
        else
            echo "## [$name] no" >> $LOG
            echo "no"
        fi
    fi
    setdata $CFG $name $trc
}

create_config () {
    configfile=$1
    cleardata $CFG
    setdata $CFG reqlibs ""

    > $CONFH
    cat <<_HERE_ >> $CONFH

#ifndef _config_H
#define _config_H 1

_HERE_

    cleardata $ARGS
    setdata $ARGS reqhdr ""
    check_header "_hdr_stdlib" "stdlib.h"
    check_header "_hdr_stdio" "stdio.h"
    check_header "_sys_types" "sys/types.h"
    check_header "_sys_param" "sys/param.h"

    check_keyword "_key_void" "void"
    check_keyword "_key_const" "const"
    check_proto "_proto_stdc"

    ininclude=0
    inheaders=1
    include=""
    while read tdatline
    do
        case ${tdatline} in
            "")
                ;;
            \#*)
                ;;
            hdr*|sys*)
                ;;
            *)
                if [ $inheaders -eq 1 ]
                then
                    check_include_malloc '_include_malloc'
                    check_include_string '_include_string'
                fi
                inheaders=0
                ;;
        esac

        if [ $ininclude -eq 1 ]
        then
            if [ "${tdatline}" = "endinclude" ]
            then
                echo "end include" >> $LOG
                ininclude=0
            else
                include="${include}
${tdatline}"
            fi
        fi

        case ${tdatline} in
            "")
                ;;
            \#*)
                ;;
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
                setdata $ARGS reqhdr "$reqhdr"
                check_header $nm $hdr
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
                check_lib $nm "${func}"
                rc=$?
                if [ $func = 'setmntent' -a $rc -eq 1 ]
                then
                    check_setmntent_1arg '_setmntent_1arg'
                    check_setmntent_2arg '_setmntent_2arg'
                fi
                if [ $func = 'statfs' -a $rc -eq 1 ]
                then
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
                cleardata $ARGS
                setdata $ARGS otherlibs "${libs}"
                check_class $nm "${class}"
                ;;
            command*)
                set $tdatline
                cmd=$2
                nm=`echo "_command_${cmd}" | tr '[A-Z]' '[a-z]'`
                check_command $nm $cmd
                ;;
            npt*)
                set $tdatline
                func=$2
                req=$3
                nm=`echo "_npt_${func}" | tr '[A-Z]' '[a-z]'`
                check_npt "${nm}" "${func}"
                ;;
            dcl*)
                set $tdatline
                type=$2
                var=$3
                nm=`echo "_dcl_${var}" | tr '[A-Z]' '[a-z]'`
                if [ "$type" = "int" ]
                then
                    check_int_declare $nm $var
                elif [ "$type" = "ptr" ]
                then
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
                ;;
        esac
    done < $configfile

    while read tline
    do
        set ${tline}
        nm=$1
        val=$2
        if [ "${val}" = "0" ]
        then
            echo "#undef ${nm}" >> $CONFH
        else
            case ${nm} in
                reqlibs)
                    echo > $REQLIB
                    echo "${val}" >> $REQLIB
                    ;;
                _siz_*)
                    echo "#define ${nm} ${val}" >> $CONFH
                    ;;
                *)
                    echo "#define ${nm} 1" >> $CONFH
                    ;;
            esac
        fi
    done < $CFG

    cat << _HERE_ >> $CONFH

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

    echo "${include}" >> ${CONFH}

    cat << _HERE_ >> ${CONFH}

#endif /* _config_H */
_HERE_

}

# main

if [ $# -ne 1 ]
then
    echo "Usage: $0 <config-file>"
    exit 1
fi
configfile=$1
echo -n 'test' | egrep -- '-n' # > /dev/null 2>&1
rc=$?
if [ $rc -eq 0 ]
then
    EN=''
    EC='\c'
fi

test -d $TMP && rm -rf $TMP > /dev/null 2>&1
mkdir $TMP
cd $TMP

rm -f $LOG > /dev/null 2>&1
CFLAGS="${CFLAGS} ${CINCLUDES}"
echo "CC: ${CC}" >> $LOG
echo "CFLAGS: ${CFLAGS}" >> $LOG
echo "LDFLAGS: ${LDFLAGS}" >> $LOG
echo "LIBS: ${LIBS}" >> $LOG

create_config $configfile

cd ..
#test -d $TMP && rm -rf $TMP > /dev/null 2>&1
exit 0
