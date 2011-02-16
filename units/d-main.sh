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

ENUM1=""
ENUM2=""
ENUM3=""
if [ "$DVERSION" = 1 ]; then
  ENUM1=": "
  ENUM2="{ "
  ENUM3=" }"
fi

_create_enum () {
  out=F
  type=$1
  if [ $type = "-o" ]; then
    out=T
    shift
    type=$1
  fi
  var=$2
  val=$3

  estr="enum "
  e1=$ENUM1
  e2=$ENUM2
  e3=$ENUM3
  strq=""
  if [ $type = "string" ]; then
    strq="\""
    if [ "$DVERSION" = "1" ]; then
      estr=""
      e1=""
      e2=""
      e3=""
    fi
  fi
  tenum="${estr}${e1}${type} ${e2}${var} = ${strq}${val}${strq}${e3};"
  set -f
  if [ $out = "T" ]; then
    echo $tenum
  fi
  set +f
}

dump_ccode () {

  ccode=""
  if [ "${cdefs}" != "" ]; then
    set -f
    doappend ccode "${cdefs}"
    set +f
  fi
  if [ "${cstructs}" != "" ]; then
    set -f
    doappend ccode "${cstructs}"
    set +f
  fi
  if [ "${ctypes}" != "" ]; then
    set -f
    doappend ccode "
${ctypes}"
    set +f
  fi
  if [ "${cdcls}" != "" ]; then
    set -f
    doappend ccode "
extern (C) {

${cdcls}
}
"
    set +f
  fi

  if [ "${ccode}" != "" ]; then
    echo ""
    set -f
    echo "${ccode}" |
      eval "sed ${cchglist} -e 's/a/a/'" |
      sed -e 's/[	 ][	 ]*/ /g' \
        -e 's,/\*[^\*]*\*/,,' \
        -e 's,//.*$,,' \
        -e 's/sizeof[	 ]*\(([^)]*)\)/\1.sizeof/g;# gcc-ism' \
        -e 's/__extension__//g;# gcc-ism' \
        -e 's/__/_t_/g;# double underscore not allowed' \
        -e 's/\*[	 ]const/*/g; # not handled' \
        -e 's/[	 ]*\([\{\}]\)/ \1/' \
        -e 's/[	 ]long[	 ]*int[	 ]/ long /g;# still C' \
        -e 's/[	 ]short[	 ]*int[	 ]/ short /g;# still C' \
        -e 's/[	 ]signed[	 ]*/ /g;# still C' \
        -e 's/[	 ]long[	 ]*double[	 ]/ xlongdx /g' \
        -e 's/double[	 ]/xdoublex /g' \
        -e 's/float[	 ]/xfloatx /g' \
        -e 's/unsigned[	 ]long[	 ]*long[	 ]/uxlonglongx /g' \
        -e 's/long[	 ]*long[	 ]/xlonglongx /g' \
        -e 's/unsigned[	 ]*short[	 ]/uxshortx /g' \
        -e 's/unsigned[	 ]*char[	 ]/uxbytex /g' \
        -e 's/unsigned[	 ]*int[	 ]/uxintx /g' \
        -e 's/unsigned[	 ]*long[	 ]/uxlongx /g' \
        -e 's/[	 ]char[	 ]/ xcharx /g' \
        -e 's/[	 ]short[	 ]/ xshortx /g' \
        -e 's/[	 ]int[	 ]/ xintx /g' \
        -e 's/[	 ]long[	 ]/ xlongx /g' \
        |
      sed -e "s/xlongdx/${_c_long_double}/g" \
        -e "s/xdoublex/${_c_double}/g" \
        -e "s/xfloatx/${_c_float}/g" \
        -e "s/xlonglongx/${_c_long_long}/g" \
        -e "s/xlongx/${_c_long}/g" \
        -e "s/xintx/${_c_int}/g" \
        -e "s/xshortx/${_c_short}/g" \
        -e "s/xcharx/${_c_char}/g" \
        -e 's/xbytex/byte/g'
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
    _create_enum -o string SYSTYPE "${_MKCONFIG_SYSTYPE}"
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
  code="int main (char[][] args) { auto f = slib1_f; 
      return (is(typeof(${rfunc}) == return)); }"

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

_map_int_csize () {
  nm=$1

  eval "tnm=_csiz_${nm}"
  getdata tval ${_MKCONFIG_PREFIX} $tnm
  if [ $tval -eq 1 ]; then mval=char; fi        # leave char as char
  if [ $tval -eq 2 ]; then mval=short; fi
  if [ $tval -eq 4 ]; then mval=int; fi
  if [ $tval -eq 8 ]; then mval=long; fi

  eval "_c_${nm}=${mval}"
}

