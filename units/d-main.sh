#!/bin/sh
#
# Copyright 2011 Brad Lanam Walnut Creek CA USA
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

ENUM1=""
ENUM2=""
ENUM3=""
if [ $DVERSION -eq 1 ]; then
  ENUM1=": "
  ENUM2="{ "
  ENUM3=" }"
fi

_init_var_lists () {
  cdefs=""
  cdcls=""
  ctypes=""
  cstructs=""
  cmacros=""
  daliases=""
  dasserts=""
  modname=""
}

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
  if [ $type = string ]; then
    strq="\""
    if [ $DVERSION -eq 1 ]; then
      estr=""
      e1=""
      e2=""
      e3=""
    fi
  fi
  if [ $type = double ]; then
    if [ $DVERSION -eq 1 ]; then
      estr=""
      e1=""
      e2=""
      e3=""
    fi
  fi

  tenum="${estr}${e1}${type} ${e2}${var} = ${strq}${val}${strq}${e3};"
  if [ $out = T ]; then
    echo $tenum
  fi
}

modify_ctypes () {
  tmcnm=$1
  tcode="$2"

  # modify c types
  tcode=`echo "${tcode}" | sed -e 's/"/\\\\"/g'`
  cmd="
    sed -e 's/[	 ]long[	 ]*int[	 ]/ long /g;# still C' \
      -e 's/[	 ]short[	 ]*int\([	 *]\)/ short\1/g;# still C' \
      -e 's/[	 ]signed[	 ]*/ /g;# still C' \
      -e 's/[	 ]long[	 ]*double\([	 *]\)/ xlongdx\1/g' \
      -e 's/double\([	 *]\)/xdoublex\1/g' \
      -e 's/float\([	 *]\)/xfloatx\1/g' \
      -e 's/unsigned[	 ]long[	 ]*long\([	 *]\)/uxlonglongx\1/g' \
      -e 's/long[	 ]*long\([	 *]\)/xlonglongx\1/g' \
      -e 's/unsigned[	 ]*short\([	 *]\)/uxshortx\1/g' \
      -e 's/unsigned[	 ]*char\([	 *]\)/uxbytex\1/g' \
      -e 's/unsigned[	 ]*int\([	 *]\)/uxintx\1/g' \
      -e 's/unsigned[	 ]*long\([	 *]\)/uxlongx\1/g' \
      -e 's/[ 	]unsigned\([	 *]\)/ uxintx\1/g; # unsigned w/o any type' \
      -e 's/[	 ]char\([	 *]\)/ xcharx\1/g' \
      -e 's/[	 ]short\([	 *]\)/ xshortx\1/g' \
      -e 's/[	 ]int\([	 *]\)/ xintx\1/g' \
      -e 's/[	 ]long\([	 *]\)/ xlongx\1/g' \
      |
    sed -e 's/xlongdx/${_c_long_double}/g' \
      -e 's/xdoublex/${_c_double}/g' \
      -e 's/xfloatx/${_c_float}/g' \
      -e 's/xlonglongx/${_c_long_long}/g' \
      -e 's/xlongx/${_c_long}/g' \
      -e 's/xintx/${_c_int}/g' \
      -e 's/xshortx/${_c_short}/g' \
      -e 's/xcharx/${_c_char}/g' \
      -e 's/xbytex/byte/g'
    "
  echo "#####  modify_ctypes" >&9
  echo "##### modify_ctypes: before" >&9
  echo "$tcode" >&9
  echo "##### modify_ctypes: $cmd" >&9
  eval "${tmcnm}=\`echo \"${tcode}\" | ${cmd}\`" >&9 2>&9
  echo "#### modify_ctypes: $tmcnm after" >&9
  eval "echo \"\$${tmcnm}\"" >&9
  echo "#### modify_ctypes: end $tmcnm after" >&9
}

modify_cchglist () {
  tmcnm=$1
  tcode="$2"

  tcode=`echo "${tcode}" | sed -e 's/"/\\\\"/g'`
  cmd="sed ${cchglist} -e 's/a/a/;# could be empty'"
  echo "#####  modify_cchglist" >&9
  echo "##### modify_cchglist: before" >&9
  echo "$tcode" >&9
  echo "##### modify_cchglist: $cmd" >&9
  eval "${tmcnm}=\`echo \"${tcode}\" | ${cmd}\`" >&9 2>&9
  echo "#### modify_cchglist: $tmcnm after" >&9
  eval "echo \"\$${tmcnm}\"" >&9
  echo "#### modify_cchglist: end $tmcnm after" >&9
}

