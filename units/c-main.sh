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
#       #if ! _key_void
#       # define void int
#       #endif
#       #if ! _key_const
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

#
# speed at the cost of maintainability...
# File Descriptors:
#    9 - >>$LOG                     (mkconfig.sh)
#    8 - >>$VARSFILE, >>$CONFH      (mkconfig.sh)
#    7 - temporary for mkconfig.sh  (mkconfig.sh)
#    6 - temporary for c-main.sh    (c-main.sh)
#    5 - temporary for c-main.sh    (c-main.sh)
#

_MKCONFIG_PREFIX=c
_MKCONFIG_HASEMPTY=F
_MKCONFIG_EXPORT=F
PH_PREFIX="mkc_ph."
PH_STD=F

REQLIB="../reqlibs.txt"

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

  echo "CC: ${CC}" >&9
  echo "CFLAGS: ${CFLAGS}" >&9
  echo "LDFLAGS: ${LDFLAGS}" >&9
  echo "LIBS: ${LIBS}" >&9

  if [ "${CC}" = "" ]; then
    echo "No compiler specified" >&2
    return
  fi

  cat  << _HERE_
#ifndef __INC_CONFIG_H
#define __INC_CONFIG_H 1

_HERE_
}

stdconfigfile () {
  pc_configfile=$1
  cat << _HERE_

#if ! _key_void
# define void int
#endif
#if ! _key_const
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
  cat << _HERE_

#endif /* __INC_CONFIG_H */
_HERE_
}

standard_checks () {
  if [ "${CC}" = "" ]; then
    echo "No compiler specified" >&2
    return
  fi

  check_hdr hdr "stdio.h"
  check_hdr hdr "stdlib.h"
  check_hdr sys "types.h"
  check_hdr sys "param.h"
  PH_STD=T
  check_key key "void"
  check_key key "const"
  check_proto "_proto_stdc"
}

_print_headers () {
  incheaders=$1

  out="${PH_PREFIX}${incheaders}"

  if [ -f $out ]; then
    cat $out
    return
  fi

  if [ "$PH_STD" = "T" -a "$incheaders" = "std" ]; then
    _print_hdrs std > $out
    cat $out
    return
  fi

  if [ "$incheaders" = "all" ]; then
    _print_hdrs all > $out
    cat $out
    return
  fi

  # until PH_STD becomes true, just do normal processing.
  _print_hdrs $incheaders
}

_print_hdrs () {
  incheaders=$1

  if [ "${incheaders}" = "all" -o "${incheaders}" = "std" ]; then
      for tnm in '_hdr_stdio' '_hdr_stdlib' '_sys_types' '_sys_param'; do
          getdata tval ${_MKCONFIG_PREFIX} ${tnm}
          if [ "${tval}" != "0" -a "${tval}" != "" ]; then
              echo "#include <${tval}>"
          fi
      done
  fi

  if [ "${incheaders}" = "all" -a -f "$VARSFILE" ]; then
    exec 5<&0 < ${VARSFILE}
    while read cfgvar; do
      getdata hdval ${_MKCONFIG_PREFIX} ${cfgvar}
      case ${cfgvar} in
        _hdr_stdio|_hdr_stdlib|_sys_types|_sys_param)
            ;;
        _sys_time)
            getdata htval ${_MKCONFIG_PREFIX} '_hdr_time'
            getdata itval ${_MKCONFIG_PREFIX} '_include_time'
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
    exec <&5 5<&-
  fi
}

_chk_run () {
  crname=$1
  code=$2
  inc=$3

  _chk_link_libs ${crname} "${code}" $inc
  rc=$?
  echo "##  run test: link: $rc" >&9
  rval=0
  if [ $rc -eq 0 ]; then
      rval=`./${crname}.exe`
      rc=$?
      echo "##  run test: run: $rc" >&9
      if [ $rc -lt 0 ]; then
          exitmkconfig $rc
      fi
  fi
  _retval=$rval
  return $rc
}

