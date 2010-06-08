#!/bin/sh
#
# Copyright 2010 Brad Lanam Walnut Creek CA USA
#
#
# check and see if there is a conflict between include files.
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

require_unit c-main

_prefix_header () {
  nm=$1
  val=$2
  case $val in
    sys*)
      eval "$nm=_${val}"
      ;;
    *)
      eval "$nm=_hdr_${val}"
      ;;
  esac
}

check_include_conflict () {
    i1=$2
    i2=$3

    if [ "${CC}" = "" ]; then
      echo "No compiler specified" >&2
      return
    fi

    oi1=$i1
    dosubst i1 '/' '_' ':' '_' '\.h' ''
    _prefix_header i1 $i1
    oi2=$i2
    dosubst i2 '/' '_' ':' '_' '\.h' ''
    _prefix_header i2 $i2

    name="_inc_conflict_${i1}_${i2}"

    # by default, ok to include both
    # if one or the other does not exist, the flag will be true.
    # if it compiles ok with both, the flag will be true.
    trc=1

    printlabel $name "header: include both ${oi1} & ${oi2}"

    getdata h1 ${_MKCONFIG_PREFIX} $i1
    getdata h2 ${_MKCONFIG_PREFIX} $i2
    if [ "${h1}" != "0" -a "${h2}" != "0" ]; then
      checkcache ${_MKCONFIG_PREFIX} $name
      if [ $rc -eq 0 ]; then return; fi

      code="#include <${h1}>
#include <${h2}>
main () { return; }
"
      do_check_compile "${name}" "${code}" std
    else
      setdata ${_MKCONFIG_PREFIX} "${name}" "${trc}"
      printyesno "${name}" $trc ""
    fi
}