modify_ccode () {
  tmcnm=$1
  tcode="$2"

  tcode=`echo "${tcode}" | sed -e 's/"/\\\\"/g'`
  cmd="
    sed -e 's/[	 ][	 ]*/ /g;# clean up spacing' \
      -e '# remove /* comments' \
      -e 's,/\*[^\*]*\*/,,;# remove comments' \
      -e '# remove // comments' \
      -e 's,//.*$,,;# remove comments' \
      -e '# change sizeof(v) to v.sizeof' \
      -e 's/sizeof[	 ]*\(([^)]*)\)/\1.sizeof/g' \
      -e 's/__extension__//g;# gcc-ism' \
      -e '# remove gcc-isms' \
      -e 's/__const\([^a-zA-Z0-9_]\)/\1/g;# gcc-ism' \
      -e '# change *const to *' \
      -e 's/\*[	 ]*const/*/g; # not handled' \
      -e '# change version to version_ (reserved keyword)' \
      -e 's/\([^a-zA-Z0-9_]\)version\([^a-zA-Z0-9_]\)/\1version_\2/g' \
      -e '# remove spacing before braces' \
      -e 's/[	 ]*\([\{\}]\)/ \1/;' \
      |
    sed ${cchglist} -e 's/a/a/;# could be empty' \
      |
    sed -e '# handle multi-line statements' \
        -e '# next lines append any line w/o semicolon or open brace' \
        -e '# this is necessary for the function conversion to work.' \
        -e '/^[^;{]*$/ N' \
        -e '/^[^;{]*$/ N' \
        -e '/^[^;{]*$/ N' \
        -e '/^[^;{]*$/ N' \
        -e '/^[^;{]*$/ N' \
        -e '# convert functions' \
        -e 's/^\(.*\)([ 	]*\*[ 	]*\([a-zA-Z0-9_][a-zA-Z0-9_]*\)[ 	]*)[ 	]*(\(.*\))[^(),a-zA-Z0-9_*]*;/\1 function(\3) \2;/' \
        -e 's/^\(.*alias.*\)[ 	][ 	*]*\([a-zA-Z0-9_][a-zA-Z0-9_]*\)[ 	][ 	]*(\(.*\))[^(),a-zA-Z0-9_*]*;/\1 function(\3) \2;/' \
        -e '# change (void) to ()' \
        -e 's/( *void *)/()/' \
        -e '# no const functions' \
        -e 's/^ *const\(  *\)/\1/' \
        |
    sed -e '# leading double underscores are not allowed' \
        -e 's/\([ \*]\)__/\1_t_/g' \
        -e 's/_t_FILE__/toStringz(__FILE__)/g; # revert and make c-ish' \
        -e 's/_t_LINE__/__LINE__/g; # revert' \
        -e '# change casts...these do not have the word "function"...' \
        -e '/function/! s/\(([ 	]*[a-zA-Z_][a-zA-Z0-9_]*[ 	*]*)[ 	]*[a-zA-Z0-9_(]\)/cast\1/g'
    "
  echo "#####  modify_ccode" >&9
  echo "##### modify_ccode: before" >&9
  echo "$tcode" >&9
  echo "##### modify_ccode: $cmd" >&9
  eval "${tmcnm}=\`echo \"${tcode}\" | ${cmd}\`" >&9 2>&9
  if [ $DVERSION -eq 1 ]; then
    cmd="sed -e 's/toStringz(__FILE__)/__FILE__/g; # revert for D1' \
        -e 's/const *//g'
    "
    eval "${tmcnm}=\`echo \"\$${tmcnm}\" | ${cmd}\`" >&9 2>&9
  fi
  echo "#### modify_ccode: $tmcnm after" >&9
  eval "echo \"\$${tmcnm}\"" >&9
  echo "#### modify_ccode: end $tmcnm after" >&9
}

dump_ccode () {

  ccode=""
  if [ "${cdefs}" != "" ]; then
    doappend ccode "${cdefs}"
  fi
  if [ "${ctypes}" != "" ]; then
    doappend ccode "
extern (C) {
${ctypes}
} // extern (C)
"
  fi
  if [ "${cstructs}" != "" ]; then
    doappend ccode "
extern (C) {
${cstructs}
} // extern (C)
"
  fi
  if [ "${cdcls}" != "" ]; then
    doappend ccode "
extern (C) {
${cdcls}
} // extern (C)
"
  fi
  if [ "${ccode}" != "" ]; then
    # handle types separately; don't want to do this on converted macros
    modify_ctypes ccode "${ccode}"
  fi
  if [ "${cmacros}" != "" ]; then
    doappend ccode "
extern (C) {
${cmacros}
} // extern (C)
"
  fi
  if [ "${ccode}" != "" ]; then
    echo ""
    modify_ccode ccode "${ccode}"
    echo "${ccode}
"
  fi
  if [ "${daliases}" != "" ]; then
    echo "${daliases}"
  fi
  if [ "${dasserts}" != "" ]; then
    echo "${dasserts}"
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
  configfile=$2

  echo "DC: ${DC}" >&9
  echo "DVERSION: ${DVERSION}" >&9
  echo "DFLAGS: ${DFLAGS}" >&9
  echo "LDFLAGS: ${LDFLAGS}" >&9
  echo "LIBS: ${LIBS}" >&9
  echo "DC_OF: ${DC_OF}" >&9

  echo "// Created on: `date`"
  echo "//  From: ${configfile}"
  echo "//  Using: mkconfig-${_MKCONFIG_VERSION}"

  if [ "$modname" != "" ]; then
    echo ''
    echo "module $modname;"
  fi

  if [ $DVERSION -eq 2 ]; then
    getdata tval ${_MKCONFIG_PREFIX} '_import_std_string'
    if [ "$tval" != "0" -a "$tval" != "" ]; then
      echo ''
      echo "import std.string;"
    fi
  fi
  getdata tval ${_MKCONFIG_PREFIX} '_type_string'
  if [ "$tval" = "0" ]; then
    echo "alias char[] string;"
  fi
  if [ "${_MKCONFIG_SYSTYPE}" != "" ]; then
    _create_enum -o string SYSTYPE "${_MKCONFIG_SYSTYPE}"
  fi

  cmd="dump_ccode"
  if [ $noprefix = T ]; then
    cmd="$cmd | sed -e 's/C_ST_//g' -e 's/C_ENUM_//g' -e 's/C_UN_//'g \
        -e 's/C_TYP_//g' -e 's/C_MACRO_//g' "
  fi
  eval $cmd

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

  check_import import std.string
  check_type type string
  check_tangolib
  # this will be output as an enum also.
  setdata ${_MKCONFIG_PREFIX} _setint_D_VERSION ${DVERSION}
}

