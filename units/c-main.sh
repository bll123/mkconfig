#!/bin/sh
#
# Copyright 2010-2018 Brad Lanam Walnut Creek CA USA
# Copyright 2020 Brad Lanam Pleasant Hill CA
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
#       #ifndef MKC_STANDARD_DEFS
#       # define MKC_STANDARD_DEFS 1
#       # if ! _key_void
#       #  define void int
#       # endif
#       # if ! _key_const
#       #  define const
#       # endif
#       # if ! _key_void || ! _param_void_star
#       #  define void char
#       # endif
#       #endif /* MKC_STANDARD_DEFS */
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

_MKCONFIG_HASEMPTY=F
_MKCONFIG_EXPORT=F
PH_PREFIX="mkc_ph."
PH_STD=F
PH_ALL=F

precc='
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
  configfile=$2

  # log all of the compiler and linker options
  for nm in CC CFLAGS_OPTIMIZE CFLAGS_DEBUG CFLAGS_INCLUDE CFLAGS_USER \
      CFLAGS_APPLICATION CFLAGS_COMPILER \
      CFLAGS_SYSTEM CFLAGS_SHARED \
      CFLAGS_SHARED_USER LDFLAGS_OPTIMIZE LDFLAGS_DEBUG LDFLAGS_USER \
      LDFLAGS_APPLICATION LDFLAGS_COMPILER LDFLAGS_SYSTEM \
      LDFLAGS_SHARED LDFLAGS_SHARED_LIBLINK LDFLAGS_SHARED_USER \
      LDFLAGS_LIBS_USER LDFLAGS_LIBS_APPLICATION LDFLAGS_LIBS_SYSTEM; do
    cmd="puts \"$nm: \${$nm}\""
    eval $cmd >&9
  done

  if [ "${CC}" = "" ]; then
    puts "No compiler specified" >&2
    return
  fi

  puts "/* Created on: `date`"
  puts "    From: ${configfile}"
  puts "    Using: mkconfig-${_MKCONFIG_VERSION} */"
  puts ''
  puts "#ifndef INC_${CONFHTAGUC}_H
#define INC_${CONFHTAGUC}_H 1
"
}

stdconfigfile () {
  pc_configfile=$1
  puts '
#ifndef MKC_STANDARD_DEFS
# define MKC_STANDARD_DEFS 1
# if ! _key_void
#  define void int
# endif
# if ! _key_void || ! _param_void_star
   typedef char *pvoid;
# else
   typedef void *pvoid;
# endif
# if ! _key_const
#  define const
# endif
#endif /* MKC_STANDARD_DEFS */
'
}

postconfigfile () {
  pc_configfile=$1
  puts "
#endif /* INC_${CONFHTAGUC}_H */"
}

standard_checks () {
  if [ "${CC}" = "" ]; then
    puts "No compiler specified" >&2
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

check_header_reset () {
  printlabel "" "reset headers"
  out="${PH_PREFIX}all"
  rm -f $out
}

check_hdr () {
  type=$1
  hdr=$2
  shift;shift

  reqhdr=$*
  # input may be:  ctype.h kernel/fs_info.h
  #    storage/Directory.h
  nm1=`puts ${hdr} | sed -e 's,/.*,,'`
  nm2="_`puts $hdr | sed -e s,\^${nm1},, -e 's,^/*,,'`"
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
int main (int argc, char *argv []) { return 0; }
"
  rc=1
  _c_chk_compile ${name} "${code}" std
  rc=$?
  val=0
  if [ $rc -eq 0 ]; then
      val=${file}
  fi

  if [ "$CPPCOUNTER" != "" ]; then
    domath CPPCOUNTER "$CPPCOUNTER + 1"
  fi
  printyesno $name $val
  setdata ${name} ${val}
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
int main (int argc, char *argv []) {
if (${constant} == 0) { 1; }
return 0;
}
"
  do_c_check_compile ${name} "${code}" all
}

check_key () {
  keyword=$2
  name="_key_${keyword}"

  printlabel $name "keyword: ${keyword}"
  checkcache $name
  if [ $rc -eq 0 ]; then return; fi

  code="int main (int argc, char *argv []) {
int ${keyword};
${keyword} = 1;
return 0;
}"

  _c_chk_compile ${name} "${code}" std
  rc=$?
  trc=0
  if [ $rc -ne 0 ]; then  # failure means it is reserved...
    trc=1
  fi
  printyesno $name $trc
  setdata ${name} ${trc}
}

