#!/bin/sh
#
# Copyright 2010 Brad Lanam Walnut Creek CA USA
#
#

_c_print_headers () {
  incheaders=$1

  out="${PH_PREFIX}${incheaders}"

  if [ -f $out ]; then
    cat $out
    return
  fi

  if [ "$PH_STD" = "T" -a "$incheaders" = "std" ]; then
    _c_print_hdrs std > $out
    cat $out
    return
  fi

  if [ "$PH_ALL" = "T" -a "$incheaders" = "all" ]; then
    _c_print_hdrs all > $out
    cat $out
    return
  fi

  # until PH_STD/PH_ALL becomes true, just do normal processing.
  _c_print_hdrs $incheaders
}

_c_print_hdrs () {
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
    # save stdin in fd 6; open stdin
    exec 6<&0 < ${VARSFILE}
    while read cfgvar; do
      getdata hdval ${_MKCONFIG_PREFIX} ${cfgvar}
      case ${cfgvar} in
        _hdr_stdio|_hdr_stdlib|_sys_types|_sys_param)
          ;;
        _hdr_linux_quota)
          if [ "${hdval}" != "0" ]; then
            getdata iqval ${_MKCONFIG_PREFIX} '_inc_conflict__sys_quota__hdr_linux_quota'
            if [ "${iqval}" = "1" ]; then
              echo "#include <${hdval}>"
            fi
          fi
          ;;
        _sys_time)
          if [ "${hdval}" != "0" ]; then
            getdata itval ${_MKCONFIG_PREFIX} '_inc_conflict__hdr_time__sys_time'
            if [ "${itval}" = "1" ]; then
              echo "#include <${hdval}>"
            fi
          fi
          ;;
        _hdr_*|_sys_*)
          if [ "${hdval}" != "0" -a "${hdval}" != "" ]; then
            echo "#include <${hdval}>"
          fi
          ;;
      esac
    done
    # set std to saved fd 6; close 6
    exec <&6 6<&-
  fi
}

_c_chk_run () {
  crname=$1
  code=$2
  inc=$3

  _c_chk_link_libs ${crname} "${code}" $inc
  rc=$?
  echo "##  run test: link: $rc" >&9
  rval=0
  if [ $rc -eq 0 ]; then
    rval=`./${crname}.exe`
    rc=$?
    echo "##  run test: run: $rc retval:$rval" >&9
    if [ $rc -lt 0 ]; then
      _exitmkconfig $rc
    fi
  fi
  _retval=$rval
  return $rc
}

_c_chk_link_libs () {
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

  tcfile=${cllname}.c
  # $cllname should be unique
  exec 4>>${tcfile}
  echo "${precc}" >&4
  _c_print_headers $inc >&4
  echo "${code}" | sed 's/_dollar_/$/g' >&4
  exec 4>&-

  dlibs=""
  otherlibs=""
  _c_chk_link $cllname
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
      _c_chk_link $cllname
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

_c_chk_cpp () {
  cppname=$1
  code="$2"
  inc=$3

  tcppfile=${cppname}.c
  # $cppname should be unique
  exec 4>>${tcppfile}
  echo "${precc}" >&4
  _c_print_headers $inc >&4
  echo "${code}" | sed 's/_dollar_/$/g' >&4
  exec 4>&-

  cmd="${CC} ${CFLAGS} ${CPPFLAGS} -E ${cppname}.c > ${cppname}.out "
  echo "##  _cpp test: $cmd" >&9
  cat ${cppname}.c >&9
  eval $cmd >&9 2>&9
  rc=$?
  if [ $rc -lt 0 ]; then
    _exitmkconfig $rc
  fi
  echo "##      _cpp test: $rc" >&9
  return $rc
}

_c_chk_link () {
  clname=$1

  cmd="${CC} ${CFLAGS} ${CPPFLAGS} -o ${clname}.exe ${clname}.c "
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
    _exitmkconfig $rc
  fi
  echo "##      _link test: $rc" >&9
  if [ $rc -eq 0 ]; then
    if [ ! -x "${clname}.exe" ]; then  # not executable
      rc=1
    fi
  fi
  return $rc
}


_c_chk_compile () {
  ccname=$1
  code=$2
  inc=$3

  tcfile=${ccname}.c
  # $ccname should be unique
  exec 4>>${tcfile}
  echo "${precc}" >&4
  _c_print_headers $inc >&4
  echo "${code}" | sed 's/_dollar_/$/g' >&4
  exec 4>&-

  cmd="${CC} ${CFLAGS} ${CPPFLAGS} -c ${tcfile}"
  echo "##  compile test: $cmd" >&9
  cat ${ccname}.c >&9
  eval ${cmd} >&9 2>&9
  rc=$?
  echo "##  compile test: $rc" >&9
  return $rc
}


do_c_check_compile () {
  dccname=$1
  code=$2
  inc=$3

  _c_chk_compile ${dccname} "${code}" $inc
  rc=$?
  try=0
  if [ $rc -eq 0 ]; then
    try=1
  fi
  printyesno $dccname $try
  setdata ${_MKCONFIG_PREFIX} ${dccname} ${try}
}