_map_float_csize () {
  nm=$1

  eval "tnm=_csiz_${nm}"
  getdata tval ${_MKCONFIG_PREFIX} $tnm
  if [ $tval -eq 4 ]; then mval=float; fi
  if [ $tval -eq 8 ]; then mval=double; fi
  if [ $tval -eq 12 ]; then mval=real; fi

  eval "_c_${nm}=${mval}"
}

check_csizes () {
  check_csize char char
  check_csize short short
  check_csize int int
  check_csize long long
  check_csize "long long" "long long"
  check_csize float float
  check_csize double double
  check_csize "long double" "long double"

  _map_int_csize char
  _map_int_csize short
  _map_int_csize int
  _map_int_csize long
  _map_int_csize long_long
  _map_float_csize float
  _map_float_csize double
  _map_float_csize long_double
}

check_csize () {
  shift
  type=$*
  nm="_csiz_${type}"
  dosubst nm ' ' '_'

  name=$nm

  printlabel $name "c-sizeof: ${type}"
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
    _create_enum string ${defname} "${val}"
    trc=1
    set -f
    doappend cdefs "${tenum}
"
    set +f
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
    _create_enum int ${defname} ${val}
    trc=1
    set -f
    doappend cdefs "${tenum}
"
    set +f
  fi

  printyesno $name $trc ""
  setdata ${_MKCONFIG_PREFIX} ${name} ${trc}
}

check_ctypeconv () {
  type=$2
  typname=$3
  shift;shift
  hdrs=$*

  nm="_ctypeconv_${typname}"
  name=$nm

  printlabel $name "c-typeconv: ${typname} ($type)"
  # no caching

  val=0
  code="int main () { printf (\"%u\", sizeof(${typname})); return (0); }"
  _c_chk_cpp ${name} "${code}" all
  rc=$?
  if [ $rc -eq 0 ]; then
    tdata=`egrep ".*typedef.*[	 \*]+${typname}[^a-zA-Z0-9_]" $name.out 2>/dev/null`
    rc=$?
    if [ $rc -eq 0 ]; then
      u=""
      case $tdata in
        *unsigned*)
          u=u
          ;;
      esac
      _c_chk_run ${name} "${code}" all
      rc=$?
      val=$_retval
    fi
  fi
  if [ $type = "int" -a $rc -eq 0 ]; then
    case $val in
      1)
        dtype=byte
        ;;
      2)
        dtype=short
        ;;
      4)
        dtype=int
        ;;
      8)
        dtype=long
        ;;
    esac
  fi
  if [ $type = "float" -a $rc -eq 0 ]; then
    case $val in
      4)
        dtype=float
        ;;
      8)
        dtype=double
        ;;
      *)
        dtype=real
        ;;
    esac
  fi
  if [ $rc -eq 0 ]; then
    doappend cchglist "-e 's/\([^a-zA-Z0-9_]\)${typname}\([^a-zA-Z0-9_]\)/\1${u}${dtype}\2/g' "
  fi

  printyesno_val $name $val ""
  setdata ${_MKCONFIG_PREFIX} ${name} ${val}
}

check_ctypedef () {
  type=$1
  typname=$2
  shift;shift
  hdrs=$*

  nm="_ctypedef_${typname}"
  name=$nm

  printlabel $name "c-typedef: ${typname}"
  # no caching

  trc=0
  code="int main () { return (0); }"
  _c_chk_cpp ${name} "${code}" all
  rc=$?
  if [ $rc -eq 0 ]; then
    echo "### ctypedef: grep out begin" >&9
    egrep ".*typedef.*[	 \*]${typname}[	 ]*;([	 ]//.*)?$" $name.out >&9
    echo "### ctypedef: grep out end" >&9
    tdata=`egrep ".*typedef.*[	 \*]${typname}[	 ]*;([	 ]//.*)?$" $name.out 2>/dev/null`
    rc=$?
    set -f
    echo "### ctypedef: $tdata" >&9
    set +f
  fi
  if [ $rc -eq 0 ]; then
    trc=1
    set -f
    dosubst tdata typedef alias
    doappend ctypes "$tdata
"
    set +f
  fi

  printyesno $name $trc ""
  setdata ${_MKCONFIG_PREFIX} ${name} ${trc}
}

check_cunion () {
  check_cstruct $@
}

check_cenum () {
  check_cstruct $@
}