check_proto () {
  name=$1

  printlabel $name "supported: prototypes"
  checkcache $name
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
  checkcache $name
  if [ $rc -eq 0 ]; then return; fi

  code="
struct xxx { ${type} mem; };
static struct xxx v;
struct xxx* f() { return &v; }
int main (int argc, char *argv []) {
struct xxx *tmp; tmp = f();
return 0;
}
"

  do_c_check_compile ${name} "${code}" all
}

check_define () {
  shift
  def=$1
  nm="_define_${def}"
  name=$nm

  printlabel $name "defined: ${def}"
  checkcache $name
  if [ $rc -eq 0 ]; then return; fi

  code="int main (int argc, char *argv []) {
#if defined(${def})
# define MKC_DEFINED 1
#endif
#ifdef MKC_DEFINED
printf (\"mkc_defined ${def}\");
#endif
return 0;
}"

  trc=0
  _c_chk_cpp "$name" "$code" all
  rc=$?
  if [ $rc -eq 0 ]; then
    ${grepcmd} -l mkc_defined $name.out >/dev/null 2>&1
    rc=$?
    if [ $rc -eq 0 ]; then
      trc=1
    fi
  fi
  setdata ${name} ${trc}
  printyesno $name $trc
}

check_param_void_star () {
  name="_param_void_star"

  printlabel $name "parameter: void *"
  checkcache $name
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
  if [ "$struct" = "union" ]; then
    shift
    struct="union $1"
  fi
  shift
  member=$1
  nm="_mem_${struct}_${member}"
  dosubst nm ' ' '_'

  name=$nm

  printlabel $name "exists: ${struct}.${member}"
  checkcache $name
  if [ $rc -eq 0 ]; then return; fi

  code="int main (int argc, char *argv []) {
${struct} s;
int i;
i = sizeof (s.${member});
return 0;
}"

  do_c_check_compile ${name} "${code}" all
}



check_memberxdr () {
  shift
  struct=$1
  shift
  member=$1

  nm="_memberxdr_${struct}_${member}"
  dosubst nm ' ' '_'
  name=$nm

  printlabel $name "member:XDR: ${struct} ${member}"
  # no cache

  _c_chk_cpp $name "" all
  rc=$?

  trc=0
  if [ $rc -eq 0 ]; then
    st=`${awkcmd} -f ${_MKCONFIG_DIR}/util/mkcextstruct.awk ${name}.out ${struct}`
    if [ "$st" != "" ]; then
      puts "  ${struct}: ${st}" >&9
      tmem=`puts "$st" | grep "${member} *;\$"`
      rc=$?
      puts "  found: ${tmem}" >&9
      if [ $rc -eq 0 ]; then
        mtype=`puts $tmem | sed -e "s/ *${member} *;$//" -e 's/^ *//'`
        puts "  type: ${mtype}" >&9
        trc=1
        setdata xdr_${member} xdr_${mtype}
      fi
    fi  # found the structure
  fi  # cpp worked

  printyesno $name $trc ""
  setdata ${name} ${trc}
}

