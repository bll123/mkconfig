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

_MKCONFIG_PREFIX=d
_MKCONFIG_HASEMPTY=F
_MKCONFIG_EXPORT=F
PH_PREFIX="mkc_ph."
PH_STD=F
PH_ALL=F

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

  check_import import "std.stdio"
  check_import import "std.string"
}

_print_imports () {
  imports=$1

  out="${PH_PREFIX}${imports}"

  if [ -f $out ]; then
    cat $out
    return
  fi

  if [ "$PH_STD" = "T" -a "$imports" = "std" ]; then
    _print_imps std > $out
    cat $out
    return
  fi

  if [ "$PH_ALL" = "T" -a "$imports" = "all" ]; then
    _print_imps all > $out
    cat $out
    return
  fi

  # until PH_STD/PH_ALL becomes true, just do normal processing.
  _print_imps $imports
}

_print_imps () {
  imports=$1

  if [ "${imports}" = "all" -o "${imports}" = "std" ]; then
      for tnm in '_import_std_stdio' '_import_std_string'; do
          getdata tval ${_MKCONFIG_PREFIX} ${tnm}
          if [ "${tval}" != "0" -a "${tval}" != "" ]; then
              echo "import ${tval};"
          fi
      done
  fi

  if [ "${imports}" = "all" -a -f "$VARSFILE" ]; then
    # save stdin in fd 6; open stdin
    exec 6<&0 < ${VARSFILE}
    while read cfgvar; do
      getdata hdval ${_MKCONFIG_PREFIX} ${cfgvar}
      case ${cfgvar} in
        _import_std_stdio|_import_std_string)
            ;;
        _import_*)
            if [ "${hdval}" != "0" -a "${hdval}" != "" ]; then
              echo "import ${hdval};"
            fi
            ;;
      esac
    done
    # set std to saved fd 6; close 6
    exec <&6 6<&-
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
  clotherlibs="'$otherlibs'"
  dosubst clotherlibs ',' "' '"
  if [ "${clotherlibs}" != "" ]; then
      eval "set -- $clotherlibs"
      ocount=$#
  else
      ocount=0
  fi

  tdfile=${cllname}.d
  # $cllname should be unique
  exec 4>>${tdfile}
  _print_imports $inc >&4
  echo "${code}" | sed 's/_dollar_/$/g' >&4
  exec 4>&-

  dlibs=""
  otherlibs=""
  _chk_link $cllname
  rc=$?
  echo "##      link test (none): $rc" >&9
  if [ $rc -ne 0 ]; then
      while test $ocounter -lt $ocount; do
          domath ocounter "$ocounter + 1"
          eval "set -- $clotherlibs"
          cmd="olibs=\$${ocounter}"
          eval $cmd
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

  DC_OF="-o"
  case ${DC} in 
    *dmd)
      DC_OF="-of"
      ;;
  esac

  cmd="${DC} ${DFLAGS} ${DC_OF}${clname}.exe ${clname}.d "
  cmd="${cmd} ${LDFLAGS} ${LIBS} "

  _clotherlibs=$otherlibs
  if [ "${_clotherlibs}" != "" ]; then
      cmd="${cmd} ${_clotherlibs} "
  fi
  echo "##  _link test: $cmd" >&9
  cat ${clname}.d >&9
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
  dfname=$1
  code=$2
  inc=$3

  tdfile=${dfname}.d
  # $dfname should be unique
  exec 4>>${tdfile}
  _print_imports $inc >&4
  echo "${code}" | sed 's/_dollar_/$/g' >&4
  exec 4>&-

  cmd="${DC} ${DFLAGS} -c ${tdfile}"
  echo "##  compile test: $cmd" >&9
  cat ${dfname}.d >&9
  eval ${cmd} >&9 2>&9
  rc=$?
  echo "##  compile test: $rc" >&9
  return $rc
}


do_check_compile () {
  ddfname=$1
  code=$2
  inc=$3

  _chk_compile ${ddfname} "${code}" $inc
  rc=$?
  try=0
  if [ $rc -eq 0 ]; then
      try=1
  fi
  printyesno $ddfname $try
  setdata ${_MKCONFIG_PREFIX} ${ddfname} ${try}
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
          doappend code "
import $1;
"
          shift
      done
  fi
  doappend code "
import $file;
int main (char[][] args) { return 0; }
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

  code="void main (char[][] args) { ${struct} s; int i; i = s.${member}.sizeof; }"

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

  code="import std.stdio; void main (char[][] args){ writef(\"%d\", ${type}.sizeof); }"
  _chk_run ${name} "${code}" all
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
  # unfortunately, this does not work if the function
  # is not declared.
  code="
CPP_EXTERNS_BEG
typedef int (*_TEST_fun_)();
static _TEST_fun_ i=(_TEST_fun_) ${func};
CPP_EXTERNS_END
int main (char[][] args) {  i(); return (i==0); }
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
    cmd="di_${_MKCONFIG_PREFIX}_lib_${name}=\"${dlibs}\""
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
  int main (char[][] args) {  i(); return (i==0); }
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
      cmd="di_${_MKCONFIG_PREFIX}_lib_${name}=\"${dlibs}\""
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
  code="void main (char[][] args) { ${class} testclass; } "

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
    cmd="di_${_MKCONFIG_PREFIX}_lib_${name}=\"${dlibs}\""
    eval $cmd
  fi
  printyesno $name $trc "$tag"
  setdata ${_MKCONFIG_PREFIX} ${name} ${trc}
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
    _setint_*|_siz_*)
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
    _imp*|_command*)
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
