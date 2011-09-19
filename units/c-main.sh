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
#       #if ! _key_void || ! _param_void_star
#         typedef char *_pvoid;
#       #else
#         typedef void *_pvoid;
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
#    4 - temporary for c-main.sh    (c-main.sh)
#

require_unit c-support

_MKCONFIG_PREFIX=c
_MKCONFIG_HASEMPTY=F
_MKCONFIG_EXPORT=F
PH_PREFIX="mkc_ph."
PH_STD=F
PH_ALL=F

precc='
#if defined(__STDC__) || defined(__cplusplus) || defined(c_plusplus)
# define _(x) x
#else
# define _(x) ()
# define void char
#endif
#if defined(__cplusplus) || defined (c_plusplus)
# define CPP_EXTERNS_BEG extern "C" {
# define CPP_EXTERNS_END }
CPP_EXTERNS_BEG
extern int printf (const char *, ...);
CPP_EXTERNS_END
#else
# define CPP_EXTERNS_BEG
# define CPP_EXTERNS_END
#endif
'

preconfigfile () {
  pc_configfile=$1

  echo "CC: ${CC}" >&9
  echo "CFLAGS: ${CFLAGS}" >&9
  echo "CPPFLAGS: ${CPPFLAGS}" >&9
  echo "LDFLAGS: ${LDFLAGS}" >&9
  echo "LIBS: ${LIBS}" >&9

  if [ "${CC}" = "" ]; then
    echo "No compiler specified" >&2
    return
  fi

  echo '#ifndef __INC_CONFIG_H
#define __INC_CONFIG_H 1
'
}

stdconfigfile () {
  pc_configfile=$1
  echo '
#if ! _key_void
# define void int
#endif
#if ! _key_void || ! _param_void_star
  typedef char *_pvoid;
#else
  typedef void *_pvoid;
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
'
}

postconfigfile () {
  pc_configfile=$1
  echo '
#endif /* __INC_CONFIG_H */'
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
  check_param_void_star
  check_proto "_proto_stdc"
  PH_ALL=T
}

check_hdr () {
  type=$1
  hdr=$2
  shift;shift
  reqhdr=$*
  # input may be:  ctype.h kernel/fs_info.h
  #    storage/Directory.h
  nm1=`echo ${hdr} | sed -e 's,/.*,,'`
  nm2="_`echo $hdr | sed -e s,\^${nm1},, -e 's,^/*,,'`"
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
main () { return (0); }
"
  rc=1
  _c_chk_compile ${name} "${code}" std
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
main () { if (${constant} == 0) { 1; } return (0); }
"
  do_c_check_compile ${name} "${code}" all
}

check_key () {
  keyword=$2
  name="_key_${keyword}"

  printlabel $name "keyword: ${keyword}"
  checkcache ${_MKCONFIG_PREFIX} $name
  if [ $rc -eq 0 ]; then return; fi

  code="main () { int ${keyword}; ${keyword} = 1; return (0); }"

  _c_chk_compile ${name} "${code}" std
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
CPP_EXTERNS_BEG
extern int foo (int, int);
CPP_EXTERNS_END
int bar () { int rc; rc = foo (1,1); return 0; }
'

  do_c_check_compile ${name} "${code}" std
}

check_typ () {
  shift
  type=$@
  nm="_typ_${type}"
  dosubst nm ' ' '_'
  name=$nm
  dosubst type 'star' '*'

  printlabel $name "type: ${type}"
  checkcache ${_MKCONFIG_PREFIX} $name
  if [ $rc -eq 0 ]; then return; fi

  code="
struct xxx { ${type} mem; };
static struct xxx v;
struct xxx* f() { return &v; }
main () { struct xxx *tmp; tmp = f(); return (0); }
"

  do_c_check_compile ${name} "${code}" all
}

check_define () {
  shift
  def=$1
  nm="_define_${def}"
  name=$nm

  printlabel $name "defined: ${def}"
  checkcache ${_MKCONFIG_PREFIX} $name
  if [ $rc -eq 0 ]; then return; fi

  code="main () {
#ifdef ${def}
return (0);
#else
return (1);
#endif
}"

  _c_chk_run "$name" "$code" all
  rc=$?
  if [ $rc -eq 0 ]; then rc=1; else rc=0; fi
  setdata ${_MKCONFIG_PREFIX} ${name} ${rc}
  printyesno $name $rc
}