check_size () {
  shift
  type=$*

  otherlibs="-lintl"
  nm="_siz_${type}"
  dosubst nm ' ' '_'

  name=$nm

  printlabel $name "sizeof: ${type}"

  if [ "$MKC_CROSS" = Y ]; then
    puts "## size: cross compiling is active" >&9
    code="int main (int argc, char *argv []) {
printf(\"%u\", sizeof(${type}));
return 0;
}"
    _c_chk_compile ${name} "${code}" all
    rc=$?
    if [ $rc -eq 0 ]; then
      sz=1
      # this could be sped up by moving the common sizes to the beginning
      # of the list of sizes to test.
      while test $sz -lt 129; do
        code="
#include <stdio.h>
#include <stdlib.h>

int
main () {
  size_t a = sizeof(int);

  switch (a) {
    case ${sz}:
    case sizeof(${type}):
    {
      break;
    }
  }
}
"
        _c_chk_compile ${name} "${code}" all
        trc=$?
        if [ $trc -ne 0 ]; then
          _retval=$sz
          rc=0
          break
        fi
        if [ $sz -eq 1 ]; then
          sz=2
        else
          domath sz "$sz + 2"
        fi
      done
    else
      _retval=0
      rc=1
    fi
  else
    puts "## size: cross compiling is NOT active" >&9
    code="int main (int argc, char *argv []) {
printf(\"%u\", sizeof(${type}));
return 0;
}"
    _c_chk_run ${name} "${code}" all
    rc=$?
  fi
  dlibs=$_retdlibs
  val=$_retval
  if [ $rc -ne 0 ]; then
    val=0
  fi
  if [ $rc -eq 0 -a "$dlibs" != "" ]; then
    cmd="mkc_lnk_${name}=\"${dlibs}\""
    eval $cmd
  fi
  otherlibs=""
  printyesno_val $name $val
  setdata ${name} ${val}
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
  # no cache

  trc=0
  ccount=0

  oldprecc="${precc}"

  if [ "$_have_variadic" = "" ]; then
    precc=""
    code="#define testvariadic(...)"
    _c_chk_cpp _args_testvariadic "$code" all
    rc=$?
    _have_variadic=F
    if [ $rc -eq 0 ]; then
      _have_variadic=T
    fi
  fi

  asmdef="#define __asm__(a)"
  if [ $_have_variadic = T ]; then
    asmdef="#define __asm__(...)"
  fi

  precc="$oldprecc"
  doappend precc "/* get rid of most gcc-isms */
#define __asm(a)
$asmdef
#define __attribute__(a)
#define __nonnull__(a,b)
#define __restrict
#define __restrict__
#if defined(__THROW)
# undef __THROW
#endif
#define __THROW
#define __const const
"
  code=""
  _c_chk_cpp ${name} "/**/" all   # force no-reuse due to precc.
  rc=$?

  precc="${oldprecc}"

  if [ $rc -eq 0 ]; then
    ${grepcmd} -l "[	 *]${funcnm}[	 ]*\(" $name.out >/dev/null 2>&1
    rc=$?
    if [ $rc -eq 0 ]; then
      trc=1
    fi

    # have a declaration
    if [ $trc -eq 1 ]; then
      dcl=`${awkcmd} -f ${_MKCONFIG_DIR}/util/mkcextdcl.awk ${name}.out ${funcnm}`
      # make single line, use no quotes
      # remove carriage returns...msys2 sometimes has them embedded.
      # \r is not recognized by older shells, use tr.
      dcl=`puts $dcl | tr '\r' ' '`
      # extern will be replaced
      # ; may or may not be present, so remove it.
      cmd="dcl=\`puts \"\$dcl\" | sed -e 's/extern *//' -e 's/;//' \`"
      eval $cmd
      puts "## dcl(A): ${dcl}" >&9
      cmd="dcl=\`puts \"\$dcl\" | sed -e 's/( *void *)/()/' \`"
      eval $cmd
      puts "## dcl(C): ${dcl}" >&9
      c=`puts "${dcl}" | sed 's/[^,]*//g'`
      ccount=`putsnonl "$c" | wc -c`
      domath ccount "$ccount + 1"  # 0==1 also, unfortunately
      c=`puts "${dcl}" | sed 's/^[^(]*(//'`
      c=`puts "${c}" | sed 's/)[^)]*$//'`
      puts "## c(E): ${c}" >&9
      val=1
      while test "${c}" != ""; do
        tmp=$c
        tmp=`puts "${c}" | sed -e 's/ *,.*$//' -e 's/[	 ]/ /g'`
        dosubst tmp 'struct ' 'struct#' 'union ' 'union#' 'enum ' 'enum#'
        # only do the following if the names of the variables are declared
        puts "${tmp}" | grep ' ' > /dev/null 2>&1
        rc=$?
        if [ $rc -eq 0 ]; then
          tmp=`puts "${tmp}" | sed -e 's/ *[A-Za-z0-9_]*$//'`
        fi
        dosubst tmp 'struct#' 'struct ' 'union#' 'union ' 'enum#' 'enum '
        if [ $noconst = T ]; then
          tmp=`puts "${tmp}" | sed -e 's/const *//'`
        fi
        puts "## tmp(F): ${tmp}" >&9
        nm="_c_arg_${val}_${funcnm}"
        setdata ${nm} "${tmp}"
        domath val "$val + 1"
        c=`puts "${c}" | sed -e 's/^[^,]*//' -e 's/^[	 ,]*//'`
        puts "## c(G): ${c}" >&9
      done
      c=`puts "${dcl}" | sed -e 's/[ 	]/ /g' \
            -e "s/\([ \*]\)${funcnm}[ (].*/\1/" \
            -e 's/^ *//' \
            -e 's/ *$//'`
      puts "## c(T0): ${c}" >&9
      if [ $noconst = T ]; then
        c=`puts "${c}" | sed -e 's/const *//'`
      fi
      puts "## c(T1): ${c}" >&9
      nm="_c_type_${funcnm}"
      setdata ${nm} "${c}"
    fi
  fi

  printyesno_val $name $ccount ""
  nm="_args_${funcnm}"
  setdata ${nm} ${ccount}
}