check_type () {
  shift
  type=$@
  nm="_type_${type}"
  dosubst nm ' ' '_'
  name=$nm
  dosubst type 'star' '*'

  printlabel $name "type: ${type}"
  checkcache ${_MKCONFIG_PREFIX} $name
  if [ $rc -eq 0 ]; then return; fi

  code="
${type} value;
struct xxx { ${type} mem; };
static xxx v;
xxx* f() { return &v; };
int main () { xxx *tmp; tmp = f(); return (0); }
"

  do_d_check_compile ${name} "${code}" all
}

check_tangolib () {
  tname=_d_tango_lib

  printlabel $tname "Tango lib:"
  checkcache ${_MKCONFIG_PREFIX} $tname
  if [ $rc -eq 0 ]; then return; fi

  code="
import tango.io.Stdout;
int main () { Stdout (\"hello world\"); return (0); }
"

  do_d_check_compile ${tname} "${code}" all
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
  # no cache check

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

  getdata tangoval ${_MKCONFIG_PREFIX} '_d_tango_lib'

  printlabel $name "sizeof: ${type}"
  checkcache_val ${_MKCONFIG_PREFIX} $name
  if [ $rc -eq 0 ]; then return; fi

  if [ $tangoval -eq 0 ]; then
    code="import std.stdio;
        void main (char[][] args) { writef(\"%d\", (${type}).sizeof); }"
  else
    code="import tango.io.Stdout;
        void main (char[][] args) { Stdout ((${type}).sizeof); }"
  fi
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
  code="int main (char[][] args) { auto f = ${rfunc};
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
    cmd="mkc_${_MKCONFIG_PREFIX}_lib_${name}=\"${dlibs}\""
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
    cmd="mkc_${_MKCONFIG_PREFIX}_lib_${name}=\"${dlibs}\""
    eval $cmd
  fi
  printyesno $name $trc "$tag"
  setdata ${_MKCONFIG_PREFIX} ${name} ${trc}
}

_map_int_csize () {
  nm=$1

  eval "tnm=_csiz_${nm}"
  getdata tval ${_MKCONFIG_PREFIX} $tnm
  mval=""
  if [ $tval -eq 1 ]; then mval=char; fi        # leave char as char
  if [ $tval -eq 2 ]; then mval=short; fi
  if [ $tval -eq 4 ]; then mval=int; fi
  if [ $tval -eq 8 ]; then mval=long; fi
  if [ "$mval" = "" ]; then mval=long; fi

  doappend daliases "alias ${mval} C_NATIVE_${nm};
"
  eval "_c_${nm}=${mval}"

  if [ ${nm} != char ]; then
    doappend daliases "alias u${mval} C_NATIVE_unsigned_${nm};
"
    eval "_c_unsigned_${nm}=u${mval}"
  fi
}

_map_float_csize () {
  nm=$1

  eval "tnm=_csiz_${nm}"
  getdata tval ${_MKCONFIG_PREFIX} $tnm
  mval=""
  if [ $tval -eq 4 ]; then mval=float; fi
  if [ $tval -eq 8 ]; then mval=double; fi
  if [ $tval -eq 12 ]; then mval=real; fi
  if [ "$mval" = "" ]; then mval=real; fi

  doappend daliases "alias ${mval} C_NATIVE_${nm};
"
  eval "_c_${nm}=${mval}"
}

# the rest of the check() routines are for the C/D language interface.

check_csizes () {
  check_csize int char
  check_csize int short
  check_csize int int
  check_csize int long
  check_csize int "long long"
  check_csize float float
  check_csize float double
  check_csize float "long double"

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
  basetype=$1
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
    cmd="mkc_${_MKCONFIG_PREFIX}_lib_${name}=\"${dlibs}\""
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

  if [ "$CPPCOUNTER" != "" ]; then
    domath CPPCOUNTER "$CPPCOUNTER + 1"
  fi
  printyesno $name $val
  setdata ${_MKCONFIG_PREFIX} ${name} ${val}
}

check_csys () {
  check_chdr $@
}

check_cdefine () {
  btype=$2
  defname=$3
  shift;shift;shift

  nm="_cdefine_${defname}"
  name=$nm

  printlabel $name "c-define ($btype): ${defname}"
  # no cache

  case $btype in
    short)
      o="%d"
      btype2=${_c_short}
      ;;
    int)
      o="%d"
      btype2=${_c_int}
      ;;
    long)
      o="%ld"
      btype2=${_c_long}
      ;;
    longlong)
      o="%lld"
      btype2=${_c_long_long}
      ;;
    hexshort)
      o="0x%x"
      btype2=${_c_short}
      ;;
    hex)
      o="0x%x"
      btype2=${_c_int}
      ;;
    hexlong)
      o="0x%lx"
      btype2=${_c_long}
      ;;
    hexlonglong)
      o="0x%llx"
      btype2=${_c_long_long}
      ;;
    float)
      o="%g"
      btype2=double
      ;;
    string)
      o="%s"
      btype2=string
      ;;
    char)
      o="%s"
      btype2=char
      ;;
  esac

  suffix=""
  if [ $btype2 = long ]; then
    suffix=L
  fi

  code="int main () { printf (\"${o}${suffix}\", ${defname}); return (0); }"

  _c_chk_run ${name} "${code}" all
  rc=$?
  if [ $rc -lt 0 ]; then
    _exitmkconfig $rc
  fi
  val=$_retval
  trc=0

  if [ $rc -eq 0 -a "$val" != "" ]; then
    _create_enum ${btype2} ${defname} "${val}"
    trc=1
    doappend cdefs "${tenum}