check_param_void_star () {
  name="_param_void_star"

  printlabel $name "parameter: void *"
  checkcache ${_MKCONFIG_PREFIX} $name
  if [ $rc -eq 0 ]; then return; fi

  code="
char *
tparamvs (ptr)
  void *ptr;
{
  ptr = (void *) NULL;
  return (char *) ptr;
}
"

  do_c_check_compile ${name} "${code}" all
}

check_member () {
  shift
  struct=$1
  if [ "$struct" = "struct" ]; then
    shift
    struct="struct $1"
  fi
  shift
  member=$1
  nm="_mem_${struct}_${member}"
  dosubst nm ' ' '_'

  name=$nm

  printlabel $name "exists: ${struct}.${member}"
  checkcache ${_MKCONFIG_PREFIX} $name
  if [ $rc -eq 0 ]; then return; fi

  code="main () { ${struct} s; int i; i = sizeof (s.${member}); }"

  do_c_check_compile ${name} "${code}" all
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

  code="main () { printf(\"%u\", sizeof(${type})); return (0); }"
  _c_chk_run ${name} "${code}" all
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

check_args () {
  type=$1
  noconst=F
  if [ "$2" = "noconst" ]; then
    noconst=T
    shift
  fi
  funcnm=$2

  nm="_args_${funcnm}"
  name=$nm

  printlabel $name "args: ${funcnm}"
  checkcache ${_MKCONFIG_PREFIX} $name
  if [ $rc -eq 0 ]; then return; fi

  trc=0
  ccount=0

  oldprecc="${precc}"
  doappend precc "/* get rid of most gcc-isms */
#define __asm__(a)
#define __attribute__(a)
#define __nonnull__(a,b)
#define __restrict
#define __THROW
#define __const const
"

  code=""
  _c_chk_cpp ${name} "" all
  rc=$?

  precc="${oldprecc}"

  if [ $rc -eq 0 ]; then
    egrep "[	 *]${funcnm}[	 ]*\(" $name.out >/dev/null 2>&1
    rc=$?
    if [ $rc -eq 0 ]; then
      trc=1
    fi

    # have a declaration
    if [ $trc -eq 1 ]; then
      dcl=`${awkcmd} -f ${_MKCONFIG_DIR}/mkcextdcl.awk ${name}.out ${funcnm}`
      dcl=`echo $dcl` # make single line
      # extern will be replaced
      # ; may or may not be present, so remove it.
      cmd="dcl=\`echo \"\$dcl\" | sed -e 's/extern *//' -e 's/;//' \`"
      eval $cmd
      echo "## dcl(A): ${dcl}" >&9
      cmd="dcl=\`echo \"\$dcl\" | sed -e 's/( *void *)/()/' \`"
      eval $cmd
      echo "## dcl(C): ${dcl}" >&9
      c=`echo ${dcl} | sed 's/[^,]*//g'`
      ccount=`echo ${EN} "$c${EC}" | wc -c`
      domath ccount "$ccount + 1"  # 0==1 also, unfortunately
      c=`echo ${dcl} | sed 's/^[^(]*(//'`
      c=`echo ${c} | sed 's/)[^)]*$//'`
      echo "## c(E): ${c}" >&9
      val=1
      while test "${c}" != ""; do
        tmp=$c
        tmp=`echo ${c} | sed -e 's/ *,.*$//' -e 's/[	 ]/ /g'`
        dosubst tmp 'struct ' 'struct#' 'union ' 'union#' 'enum ' 'enum#'
        # only do the following if the names of the variables are declared
        echo ${tmp} | grep ' ' > /dev/null 2>&1
        rc=$?
        if [ $rc -eq 0 ]; then
          tmp=`echo ${tmp} | sed -e 's/ *[A-Za-z0-9_]*$//'`
        fi
        dosubst tmp 'struct#' 'struct ' 'union#' 'union ' 'enum#' 'enum '
        if [ $noconst = T ]; then
          tmp=`echo ${tmp} | sed -e 's/const *//'`
        fi
        echo "## tmp(F): ${tmp}" >&9
        nm="_c_arg_${val}_${funcnm}"
        setdata ${_MKCONFIG_PREFIX} ${nm} "${tmp}"
        domath val "$val + 1"
        c=`echo ${c} | sed -e 's/^[^,]*//' -e 's/^[	 ,]*//'`
        echo "## c(G): ${c}" >&9
      done
      c=`echo ${dcl} | sed -e 's/[ 	]/ /g' \
            -e "s/\([ \*]\)${funcnm}[ (].*/\1/" \
            -e 's/^ *//' \
            -e 's/ *$//'`
      echo "## c(T0): ${c}" >&9
      if [ $noconst = T ]; then
        c=`echo ${c} | sed -e 's/const *//'`
      fi
      echo "## c(T1): ${c}" >&9
      nm="_c_type_${funcnm}"
      setdata ${_MKCONFIG_PREFIX} ${nm} "${c}"
    fi
  fi

  printyesno_val $name $ccount ""
  nm="_args_${funcnm}"
  setdata ${_MKCONFIG_PREFIX} ${nm} ${ccount}
}

check_int_declare () {
  name=$1
  function=$2

  printlabel $name "declared: ${function}"
  checkcache ${_MKCONFIG_PREFIX} $name
  if [ $rc -eq 0 ]; then return; fi

  code="main () { int x; x = ${function}; }"
  do_c_check_compile ${name} "${code}" all
}

check_ptr_declare () {
  name=$1
  function=$2

  printlabel $name "declared: ${function}"
  checkcache ${_MKCONFIG_PREFIX} $name
  if [ $rc -eq 0 ]; then return; fi

  code="main () { void *x; x = ${function}; }"
  do_c_check_compile ${name} "${code}" all
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
CPP_EXTERNS_BEG
struct _TEST_struct { int _TEST_member; };
extern struct _TEST_struct* ${proto} _((struct _TEST_struct*));
CPP_EXTERNS_END
"
  do_c_check_compile ${name} "${code}" all
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
    # code to check the cache for which libraries is not written
  else
    printlabel $name "function: ${rfunc}"
    checkcache ${_MKCONFIG_PREFIX} $name
    if [ $rc -eq 0 ]; then return; fi
  fi

  trc=0
  # unfortunately, this does not work if the function
  # is not declared.
  code="
CPP_EXTERNS_BEG
typedef int (*_TEST_fun_)();
static _TEST_fun_ i=(_TEST_fun_) ${func};
CPP_EXTERNS_END
main () {  i(); return (i==0); }
"

  _c_chk_link_libs ${name} "${code}" all
  rc=$?
  dlibs=$_retdlibs
  if [ $rc -eq 0 ]; then
      trc=1
  fi
  tag=""
  if [ $rc -eq 0 -a "$dlibs" != "" ]; then
    tag=" with ${dlibs}"
    cmd="mkc_${_MKCONFIG_PREFIX}_lib_${name}=\"${dlibs}\""
    eval $cmd
  fi

  if [ ${trc} -eq 0 -a "$_MKCONFIG_TEST_EXTERN" != "" ]; then
    # Normally, we don't want to do this, as
    # on some systems we can get spurious errors
    # where the lib does not exist and the link works!
    # On modern systems, this simply isn't necessary.
    code="
CPP_EXTERNS_BEG
  extern int ${func}();
  typedef int (*_TEST_fun_)();
  static _TEST_fun_ i=(_TEST_fun_) ${func};
CPP_EXTERNS_END
  main () {  i(); return (i==0); }
  "
    _c_chk_link_libs ${name} "${code}" all
    rc=$?
    dlibs=$_retdlibs
    if [ $rc -eq 0 ]; then
        trc=1
    fi
    tag=""
    if [ $rc -eq 0 -a "$dlibs" != "" ]; then
      tag=" with ${dlibs}"
      cmd="mkc_${_MKCONFIG_PREFIX}_lib_${name}=\"${dlibs}\""
      eval $cmd
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

  _c_chk_link_libs ${name} "${code}" all
  rc=$?
  if [ $rc -eq 0 ]; then
      trc=1
  fi
  tag=""
  if [ $rc -eq 0 -a "${dlibs}" != "" ]; then
    tag=" with ${dlibs}"
    cmd="mkc_${_MKCONFIG_PREFIX}_lib_${name}=\"${dlibs}\""
    eval $cmd
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
    _setint_*)
      tname=$name
      dosubst tname '_setint_' ''
      echo "#define ${tname} ${val}"
      ;;
    _setstr_*|_opt_*)
      tname=$name
      dosubst tname '_setstr_' '' '_opt_' ''
      echo "#define ${tname} \"${val}\""
      ;;
    _hdr*|_sys*|_command*)
      echo "#define ${name} ${tval}"
      ;;
    *)      # _c_arg, _c_type go here also
      echo "#define ${name} ${val}"
      ;;
  esac
}

output_other () {
  return
}