check_int_declare () {
  name=$1
  function=$2

  printlabel $name "declared: ${function}"
  checkcache $name
  if [ $rc -eq 0 ]; then return; fi

  code="int main (int argc, char *argv []) {
int x;
x = ${function};
return 0;
}"
  do_c_check_compile ${name} "${code}" all
}

check_ptr_declare () {
  name=$1
  function=$2

  printlabel $name "declared: ${function}"
  checkcache $name
  if [ $rc -eq 0 ]; then return; fi

  code="
int main (int argc, char *argv []) {
  void *x;
  x = ${function};
  return 0;
}"
  do_c_check_compile ${name} "${code}" all
}

check_npt () {
  func=$2
  req=$3

  has=1
  if [ "${req}" != "" ]; then
    getdata has "${req}"
  fi
  nm="_npt_${func}"

  name=$nm
  proto=$func

  printlabel $name "need prototype: ${proto}"
  checkcache $name
  if [ $rc -eq 0 ]; then return; fi

  if [ ${has} -eq 0 ]; then
    setdata ${name} 0
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

check_staticlib () {
  staticlib=T
  check_lib "$@"
  unset staticlib
}

check_lib () {
  func=$2
  shift;shift
  otherlibs=$*
  nm="_lib_${func}"

  name=$nm

  rfunc=$func
  dosubst rfunc '_dollar_' '$'
  if [ "${otherlibs}" != "" ]; then
    printlabel $name "function: ${rfunc} [${otherlibs}]"
    # code to check the cache for which libraries are specified is not written
  else
    printlabel $name "function: ${rfunc}"
    checkcache $name
    if [ $rc -eq 0 ]; then return; fi
  fi

  trc=0
  # unfortunately, this does not work if the function
  # is not declared.
  if [ "$_MKCONFIG_USING_CPLUSPLUS" = Y ]; then
    hinc=none
    code="
CPP_EXTERNS_BEG
#undef $rfunc
typedef char (*test_func)();
char $rfunc();
test_func f = (test_func) $rfunc;
CPP_EXTERNS_END
int main (int argc, char *argv []) {
  if (f == (test_func) $rfunc) {
    return 0;
  }
  return 1;
}
"
  else
    hinc=all
    code="
CPP_EXTERNS_BEG
typedef char (*test_func)();
test_func f = (test_func) $rfunc;
CPP_EXTERNS_END
int main (int argc, char *argv []) {
  f();
  if (f == (test_func) $rfunc) {
    return 0;
  }
  return 1;
}
"
  fi

  _c_chk_link_libs ${name} "${code}" $hinc
  rc=$?
  dlibs=$_retdlibs
  if [ $rc -eq 0 ]; then
    trc=1
  fi

  tag=""
  if [ $rc -eq 0 -a "$dlibs" != "" ]; then
    if [ "$staticlib" = "T" ]; then
      dlibs="$LDFLAGS_STATIC_LIB_LINK $dlibs $LDFLAGS_SHARED_LIB_LINK"
    fi
    tag=" with ${dlibs}"
    cmd="mkc_lnk_${name}=\"${dlibs}\""
    eval $cmd
  fi

  if [ ${trc} -eq 0 -a "$_MKCONFIG_TEST_EXTERN" != "" ]; then
    if [ $_MKCONFIG_USING_CPLUSPLUS = Y ]; then
      hinc=none
      code="
CPP_EXTERNS_BEG
#undef $rfunc
typedef char (*test_func)();
char $rfunc();
test_func f = (test_func) $rfunc;
CPP_EXTERNS_END
int main (int argc, char *argv []) {
  if (f == (test_func) $rfunc) {
    return 0;
  }
  return 1;
}
"
    else
      hinc=all
      code="
CPP_EXTERNS_BEG
/*
Normally, we don't want to do this, as
on some systems we can get spurious errors
where the lib does not exist and the link works!
On modern systems, this simply isn't necessary.
*/
extern int ${func}();
typedef char (*test_func)();
test_func f = (test_func) $rfunc;
CPP_EXTERNS_END
int main (int argc, char *argv []) {
  f();
  if (f == (test_func) $rfunc) {
    return 0;
  }
  return 1;
}
"
    fi

    _c_chk_link_libs ${name} "${code}" $hinc
    rc=$?
    dlibs=$_retdlibs
    if [ $rc -eq 0 ]; then
        trc=1
    fi
    tag=""
    if [ $rc -eq 0 -a "$dlibs" != "" ]; then
      tag=" with ${dlibs}"
      cmd="mkc_lnk_${name}=\"${dlibs}\""
      eval $cmd
    fi
  fi

  otherlibs=""
  printyesno $name $trc "$tag"
  setdata ${name} ${trc}
  return $trc
}

check_class () {
  class=$2
  shift;shift
  otherlibs=$*
  nm="_class_${class}"
  dosubst nm '/' '_' ':' '_'

  name=$nm

  trc=0
  code=" int main (int argc, char *argv []) {
${class} testclass;
return 0;
} "

  if [ "$otherlibs" != "" ]; then
      printlabel $name "class: ${class} [${otherlibs}]"
  else
      printlabel $name "class: ${class}"
      checkcache $name
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
    cmd="mkc_lnk_${name}=\"${dlibs}\""
    eval $cmd
  fi

  otherlibs=""
  printyesno $name $trc "$tag"
  setdata ${name} ${trc}
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
      puts "#define ${tname} ${val}"
      ;;
    _envquote_*)
      ;;
    _env_*)
      if [ "x${val}" != x ]; then
        tname=$name
        dosubst tname '_env_' ''
        eval q=\${mkc__envquote_${tname}}
        if [ $q -eq 1 ]; then
          puts "#define ${tname} \"${val}\""
        else
          puts "#define ${tname} ${val}"
        fi
      fi
      ;;
    _setstr_*|_cmd_loc_*)
      tname=$name
      dosubst tname '_setstr_' ''
      puts "#define ${tname} \"${val}\""
      ;;
    _hdr_*|_sys_*|_command_*)
      puts "#define ${name} ${tval}"
      ;;
    *)      # _c_arg, _c_type go here also
      puts "#define ${name} ${val}"
      ;;
  esac
}

new_output_file () {
  return 0
}