_chk_link_libs () {
  cllname=$1
  code=$2
  inc=$3
  shift;shift;shift

  ocounter=0
  clotherlibs=$otherlibs
  if [ "${clotherlibs}" != "" ]; then
      set -- $clotherlibs
      ocount=$#
  else
      ocount=0
  fi

  tcfile=${cllname}.c
  # $cllname should be unique
  exec 6>>${tcfile}
  echo "${precc}" >&6
  _print_headers $inc >&6
  echo "${code}" | sed 's/_dollar_/$/g' >&6
  exec 6>&-

  dlibs=""
  otherlibs=""
  _chk_link $cllname
  rc=$?
  echo "##      link test (none): $rc" >&9
  if [ $rc -ne 0 ]; then
      while test $ocounter -lt $ocount; do
          domath ocounter "$ocounter + 1"
          set -- $clotherlibs
          tcounter=0
          olibs=""
          while test $tcounter -lt $ocounter; do
              doappend olibs " $1"
              shift
              domath tcounter "$tcounter + 1"
          done
          dlibs=${olibs}
          otherlibs=${olibs}
          _chk_link $cllname
          rc=$?
          echo "##      link test (${olibs}): $rc" >&9
          if [ $rc -eq 0 ]; then
              break
          fi
      done
  fi
  _retdlibs=$dlibs
  return $rc
}

_chk_link () {
  clname=$1

  cmd="${CC} ${CFLAGS} -o ${clname}.exe ${clname}.c "
  cmd="${cmd} ${LDFLAGS} ${LIBS} "
  _clotherlibs=$otherlibs
  if [ "${_clotherlibs}" != "" ]; then
      cmd="${cmd} ${_clotherlibs} "
  fi
  echo "##  _link test: $cmd" >&9
  cat ${clname}.c >&9
  eval $cmd >&9 2>&9
  rc=$?
  if [ $rc -lt 0 ]; then
      exitmkconfig $rc
  fi
  echo "##      _link test: $rc" >&9
  if [ $rc -eq 0 ]; then
    if [ ! -x "${clname}.exe" ]; then  # not executable
      rc=1
    fi
  fi
  return $rc
}


_chk_compile () {
  ccname=$1
  code=$2
  inc=$3

  tcfile=${ccname}.c
  # $ccname should be unique
  exec 6>>${tcfile}
  echo "${precc}" >&6
  _print_headers $inc >&6
  echo "${code}" >&6
  exec 6>&-

  cmd="${CC} ${CFLAGS} -c ${tcfile}"
  echo "##  compile test: $cmd" >&9
  cat ${ccname}.c >&9
  eval ${cmd} >&9 2>&9
  rc=$?
  echo "##  compile test: $rc" >&9
  return $rc
}


do_check_compile () {
  dccname=$1
  code=$2
  inc=$3

  _chk_compile ${dccname} "${code}" $inc
  rc=$?
  try=0
  if [ $rc -eq 0 ]; then
      try=1
  fi
  printyesno $dccname $try
  setdata ${_MKCONFIG_PREFIX} ${dccname} ${try}
}

check_hdr () {
  type=$1
  hdr=$2
  shift;shift
  reqhdr=$*
  # input may be:  ctype.h kernel/fs_info.h
  #    storage/Directory.h
  nm1=`echo ${hdr} | sed -e 's,/.*,,'`
  nm2="_`echo $hdr | sed -e \"s,^${nm1},,\" -e 's,^/*,,'`"
  nm="_${type}_${nm1}"
  if [ "$nm2" != "_" ]; then
    doappend nm $nm2
  fi
  dosubst nm '/' '_' ':' '_' '\.h' ''
  case ${type} in
    sys)
      hdr="sys/${hdr}"
      ;;
  esac

  name=$nm
  file=$hdr

  printlabel $name "header: ${file}"
  checkcache ${_MKCONFIG_PREFIX} $name
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
  _chk_compile ${name} "${code}" std
  rc=$?
  val=0
  if [ $rc -eq 0 ]; then
      val=${file}
  fi
  printyesno $name $val
  setdata ${_MKCONFIG_PREFIX} ${name} ${val}
}