"
  fi

  printyesno $name $trc ""
  setdata ${_MKCONFIG_PREFIX} ${name} ${trc}
}

check_ctype () {
  type=$2
  typname=$3
  shift;shift;shift

  nm="_ctype_${typname}"
  name=$nm

  printlabel $name "c-type ($type): ${typname}"
  # no cache

  val=0
  u=""
  code="int main () { printf (\"%u\", sizeof(${typname})); return (0); }"
  _c_chk_cpp ${name} "${code}" all
  rc=$?
  if [ $rc -eq 0 ]; then
    tdata=`egrep ".*typedef.*[	 \*]+${typname}[	 ]*;" $name.out 2>/dev/null |
        sed -e 's/ *__attribute__ *(.*) *//' `
    rc=$?
    if [ $rc -eq 0 ]; then
      _c_chk_run ${name} "${code}" all
      rc=$?
      val=$_retval
    fi
  fi
  if [ $rc -eq 0 ]; then
    code="int main () { int rc; ${typname} ww; ww = ~ 0; rc = ww < 0 ? 0 : 1;
        printf (\"%d\", rc); return (0); }"
    _c_chk_run ${name}_uchk "${code}" all
    rc=$?
    uval=$_retval
    if [ $rc -ne 0 ]; then
      uval=0
    fi
    if [ $uval -eq 1 ]; then
      u=u
    fi
  fi
  if [ $type = int -a $rc -eq 0 ]; then
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
      *)
        dtype=long
        ;;
    esac
  fi
  if [ $type = float -a $rc -eq 0 ]; then
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
    ntypname=$typname
    ntypname=C_TYP_${ntypname}
    if [ $noprefix = F -o ${dtype} != ${ntypname} ]; then
      doappend daliases "alias ${u}${dtype} ${ntypname};
"
    fi
    doappend dasserts "static assert ((${ntypname}).sizeof == ${val});
"
    doappend cchglist "-e 's/\([^a-zA-Z0-9_]\)${typname}\([^a-zA-Z0-9_]\)/\1${ntypname}\2/g' "
  fi

  printyesno_val $name $val ""
  setdata ${_MKCONFIG_PREFIX} ${name} ${val}
}

check_ctypedef () {
  type=$1
  typname=$2
  shift;shift

  nm="_ctypedef_${typname}"
  name=$nm

  printlabel $name "c-typedef: ${typname}"
  # no cache

  trc=0
  code=""
  _c_chk_cpp ${name} "" all
  rc=$?
  if [ $rc -eq 0 ]; then
    tdata=`${awkcmd} -f ${_MKCONFIG_DIR}/util/mkcexttypedef.awk ${name}.out ${typname}`
    tdata=`echo $tdata`  # make single line.
    echo "## tdata(0): ${tdata}" >&9
    if [ "$tdata" != "" ]; then
      trc=1
      tdata=`echo $tdata | sed -e \
        's/^\(.*\)([ 	*]*\([a-zA-Z0-9_][a-zA-Z0-9_]*\)[ 	]*)[ 	]*(\(.*\))[ 	]*;/\1 function(\3) \2;/' \
        -e 's/[ 	]*;/;/'`
      echo "## tdata(B): ${tdata}" >&9
      dosubst tdata typedef alias
      echo "## tdata(c): ${tdata}" >&9
      tta=a
      ttb=b
      if [ $noprefix = T ]; then
        ttl=`echo $tdata | sed 's/^alias *[sue][trucniom]* *\([a-zA-Z0-9_]*\) *\([a-zA-Z0-9_]*\);/\1 \2/'`
        set $ttl
        if [ $# -eq 2 ]; then
          tta=$1
          ttb=$2
        fi
      fi
      if [ $tta != $ttb ]; then
        doappend ctypes "$tdata
"
      fi
    fi
  fi

  printyesno $name $trc ""
  setdata ${_MKCONFIG_PREFIX} ${name} ${trc}
}

_findheader () {
  fhpat=$1
  shift

  # need path to header file
  if [ "$cmpaths" = "" ]; then
    cmpaths="/usr/include . "
    if [ "$CFLAGS" != "" ]; then
      next=F
      for f in $CFLAGS; do
        if [ $next = T ]; then
          doappend cmpaths ' '
          doappend cmpaths $f
        fi
        next=F
        case $f in
          -I*)
            if [ $f = "-I" ]; then
              next=T
            else
              dosubst f '-I' ''
              doappend cmpaths ' '
              doappend cmpaths $f
            fi
            ;;
        esac
      done
    fi
  fi

  fhrc=0
  while test $# -gt 0; do
    thdr=$1
    case $thdr in
      *.h)
        create_chdr_nm nhdr $thdr
        getdata vhdr ${_MKCONFIG_PREFIX} $nhdr
        echo "   checking $thdr : $nhdr : $vhdr " >&9
        if [ "${vhdr}" != "0" -a "${vhdr}" != "" ]; then
          for p in $cmpaths; do
            echo "  checking $p/$thdr for $fhpat" >&9
            if [ -f $p/$thdr ]; then
              egrep "$fhpat" $p/$thdr >/dev/null 2>&1
              rc=$?
              if [ $rc -eq 0 ]; then
                fhrc=1
                fhdr=$p/$thdr
                echo "  found $fhdr for $mname" >&9
                break
              fi
            fi
          done
        fi
        ;;
      *)
        break
        ;;
    esac
    shift
  done
}


