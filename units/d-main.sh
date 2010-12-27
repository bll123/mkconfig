#!/bin/sh
#
# Copyright 2010 Brad Lanam Walnut Creek CA USA
#
#
#

#
# speed at the cost of maintainability...
# File Descriptors:
#    9 - >>$LOG                     (mkconfig.sh)
#    8 - >>$VARSFILE, >>$CONFH      (mkconfig.sh)
#    7 - temporary for mkconfig.sh  (mkconfig.sh)
#    6 - temporary for d-main.sh    (d-main.sh)
#    4 - temporary for d-main.sh    (d-main.sh)
#

require_unit d-support
require_unit c-support

_MKCONFIG_PREFIX=d
_MKCONFIG_HASEMPTY=F
_MKCONFIG_EXPORT=F
PH_PREFIX="mkc_ph."
PH_STD=F
PH_ALL=F
PI_PREFIX="mkc_pi."
PI_ALL=F
chdr_standard_done=F

cdefs=""
ctypes=""
cdcls=""
cstructs=""
cchglist=""

dump_ccode () {
  ccode=""
  if [ "${cdefs}" != "" ]; then
    doappend ccode "${cdefs}"
  fi
  if [ "${ctypes}" != "" ]; then
    doappend ccode "
${ctypes}"
  fi
  if [ "${cstructs}" != "" ]; then
    doappend ccode "${cstructs}"
  fi
  if [ "${cdcls}" != "" ]; then
    doappend ccode "
extern (C) {

${cdcls}
}
"
  fi

  if [ "${ccode}" != "" ]; then
    echo ""
    set -f
    echo "${ccode}" |
      sed -e 's/[	 ][	 ]*/ /g' \
        -e 's,/\*[^\*]*\*/,,' \
        -e 's,//.*$,,' \
        -e 's/sizeof[	 ]*\(([^)]*)\)/\1.sizeof/g;# gcc-ism' \
        -e 's/__extension__//g;# gcc-ism' \
        -e 's/__/_t_/g;# double underscore not allowed' \
        -e 's/[	 ]*typedef[	 ]/alias /g' \
        -e 's/\*[	 ]const/*/g; # not handled' \
        -e 's/[	 ]*\([\{\}]\)/ \1/' \
        -e 's/long[	 ]*int[	 ]/long /g;# still C' \
        -e 's/short[	 ]*int[	 ]/short /g;# still C' \
        -e 's/long[	 ]*long[	 ]/xlongx /g;# save it' \
        -e 's/long[	 ]*double[	 ]/ real /g' \
        -e 's/unsigned[	 ]*long[	 ]/ uint /g' \
        -e 's/unsigned[	 ]*int[	 ]/uint /g' \
        -e 's/unsigned[	 ]*short[	 ]/ ushort /g' \
        -e 's/unsigned[	 ]*char[	 ]/ ubyte /g' \
        -e 's/unsigned[	 ]*long[	 ]/ uint /g' \
        -e 's/[	 ]signed[	 ]*/ /g;# still C' \
        -e 's/long[	 ]/ int /g' |
      sed -e 's/unsigned *xlongx/ulong /g' \
        -e 's/xlongx /long /g' |
      eval "sed ${cchglist} -e 's/a/a/'"
    set +f
  fi
}

create_chdr_nm () {
  chvar=$1
  thdr=$2

  tnm=$thdr
  # dots are for relative pathnames...
  dosubst tnm '/' '_' ':' '_' '\.h' '' '\.' ''
  case $tnm in
  sys_*)
      tnm="_${tnm}"
      ;;
    *)
      tnm="_hdr_${tnm}"
      ;;
  esac
  eval "$chvar=${tnm}"
}

preconfigfile () {
  pc_configfile=$1

  set -f
  echo "DC: ${DC}" >&9
  echo "DFLAGS: ${DFLAGS}" >&9
  echo "LDFLAGS: ${LDFLAGS}" >&9
  echo "LIBS: ${LIBS}" >&9
  echo "DC_OF: ${DC_OF}" >&9
  set +f

  echo "import std.string;"
  if [ "${_MKCONFIG_SYSTYPE}" != "" ]; then
    echo "enum string SYSTYPE = \"${_MKCONFIG_SYSTYPE}\";"
  fi

  dump_ccode

  if [ "${DC}" = "" ]; then
    echo "No compiler specified" >&2
    return
  fi
}

stdconfigfile () {
  pc_configfile=$1
}

postconfigfile () {
  pc_configfile=$1
}

standard_checks () {
  if [ "${DC}" = "" ]; then
    echo "No compiler specified" >&2
    return
  fi
}