check_sys () {
  check_hdr $@
}

check_const () {
  constant=$2
  shift;shift
  reqhdr=$*
  nm="_const_${constant}"

  name=$nm

  printlabel $name "constant: ${constant}"
  checkcache ${_MKCONFIG_PREFIX} $name
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
  do_check_compile ${name} "${code}" all
}

check_key () {
  keyword=$2
  name="_key_${keyword}"

  printlabel $name "keyword: ${keyword}"
  checkcache ${_MKCONFIG_PREFIX} $name
  if [ $rc -eq 0 ]; then return; fi

  code="main () { int ${keyword}; ${keyword} = 1; exit (0); }"

  _chk_compile ${name} "${code}" std
  rc=$?
  trc=0
  if [ $rc -ne 0 ]; then  # failure means it is reserved...
    trc=1
  fi
  printyesno $name $trc
  setdata ${_MKCONFIG_PREFIX} ${name} ${trc}
}

check_proto () {
  name=$1

  printlabel $name "supported: prototypes"
  checkcache ${_MKCONFIG_PREFIX} $name
  if [ $rc -eq 0 ]; then return; fi

  code='
_BEGIN_EXTERNS_
extern int foo (int, int);
_END_EXTERNS_
int bar () { int rc; rc = foo (1,1); return 0; }
'

  do_check_compile ${name} "${code}" std
}

check_typ () {
  type=$2
  nm="_typ_${type}"

  name=$nm

  printlabel $name "type: ${type}"
  checkcache ${_MKCONFIG_PREFIX} $name
  if [ $rc -eq 0 ]; then return; fi

  code="
struct xxx { ${type} mem; };
static struct xxx v;
struct xxx* f() { return &v; }
main () { struct xxx *tmp; tmp = f(); exit (0); }
"

  do_check_compile ${name} "${code}" all
}

check_member () {
  struct=$2
  member=$3
  nm="_mem_${member}_${struct}"

  name=$nm

  printlabel $name "exists: ${struct}.${member}"
  checkcache ${_MKCONFIG_PREFIX} $name
  if [ $rc -eq 0 ]; then return; fi

  code="main () { struct ${struct} s; int i; i = sizeof (s.${member}); }"

  do_check_compile ${name} "${code}" all
}


check_size () {
  shift
  type=$*
  nm="_siz_${type}"
  dosubst nm ' ' '_'

  name=$nm

  printlabel $name "sizeof: ${type}"
  checkcache_val ${_MKCONFIG_PREFIX} $name
  if [ $rc -eq 0 ]; then return; fi

  code="main () { printf(\"%u\", sizeof(${type})); exit (0); }"
  _chk_run ${name} "${code}" all
  rc=$?
  val=$_retval
  if [ $rc -ne 0 ]; then
    val=0
  fi
  printyesno_val $name $val
  setdata ${_MKCONFIG_PREFIX} ${name} ${val}
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
  checkcache ${_MKCONFIG_PREFIX} $name
  if [ $rc -eq 0 ]; then return; fi

  code="main () { int x; x = ${function}; }"
  do_check_compile ${name} "${code}" all
}

check_ptr_declare () {
  name=$1
  function=$2

  printlabel $name "declared: ${function}"
  checkcache ${_MKCONFIG_PREFIX} $name
  if [ $rc -eq 0 ]; then return; fi

  code="main () { _VOID_ *x; x = ${function}; }"
  do_check_compile ${name} "${code}" all
}

check_npt () {
  func=$2
  req=$3

  has=1
  if [ "${req}" != "" ]; then
    getdata has ${_MKCONFIG_PREFIX} "${req}"
  fi
  nm="_npt_${func}"

  name=$nm
  proto=$func

  printlabel $name "need prototype: ${proto}"
  checkcache ${_MKCONFIG_PREFIX} $name
  if [ $rc -eq 0 ]; then return; fi

  if [ ${has} -eq 0 ]; then
    setdata ${_MKCONFIG_PREFIX} ${name} 0
    printyesno $name 0
    return
  fi

  code="
_BEGIN_EXTERNS_
struct _TEST_struct { int _TEST_member; };
extern struct _TEST_struct* ${proto} _ARG_((struct _TEST_struct*));
_END_EXTERNS_
"
  do_check_compile ${name} "${code}" all
}