check_cmacro () {
  mname=$2
  shift;shift

  nm="_cmacro_${mname}"
  name=$nm

  printlabel $name "c-macro: ${mname}"
  # no cache

  trc=0
  cmpaths=""

  _findheader "define[	 ]*${mname}[^a-zA-Z0-9_]" $@

  echo "  \$@:$@" >&9

  # eat the rest of the .h args
  while test $# -gt 0; do
    thdr=$1
    case $thdr in
        *.h)
          ;;
        *)
          break
          ;;
    esac
    shift
  done

  if [ $fhrc -eq 1 ]; then
    macro=`${awkcmd} -f ${_MKCONFIG_DIR}/util/mkcextmacro.awk $fhdr ${mname}`
    echo "  extracted macro: $macro" >&9
    macro=`echo ${macro} |
        sed -e 's/	/ /g;# tab to space' \
        -e 's/^# *define *//' \
        -e 's/\$/; }/' \
        -e 's/([ *]*\(a-zA-Z0-9_]*\))->/\1./g' \
        -e 's/->/./g' \
        -e 's/(\([a-zA-Z0-9_]*\))\./\1./g;# (name). to name.' \
        -e 's/^/auto C_MACRO_/' \
        -e 's/\(C_MACRO_[a-zA-Z0-9_]*([^)]*) *\)/\1 { return /' \
        -e 's/\(C_MACRO_[a-zA-Z0-9_]*  *\)/\1 () { return /'`
    echo "  initial macro: $macro" >&9
    trc=1
  fi

  # always pull the type off the list, even for D2
  type=$1
  shift
  if [ "$type" = "" ]; then
    type=int
  fi
  if [ $DVERSION -eq 1 -a $rc -eq 0 -a $trc -eq 1 ]; then
    macro=`echo ${macro} | sed -e "s/^auto/${type}/"`
    echo "  macroC: $macro" >&9
  fi

  tfirst=1
  if [ $rc -eq 0 -a $trc -eq 1 -a $# -gt 0 ]; then
    while test $# -gt 0; do
      type=$1
      if [ $tfirst -eq 1 ]; then
        macro=`echo ${macro} | sed -e "s/(/(${type} /" `
        echo "  macroD: $macro" >&9
        tfirst=0
        ttype=`echo $type | sed 's/\*/\\\\*/g'`
        tmp="($ttype [a-zA-Z0-9_]*"
      else
        echo "  tmp: $tmp" >&9
        cmd="macro=\`echo \${macro} |
            sed -e 's/\(${tmp}\) *, */\\\\1, ${type} /'\`"
        echo "  cmdE: $cmd" >&9
        eval $cmd
        echo "  macroE: $macro" >&9
        ttype=`echo $type | sed 's/\*/\\\\*/g'`
        doappend tmp ", ${ttype} [a-zA-Z0-9_]*"
      fi
      shift
    done
  fi

  if [ $rc -eq 0 -a $trc -eq 1 ]; then
    nmname=$mname
    nmname=C_MACRO_${nmname}
    doappend cmacros "${macro}
"
    doappend cchglist "-e 's/\([^a-zA-Z0-9_]\)${mname}\([^a-zA-Z0-9_]\)/\1${nmname}\2/g' "
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
  # no cache

  code=""
  _c_chk_cpp $name "" all
  rc=$?
  trc=0
  rval=0
  origstnm=""
  stnm=""
  tdnm=""

  if [ $rc -eq 0 ]; then
    st=`${awkcmd} -f ${_MKCONFIG_DIR}/util/mkcextstruct.awk ${name}.out ${s} d`
    echo "#### initial ${ctype}" >&9
    echo "${st}" >&9
    echo "#### end initial ${ctype}" >&9
    if [ "${st}" != "" ]; then
      tst=`echo ${st} | sed -e 's/{.*}/ = /' -e 's/[	]/ /g' -e 's/  / /g' \
          -e 's/^ *//' -e 's/[ ;]*\$//'`
      echo "### ${ctype} basics:${tst}:" >&9
      # should now be: [typedef] {struct|union|enum} [name] = [name2]
      if [ "${tst}" != "" ]; then
        set ${tst}
        havetypedef=F
        if [ $1 = typedef ]; then
          havetypedef=T
          shift
        fi
        shift # the type, which we know already
        if [ $1 != "=" ]; then
          stnm=$1
          shift
        fi
        shift # remove the equals sign
        if [ $# -gt 0 ]; then
          tdnm=$1
          shift
        fi
        echo "#### stnm=${stnm}" >&9
        otdnm=$tdnm
        dosubst otdnm '\*' ''
        ttdnm=$tdnm
        dosubst ttdnm '\*' '\\*'
        echo "#### tdnm=${tdnm} (${otdnm})" >&9

        if [ "$stnm" != "" -o "$otdnm" != "" ]; then
          trc=1
        fi

        # remove 'typedef' keyword
        # remove trailing name before ;
        # remove "struct $stnm"
        # remove "struct"
        # remove all const
        # remove blank lines
        st=`echo "${st}" |
            sed -e 's/[	]/ /g' -e 's/  / /g' \
              -e 's/typedef *//' \
              -e "s/${ttdnm} *;/;/; # typedef name or named struct" \
              -e "s/ *${ctype} *${stnm} *{/{/" \
              -e "s/^ *${ctype} *${stnm} *\$//" \
              -e 's/\([^a-zA-Z0-9_]\)const\([^a-zA-Z0-9_]\)/\1 \2/g; # not supported' \
              -e 's/^const\([^a-zA-Z0-9_]\)/\1/g; # not supported' \
              | grep -v '^ *$' `
        # change all other struct/union/enum to our tag.
        if [ "$stnm" != "" ]; then
          st=`echo "${st}" |
              sed -e "s/${ctype} *${stnm}\\([^a-zA-Z0-9_]\\)/${lab}${stnm}\\1/"`
        fi
        echo "#### modified ${ctype} (A)" >&9
        echo ":${st}:" >&9
        echo "#### end modified ${ctype} (A)" >&9
      else
        trc=0
      fi
    fi

    if [ "${st}" != "" ]; then
      echo "### check for nested struct/union/enum" >&9

      # look for any nested structure definitions as changed by
      # the awk extractor and add them to the cchglist.
      # remove the struct/union/enum tags from the structure now also
      # for those definitions that are found.
      tst=$st
      inst=0
      while read tsline; do
        case $tsline in
          *struct*{|*union*{|*enum*{)
            echo "###   found: ${tsline}" >&9
            ttype=`echo ${tsline} | sed -e 's/^[ const]*\([sue][trucniom]*\) *.*/\1/'`
            tl=`echo ${tsline} | sed -e "s/^.*${ttype} *\([a-zA-Z0-9_]*\) *{.*/\1/"`
            tlab=`echo ${tl} | sed 's/^\(C_[STUNEM]*_\).*/\1/'`
            tl=`echo ${tl} | sed -e "s/^${tlab}//"`
            echo "###   ttype: ${ttype}" >&9
            echo "###   tlab: ${tlab}" >&9
            echo "###   tl: ${tl}" >&9
            if [ "$tl" != "" ]; then
              st=`echo "${st}" | sed -e "s/${ttype} *${tl}/${tl}/g"`
              doappend cchglist "-e 's/\([^a-zA-Z0-9_]\)${tl}\([^a-zA-Z0-9_]\)/\1${tlab}${tl}\2/g' "
              doappend cchglist "-e 's/^${tl}\([^a-zA-Z0-9_]\)/${tlab}${tl}\1/g' "
            fi
            domath inst "$inst + 1"
            ;;
          *"}"*)
            if [ $inst -ge 1 ]; then
              tnname=`echo ${tsline} | sed -e 's/.*}[ *]*\([^; ]*\) *;/\1/'`
              if [ "$tnname" != "" ]; then
                echo "###   tnname:${tnname}:" >&9
                doappend cchglist "-e 's/->${tnname}\././g' "
                doappend cchglist "-e 's/\.${tnname}\././g' "
                st=`echo "${st}" | sed -e "s/\}[ *]*${tnname} *;/};/"`
              fi
            fi
            domath inst "$inst - 1"
            ;;
          *)
            ;;
        esac
      # runs the 'while read' in the local shell, not a subshell.
      done << _HERE_
${st}
_HERE_

      ts=$s
      if [ "$stnm" = "" -a "$tdnm" != "$otdnm" ]; then
        ts=${s}_
      fi
      st=`(
          echo "${ctype} ${lab}${ts} ";
          echo "${st}"
          )`
      echo "#### modified ${ctype} (B)" >&9
      echo "${st}" >&9
      echo "#### end modified ${ctype} (B)" >&9

      # save this for possible later use (cmembertype, cmemberxdr)
      cmd="CST_${s}=\${st}"
      eval $cmd
      echo "   save: CST_${s}" >&9
    else
      trc=0
    fi

    if [ $trc -eq 1 ]; then
      if [ $ctype != enum ]; then
        # don't try to get size if there's no way to access the structure.
        # e.g. typedef struct { int a; } *b;
        if [ "$otdnm" = "" -o \
            \( "$tdnm" != "" -a "$otdnm" = "$tdnm" \) ]; then
          tstnm=$otdnm
          if [ "$tstnm" = "" ]; then
            tstnm="${ctype} ${stnm}"  # c language name
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
      fi
    else
      trc=0
    fi
  fi

  if [ $trc -eq 1 ]; then
    if [ "$stnm" != "" ]; then
      doappend cchglist "-e 's/\([^a-zA-Z0-9_]\)${ctype} *${stnm}\([^a-zA-Z0-9_]\)/\1${lab}${s}\2/g' "
      doappend cchglist "-e 's/^${ctype} *${stnm}\([^a-zA-Z0-9_]\)/${lab}${s}\1/g' "
    fi
    if [ $havetypedef = T -a "$otdnm" != "" ]; then
      doappend cchglist "-e 's/\([^a-zA-Z0-9_]\)${otdnm}\([^a-zA-Z0-9_]\)/\1${lab}${s}\2/g' "
      doappend cchglist "-e 's/^${otdnm}\([^a-zA-Z0-9_]\)/${lab}${s}\1/g' "
    fi
    doappend cstructs "
${st}
"
    if [ $havetypedef = T -a "$otdnm" != "" ]; then
      # if noprefix is on, don't alias some name to itself.
      if [ $noprefix = F -o ${s} != ${tdnm} ]; then
        doappend daliases "alias ${lab}${ts} ${tdnm};
"
      fi
    fi
    if [ $havetypedef = T -a "$otdnm" != "" -a \
        "$stnm" != "" -a "$stnm" != "$s" ]; then
      doappend daliases "alias ${lab}${ts} ${lab}${stnm};
"
    fi
    if [ $lab != enum -a $rval -gt 0 ]; then
      doappend dasserts "static assert ((${lab}${s}).sizeof == ${rval});
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
  checkcache ${_MKCONFIG_PREFIX} $name
  if [ $rc -eq 0 ]; then return; fi

  trc=0
  tdfile="${name}.d"
  > ${tdfile}
  exec 4>>${tdfile}
  dump_ccode >&4
  exec 4>&-
  code="void main (char[][] args) { C_ST_${struct} stmp; int i; i = stmp.${member}.sizeof; }"

  do_d_check_compile ${name} "${code}" all
}


check_cmembertype () {
  shift
  struct=$1
  shift
  member=$1

  nm="_cmembertype_${struct}_${member}"
  dosubst nm ' ' '_'
  name=$nm

  printlabel $name "member:type (C): ${struct} ${member}"
  # no cache

  trc=0
  cmd="st=\${CST_${struct}}"
  echo "   get: ${cmd}" >&9
  eval $cmd
  if [ "$st" != "" ]; then
    echo "  struct ${struct}: ${st}" >&9
    tmem=`echo "$st" | grep "${member} *;\$"`
    rc=$?
    echo "  found: ${tmem}" >&9
    if [ $rc -eq 0 ]; then
      mtype=`echo $tmem | sed -e "s/ *${member} *;$//" -e 's/^ *//'`
      echo "  type:${mtype}:" >&9
      echo "  member:${member}:" >&9
      trc=1
      if [ "${mtype}" != "" -a "${member}" != "" -a \( \
          $noprefix = F -o "${mtype}" != "${member}" \) ]; then
        doappend daliases "alias ${mtype} C_TYP_${member};
"
      fi
    fi
  fi

  printyesno $name $trc ""
  setdata ${_MKCONFIG_PREFIX} ${name} ${trc}
}


check_cmemberxdr () {
  shift
  struct=$1
  shift
  member=$1

  nm="_cmemberxdr_${struct}_${member}"
  dosubst nm ' ' '_'
  name=$nm

  printlabel $name "member:XDR (C): ${struct} ${member}"
  # no cache

  trc=0
  cmd="st=\${CST_${struct}}"
  echo "   get: ${cmd}" >&9
  eval $cmd
  if [ "$st" != "" ]; then
    echo "  struct ${struct}: ${st}" >&9
    tmem=`echo "$st" | grep "${member} *;\$"`
    rc=$?
    echo "  found: ${tmem}" >&9
    if [ $rc -eq 0 ]; then
      mtype=`echo $tmem | sed -e "s/ *${member} *;$//" -e 's/^ *//'`
      echo "  type: ${mtype}" >&9
      trc=1
      doappend daliases "alias xdr_${mtype} xdr_${member};
"
    fi
  fi

  printyesno $name $trc ""
  setdata ${_MKCONFIG_PREFIX} ${name} ${trc}
}


check_cdcl () {
  type=$1
  dname=$2
  argflag=0
  ccount=0
  noconst=F
  shift;shift
  if [ "$dname" = args ]; then
    argflag=1
    dname=$1
    shift
    if [ "$dname" = noconst ]; then
      noconst=T
      dname=$1
      shift
    fi
  fi

  nm="_cdcl_${dname}"
  name=$nm

  printlabel $name "c-dcl: ${dname}"
  # no cache

  trc=0

  oldprecc="${precc}"
  doappend precc "/* get rid of most gcc-isms */
/* keep __asm__ to check for function renames */
#define __attribute__(a)
#define __nonnull__(a,b)
#define __restrict
#define __THROW
#define __const const
"

  code=""
  _c_chk_cpp ${name} "/**/" all  # force no-reuse due to precc
  rc=$?

  if [ $rc -eq 0 ]; then
    egrep "[	 \*]${dname}[	 ]*\(" $name.out >/dev/null 2>&1
    rc=$?
    if [ $rc -eq 0 ]; then
      trc=1
    fi

    if [ $trc -eq 1 ]; then
      dcl=`${awkcmd} -f ${_MKCONFIG_DIR}/util/mkcextdcl.awk ${name}.out ${dname}`
      dcl=`echo $dcl`  # make single line.
      echo "## dcl(0): ${dcl}" >&9
      # extern will be replaced
      # ; may or may not be present, so remove it.
      cmd="dcl=\`echo \"\$dcl\" | sed -e 's/extern *//' -e 's/;//' \`"
      eval $cmd
      if [ $DVERSION -eq 1 ]; then
        dosubst dcl 'const' ''
      fi
      echo "## dcl(A): ${dcl}" >&9
      echo $dcl | grep __asm__ > /dev/null 2>&1
      rc=$?
      dclren=""
      if [ $rc -eq 0 ]; then
        dclren=`echo $dcl | sed -e 's/.*__asm__[ 	]*("" "\([a-z0-9A-Z_]*\)")/\1/'`
      fi
      echo "## dclren: ${dclren}" >&9
      if [ "$dclren" != "" ]; then
        doappend daliases "alias ${dclren} ${dname};
"
        cmd="dcl=\`echo \"\$dcl\" | \
            sed -e 's/[ 	]*__asm__[ 	]*([^)]*)[ 	]*//' \
            -e 's/\([ \*]\)${dname}\([ (]\)/\1${dclren}\2/' \`"
        eval $cmd
        echo "## dcl(B): ${dcl}" >&9
      fi
      cmd="dcl=\`echo \"\$dcl\" | sed -e 's/( *void *)/()/' \`"
      eval $cmd
      echo "## dcl(C): ${dcl}" >&9
      tdcl=$dcl
      modify_ctypes tdcl "${tdcl}"
      modify_cchglist tdcl "${tdcl}"    # need any struct renames for args
      echo "## tdcl(D): ${tdcl}" >&9
      if [ $argflag = 1 ]; then
        c=`echo ${tdcl} | sed 's/[^,]*//g'`
        ccount=`echo ${EN} "$c${EC}" | wc -c`
        domath ccount "$ccount + 1"  # 0==1 also, unfortunately
        c=`echo ${tdcl} | sed 's/^[^(]*(//'`
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
          nm="_c_arg_${val}_${dname}"
          setdata ${_MKCONFIG_PREFIX} ${nm} "${tmp}"
          case ${tmp} in
            struct*|union*|enum*)
              ;;
            *)
              doappend daliases "alias ${tmp} ${nm}_alias;
"
              ;;
          esac
          domath val "$val + 1"
          c=`echo ${c} | sed -e 's/^[^,]*//' -e 's/^[	 ,]*//'`
        done
        tname=${dclren:-$dname}
        echo "## tname(G): ${tname} ($dname - $dclren)" >&9
        c=`echo ${tdcl} | sed -e 's/[ 	]/ /g' \
            -e "s/\([ \*]\)${tname}[ (].*/\1/" \
            -e 's/^ *//' \
            -e 's/ *$//'`
        if [ $noconst = T ]; then
          c=`echo ${c} | sed -e 's/const *//'`
        fi
        nm="_c_type_${dname}"
        setdata ${_MKCONFIG_PREFIX} ${nm} "${c}"
      fi
      doappend cdcls " ${dcl};
"
    fi
  fi

  precc="${oldprecc}"

  printyesno $name $trc ""
  setdata ${_MKCONFIG_PREFIX} ${name} ${trc}
  if [ $argflag = 1 ]; then
    nm="_c_args_${dname}"
    setdata ${_MKCONFIG_PREFIX} ${nm} ${ccount}
  fi
}

check_module () {
  type=$1
  modname=$2

  printlabel $name "module:"
  printyesno_val $name $modname
}

check_noprefix () {
  name=$1
  noprefix=T

  printlabel $name "noprefix:"
  val=1
  printyesno $name $val
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
    _setstr_*|_opt_*|_c_arg_*|_c_type_*)
      tname=$name
      dosubst tname '_setstr_' '' '_opt_' ''
      _create_enum -o string ${tname} "${val}"
      ;;
    _setint_*|_csiz_*|_siz_*|_c_args_*|_ctype_*)
      tname=$name
      dosubst tname '_setint_' ''
      _create_enum -o int ${tname} ${val}
      ;;
    *)
      _create_enum -o bool ${name} "${tval}"
      ;;
  esac
}

new_output_file () {
  _init_var_lists
  return
}

# initialization

_init_var_lists
cchglist=""
cmpaths=""
noprefix=F