check_import () {
  type=$1
  imp=$2
  shift;shift
  reqimp=$*

  nm1=`echo ${imp} | sed -e 's,/.*,,'`
  nm2="_`echo $imp | sed -e \"s,^${nm1},,\" -e 's,^/*,,'`"
  nm="_${type}_${nm1}"
  if [ "$nm2" != "_" ]; then
    doappend nm $nm2
  fi
  dosubst nm '/' '_' '\.' '_'

  name=$nm
  file=$imp

  printlabel $name "import: ${file}"
  checkcache ${_MKCONFIG_PREFIX} $name
  if [ $rc -eq 0 ]; then return; fi

  code=""
  if [ "${reqimp}" != "" ]; then
      set ${reqimp}
      while test $# -gt 0; do
          doappend code "import $1;
"
          shift
      done
  fi
  doappend code "import $file;
int main (char[][] args) { return 0; }
"
  rc=1
  _d_chk_compile ${name} "${code}" std
  rc=$?
  val=0
  if [ $rc -eq 0 ]; then
      val=${file}
  fi
  printyesno $name $val
  setdata ${_MKCONFIG_PREFIX} ${name} ${val}
}

check_member () {
  shift
  struct=$1
  shift
  member=$1
  nm="_mem_${struct}_${member}"
  dosubst nm ' ' '_'

  name=$nm

  printlabel $name "exists: ${struct}.${member}"
  checkcache ${_MKCONFIG_PREFIX} $name
  if [ $rc -eq 0 ]; then return; fi

  code="void main (char[][] args) { ${struct} stmp; int i; i = stmp.${member}.sizeof; }"

  do_d_check_compile ${name} "${code}" all
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

  code="import std.stdio; void main (char[][] args){ writef(\"%d\", (${type}).sizeof); }"
  _d_chk_run ${name} "${code}" all
  rc=$?
  val=$_retval
  if [ $rc -ne 0 ]; then
    val=0
  fi
  printyesno_val $name $val
  setdata ${_MKCONFIG_PREFIX} ${name} ${val}
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
  code="int main (char[][] args) { return (is(typeof(${rfunc}) == return)); }"

  _d_chk_run ${name} "${code}" all
  rc=$?
  if [ $rc -eq 1 ]; then
    rc=0
  else
    rc=1
  fi
  dlibs=$_retdlibs
  if [ $rc -eq 0 ]; then
      trc=1
  fi
  tag=""
  if [ $rc -eq 0 -a "$dlibs" != "" ]; then
    tag=" with ${dlibs}"
    cmd="di_${_MKCONFIG_PREFIX}_lib_${name}=\"${dlibs}\""
    eval $cmd
  fi

  printyesno $name $trc "$tag"
  setdata ${_MKCONFIG_PREFIX} ${name} ${trc}
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

  if [ "$otherlibs" != "" ]; then
      printlabel $name "class: ${class} [${otherlibs}]"
  else
      printlabel $name "class: ${class}"
      checkcache ${_MKCONFIG_PREFIX} $name
      if [ $rc -eq 0 ]; then return; fi
  fi

  code="void main (char[][] args) { ${class} testclass; testclass = new ${class}; }"
  _d_chk_link_libs ${name} "${code}" all
  rc=$?
  if [ $rc -eq 0 ]; then
    trc=1
  fi
  tag=""
  if [ $rc -eq 0 -a "${dlibs}" != "" ]; then
    tag=" with ${dlibs}"
    cmd="di_${_MKCONFIG_PREFIX}_lib_${name}=\"${dlibs}\""
    eval $cmd
  fi
  printyesno $name $trc "$tag"
  setdata ${_MKCONFIG_PREFIX} ${name} ${trc}
}

check_clib () {
  func=$2
  shift;shift
  libs=$*
  nm="_clib_${func}"
  otherlibs=${libs}

  name=$nm

  rfunc=$func
  dosubst rfunc '_dollar_' '$'
  if [ "${otherlibs}" != "" ]; then
    printlabel $name "c-function: ${rfunc} [${otherlibs}]"
    # code to check the cache for which libraries is not written
  else
    printlabel $name "c-function: ${rfunc}"
    checkcache ${_MKCONFIG_PREFIX} $name
    if [ $rc -eq 0 ]; then return; fi
  fi

  trc=0
  code="
extern (C) {
void ${rfunc}();
}
alias int function () _TEST_fun_;
_TEST_fun_ i= cast(_TEST_fun_) &${rfunc};
void main (char[][] args) { i(); }
"

  _d_chk_link_libs ${name} "${code}" all
  rc=$?
  dlibs=$_retdlibs
  if [ $rc -eq 0 ]; then
      trc=1
  fi
  tag=""
  if [ $rc -eq 0 -a "$dlibs" != "" ]; then
    tag=" with ${dlibs}"
    cmd="di_${_MKCONFIG_PREFIX}_lib_${name}=\"${dlibs}\""
    eval $cmd
  fi

  printyesno $name $trc "$tag"
  setdata ${_MKCONFIG_PREFIX} ${name} ${trc}
}