check_cstruct () {
  type=$1
  s=$2
  shift;shift
  hdrs=$*

  nm="_${type}_${s}"
  ctype=$type
  ctype=`echo $ctype | sed -e 's/^c//'`
  lab=C_ST_
  case $ctype in
    enum)
      lab=C_ENUM_
      ;;
    union)
      lab=C_UN_
      ;;
  esac
  name=$nm

  printlabel $name "c-${ctype}: ${s}"
  # no caching

  _c_chk_cpp $name "" all
  rc=$?
  trc=0
  rval=0
  std=""
  stnm=""

  if [ $rc -eq 0 ]; then
    st=`awk -f ${_MKCONFIG_DIR}/mkcextstruct.awk ${name}.out ${s}`
    echo "#### initial ${ctype}" >&9
    echo "${st}" >&9
    echo "#### end initial ${ctype}" >&9

    # is there a typedef?
    # need to know whether the struct has a typedef name or not.
    echo "### check for typedef w/_t" >&9
    echo $st | egrep "typedef.*}[	 ]*${s}_t[	 ]*;" >&9 2>&1
    rc=$?
    if [ $rc -eq 0 ]; then
      std="${s}_t"
    else
      # sometimes typedef'd w/o _t
      echo "### check for typedef w/o _t" >&9
      echo $st | egrep "typedef.*}[	 ]*${s}[	 ]*;" >&9 2>&1
      rc=$?
      if [ $rc -eq 0 ]; then
        std="${s}"
      fi
    fi
    echo "#### std=${std}" >&9

    echo "### check for named struct" >&9
    if [ "$std" = "" ]; then
      stnm=`echo $st | egrep "}[	 ]*[a-zA-Z0-9_]*[	 ]*;" |
          sed -e 's/.*}[	 ]*//' -e 's/[	 ]*;$//'`
    fi
    echo "#### stnm=${stnm}" >&9

    trc=1

    tstnm=$std
    if [ "$stnm" != "" ]; then
      tstnm=$stnm
    fi

    st=`(
      echo "${ctype} ${lab}${s} ";
      # remove only first "struct $s", first "struct", typedef name,
      # any typedef.
      echo "${st}" |
        sed -e 's/  / /g' \
          -e "s/${tstnm}[	 ]*;/;/;# typedef name or named struct" \
          -e "s/${ctype}[	 ]*${s}[	 ]*{/{/" \
          -e "s/${ctype}[	 ]*${s}[	 ]*$//" \
          -e 's/typedef[	 ]*//' \
          -e "s/^${ctype}[	 ]*{/{/" \
          -e "s/^[	 ]*${ctype}$//" |
        grep -v '^[	 ]*$'
      )`
    echo "#### modified ${ctype}" >&9
    echo "${st}" >&9
    echo "#### end modified ${ctype}" >&9

    if [ "$std" = "" ]; then
      std=$s
      if [ $ctype != "enum" ]; then
        std="${ctype} ${s}"
      fi
    fi
    echo "#### std=${std}" >&9

    if [ $trc -eq 1 ]; then
      if [ $ctype != "enum" ]; then
        tstnm=$std
        if [ "$stnm" != "" ]; then
          tstnm=$stnm
        fi
        echo "#### check size using: ${tstnm}" >&9
        code="main () { printf (\"%d\", sizeof (${tstnm})); return (0); }"
        _c_chk_run ${name} "${code}" all
        rc=$?
        if [ $rc -lt 0 ]; then
          _exitmkconfig $rc
        fi
        rval=$_retval
        echo "#### not enum: rval=${rval}" >&9
        if [ $rc -ne 0 ]; then
          trc=0
        fi
      fi
    else
      trc=0
    fi
  fi

  if [ $trc -eq 1 ]; then
    doappend cchglist "-e 's/\([^a-zA-Z0-9_]\)${std}\([^a-zA-Z0-9_]\)/\1${lab}${s}\2/g' "
    doappend cchglist "-e 's/^${std}\([^a-zA-Z0-9_]\)/${lab}${s}\1/g' "
    set -f
    doappend cstructs "
${st}
"
    set +f
    if [ "$stnm" != "" ]; then
      doappend cstructs "${lab}${s} ${stnm};
"
    fi
    if [ $lab != "enum" -a $rval -gt 0 ]; then
      doappend cstructs "static assert ((${lab}${s}).sizeof == ${rval});
"
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
  code="void main (char[][] args) { C_ST_${struct} stmp; int i; i = stmp.${member}.sizeof; }"

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
      if [ "$DVERSION" = 1 ]; then
        dosubst dcl 'const' ''
      fi
      set +f
      if [ $argflag = 1 ]; then
        set -f
        c=`echo ${dcl} | sed 's/[^,]*//g'`
        set +f
        ccount=`echo ${EN} "$c${EC}" | wc -c`
        domath ccount "$ccount + 1"  # 0==1 also
      fi
      set -f
      doappend cdcls "${dcl};
"
      set +f
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
    _setint_*|_csiz_*|_siz_*|_c_args_*|_ctypeconv_*)
      tname=$name
      dosubst tname '_setint_' ''
      _create_enum -o int ${tname} ${val}
      ;;
    _setstr_*|_opt_*)
      tname=$name
      dosubst tname '_setstr_' '' '_opt_' ''
      _create_enum -o string ${tname} "${val}"
      ;;
    *)
      _create_enum -o bool ${name} "${tval}"
      ;;
  esac
}

output_other () {
  return
}