check_lib () {
  func=$2
  shift;shift
  libs=$*
  nm="_lib_${func}"
  otherlibs=${libs}

  name=$nm

  rfunc=$func
  dosubst rfunc '_dollar_' '$'
  if [ "${otherlibs}" != "" ]; then
      printlabel $name "function: ${rfunc} [${otherlibs}]"
  else
      printlabel $name "function: ${rfunc}"
      checkcache ${_MKCONFIG_PREFIX} $name
      if [ $rc -eq 0 ]; then return; fi
  fi

  trc=0
  # unfortunately, this does not work if the function
  # is not declared.
  code="
_BEGIN_EXTERNS_
typedef int (*_TEST_fun_)();
static _TEST_fun_ i=(_TEST_fun_) ${func};
_END_EXTERNS_
main () {  i(); return (i==0); }
"

  _chk_link_libs ${name} "${code}" all
  rc=$?
  dlibs=$_retdlibs
  if [ $rc -eq 0 ]; then
      trc=1
  fi
  tag=""
  if [ $rc -eq 0 -a "$dlibs" != "" ]; then
    tag=" with ${dlibs}"
    doappend reqlibs " ${dlibs}"
  fi

  if [ ${trc} -eq 0 -a "$_MKCONFIG_TEST_EXTERN" != "" ]; then
    # Normally, we don't want to do this, as
    # on some systems we can get spurious errors
    # where the lib does not exist and the link works!
    # On modern systems, this simply isn't necessary.
    code="
_BEGIN_EXTERNS_
  extern int ${func}();
  typedef int (*_TEST_fun_)();
  static _TEST_fun_ i=(_TEST_fun_) ${func};
_END_EXTERNS_
  main () {  i(); return (i==0); }
  "
    _chk_link_libs ${name} "${code}" all
    rc=$?
    dlibs=$_retdlibs
    if [ $rc -eq 0 ]; then
        trc=1
    fi
    tag=""
    if [ $rc -eq 0 -a "$dlibs" != "" ]; then
      tag=" with ${dlibs}"
      doappend reqlibs " ${dlibs}"
    fi
  fi

  printyesno $name $trc "$tag"
  setdata ${_MKCONFIG_PREFIX} ${name} ${trc}
  return $trc
}

check_class () {
  class=$2
  shift;shift
  libs=$*
  nm="_class_${class}"
  dosubst nm '/' '_' ':' '_'
  otherlibs=${libs}

  name=$nm

  trc=0
  code=" main () { ${class} testclass; } "

  if [ "$otherlibs" != "" ]; then
      printlabel $name "class: ${class} [${otherlibs}]"
  else
      printlabel $name "class: ${class}"
      checkcache ${_MKCONFIG_PREFIX} $name
      if [ $rc -eq 0 ]; then return; fi
  fi

  _chk_link_libs ${name} "${code}" all
  rc=$?
  if [ $rc -eq 0 ]; then
      trc=1
  fi
  tag=""
  if [ $rc -eq 0 -a "${dlibs}" != "" ]; then
      tag=" with ${dlibs}"
      doappend reqlibs " ${dlibs}"
  fi
  printyesno $name $trc "$tag"
  setdata ${_MKCONFIG_PREFIX} ${name} ${trc}
}

output_item () {
  out=$1
  name=$2
  val=$3

  tval=0
  if [ "$val" != "0" ]; then
    tval=1
  fi
  case ${name} in
    _hdr*|_sys*|_command*)
      echo "#define ${name} ${tval}"
      ;;
    *)
      echo "#define ${name} ${val}"
      ;;
  esac
}

output_other () {
  out=$1

  > $REQLIB
  echo $reqlibs >> $REQLIB
}