check_chdr () {
  chdrargs=$@
  if [ $chdr_standard_done = F ]; then
    _check_chdr chdr "stdio.h"
    _check_chdr chdr "stdlib.h"
    _check_chdr csys "types.h"
    _check_chdr csys "param.h"
    PH_STD=T
    PH_ALL=T
    chdr_standard_done=T
  fi
  _check_chdr $chdrargs
}

_check_chdr () {
  type=$1
  hdr=$2
  shift;shift
  reqhdr=$*
  case ${type} in
    csys)
      hdr="sys/${hdr}"
      ;;
  esac
  create_chdr_nm nm $hdr

  name=$nm

  printlabel $name "c-header: ${hdr}"
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
  doappend code "#include <${hdr}>
main () { return (0); }
"
  _c_chk_compile ${name} "${code}" std
  rc=$?
  val=0
  if [ $rc -eq 0 ]; then
    val=${hdr}
  fi

  printyesno $name $val
  setdata ${_MKCONFIG_PREFIX} ${name} ${val}
}

check_csys () {
  check_chdr $@
}

check_cdefstr () {
  type=$1
  defname=$2
  shift;shift
  hdrs=$*

  nm="_cdefstr_${defname}"
  name=$nm

  printlabel $name "c-define-string: ${defname}"
  # no caching

  code="int main () { printf (\"%s\", ${defname}); return (0); }"

  _c_chk_run ${name} "${code}" all
  rc=$?
  if [ $rc -lt 0 ]; then
    _exitmkconfig $rc
  fi
  val=$_retval
  trc=0

  if [ $rc -eq 0 -a "$val" != "" ]; then
    tdata="enum string ${defname} = \"$val\";"
    trc=1
    doappend cdefs "${tdata}
"
  fi

  printyesno $name $trc ""
  setdata ${_MKCONFIG_PREFIX} ${name} ${trc}
}

check_cdefint () {
  type=$1
  defname=$2
  shift;shift
  hdrs=$*

  nm="_cdefint_${defname}"
  name=$nm

  printlabel $name "c-define-int: ${defname}"
  # no caching

  code="int main () { printf (\"%d\", ${defname}); return (0); }"

  _c_chk_run ${name} "${code}" all
  rc=$?
  if [ $rc -lt 0 ]; then
    _exitmkconfig $rc
  fi
  val=$_retval
  trc=0

  if [ $rc -eq 0 -a "$val" != "" ]; then
    tdata="enum int ${defname} = $val;"
    trc=1
    doappend cdefs "${tdata}
"
  fi

  printyesno $name $trc ""
  setdata ${_MKCONFIG_PREFIX} ${name} ${trc}
}

check_ctype () {
  type=$1
  typname=$2
  shift;shift
  hdrs=$*

  nm="_ctype_${typname}"
  name=$nm

  printlabel $name "c-type: ${typname}"
  # no caching

  _c_chk_cpp ${name} "${code}" all
  rc=$?
  trc=0

  if [ $rc -eq 0 ]; then
    tdata=`egrep ".*typedef.*[	 *]+${typname}[	 ]*;" $name.out 2>/dev/null`
    rc=$?
    if [ $rc -eq 0 ]; then
      trc=1
    fi

    if [ $trc -eq 1 ]; then
      doappend ctypes "${tdata}
"
    fi
  fi

  printyesno $name $trc ""
  setdata ${_MKCONFIG_PREFIX} ${name} ${trc}
}

check_cstruct () {
  type=$1
  sname=$2
  shift;shift
  hdrs=$*

  nm="_cstruct_${sname}"
  name=$nm

  printlabel $name "c-struct: ${sname}"
  # no caching

  _c_chk_cpp $name "" all
  rc=$?
  trc=0

  if [ $rc -eq 0 ]; then
    slist="`echo $sname | sed -e 's/,/ /g'`"
    for s in $slist; do
      # looking for the structure, but not forward dcls
      egrep "struct[	 ]*${s}" $name.out 2>/dev/null |
        egrep -v "struct[	 ]*${s} *;" >/dev/null 2>&1
      rc=$?
      if [ $rc -eq 0 ]; then
        snm="struct $s"
        trc=1
      fi
      # is there a typedef?
      # need to know this whether the struct has a name or not.
      egrep -l "[	 ]${s}_t[	 ;]" $name.out >/dev/null 2>&1
      rc=$?
      if [ $rc -eq 0 ]; then
        snm="${s}_t"
        trc=1
      fi
      if [ $trc -eq 1 ]; then
        break
      fi
    done

    if [ $trc -eq 1 ]; then
      > ${name}.c
      code="main () { printf (\"%d\", sizeof (${snm})); return (0); }"
      _c_chk_run ${name} "${code}" all
      rc=$?
      if [ $rc -lt 0 ]; then
        _exitmkconfig $rc
      fi
      rval=$_retval

      if [ $rc -eq 0 ]; then
        st=`awk -f ${_MKCONFIG_DIR}/mkcextstruct.awk ${name}.out ${s}`
        st=`(
          echo "struct C_ST_${s} ";
          # remove only first "struct $s", first "struct", $s_t name,
          # any typedef.
          echo "${st}" |
            sed -e 's/	/ /' -e "s/${s}_t//" -e "s/struct *${s} *{/{/" \
              -e "s/struct *${s} *$//" \
              -e 's/typedef *//' -e 's/struct *{/{/' -e 's/^ *struct$//' |
            grep -v '^ *$'
          )`
        cchglist="${cchglist} -e 's/${snm}/C_ST_${s}/g'"
        doappend cstructs "
${st}
static assert ((C_ST_${s}).sizeof == ${rval});
"
      else
        trc=0
      fi
    fi
  fi

  printyesno $name $trc ""
  setdata ${_MKCONFIG_PREFIX} ${name} ${trc}
}

check_cmember () {
  shift
  struct=$1
  shift
  member=$1
  nm="_cmem_${struct}_${member}"
  dosubst nm ' ' '_'

  name=$nm

  printlabel $name "exists (C): ${struct}.${member}"

  trc=0
  tdfile="${name}.d"
  > ${tdfile}
  exec 4>>${tdfile}
  set -f
  dump_ccode >&4
  set +f
  exec 4>&-
  code="import core.stdc.stdio;
    void main (char[][] args) { C_ST_${struct} stmp; int i; i = stmp.${member}.sizeof; }"

  do_d_check_compile ${name} "${code}" all
}


check_cdcl () {
  type=$1
  dname=$2
  argflag=0
  shift;shift
  if [ "$dname" = "args" ]; then
    argflag=1
    dname=$1
    shift
  fi
  hdrs=$*

  nm="_cdcl_${dname}"
  name=$nm

  printlabel $name "c-dcl: ${dname}"
  # no caching

  trc=0

  set -f
  oldprecc="${precc}"
  doappend precc "/* get rid of gcc-isms */
#define __asm__(a)
#define __attribute__(a)
#define __nonnull__(a,b)
#define __restrict
#define __THROW
#define __const const
"
  set +f

  _c_chk_cpp ${name} "${code}" all
  rc=$?

  if [ $rc -eq 0 ]; then
    egrep "[	 *]${dname}[	 ]*\(" $name.out >/dev/null 2>&1
    rc=$?
    if [ $rc -eq 0 ]; then
      trc=1
    fi

    if [ $trc -eq 1 ]; then
      dcl=`awk -f ${_MKCONFIG_DIR}/mkcextdcl.awk ${name}.out ${dname}`
      set -f
      # extern will be replaced
      # ; may or may not be present, so remove it.
      cmd="dcl=\`echo \"\$dcl\" | sed -e 's/extern *//' -e 's/;//' \`"
      eval $cmd
      set +f
      if [ $argflag = 1 ]; then
        set -f
        c=`echo ${dcl} | sed 's/[^,]*//g'`
        set +f
        ccount=`echo ${EN} "$c${EC}" | wc -c`
        domath ccount "$ccount + 1"  # 0==1 also
      fi
      doappend cdcls "${dcl};
"
    fi
  fi

  set -f
  precc="${oldprecc}"
  set +f

  printyesno $name $trc ""
  setdata ${_MKCONFIG_PREFIX} ${name} ${trc}
  if [ $argflag = 1 ]; then
    nm="_c_args_${dname}"
    setdata ${_MKCONFIG_PREFIX} ${nm} ${ccount}
  fi
}

output_item () {
  out=$1
  name=$2
  val=$3

  tval=false
  if [ "$val" != "0" ]; then
    tval=true
  fi
  case ${name} in
    _setint_*|_siz_*|_c_args_*)
      tname=$name
      dosubst tname '_setint_' ''
      set -f
      echo "enum int ${tname} = ${val};"
      set +f
      ;;
    _setstr_*|_opt_*)
      tname=$name
      dosubst tname '_setstr_' '' '_opt_' ''
      set -f  # disable filename generation
      echo "enum string ${tname} = \"${val}\";"
      set +f
      ;;
    _import_*|_command_*|_chdr_*|_csys_*)
      echo "enum bool ${name} = ${tval};"
      ;;
    *)
      echo "enum bool ${name} = ${tval};"
      ;;
  esac
}

output_other () {
  return
}
