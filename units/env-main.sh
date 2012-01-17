#!/bin/sh
#
# Copyright 2010 Brad Lanam Walnut Creek CA USA
#
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

_MKCONFIG_PREFIX=env
_MKCONFIG_HASEMPTY=T
_MKCONFIG_EXPORT=T

preconfigfile () {
  pc_configfile=$1
  configfile=$2

  echo "# Created on: `date`"
  echo "#  From: ${configfile}"
  echo "#  Using: mkconfig-${_MKCONFIG_VERSION}"
  return
}

stdconfigfile () {
  pc_configfile=$1
  return
}

postconfigfile () {
  pc_configfile=$1
  return
}

standard_checks () {
  return
}

check_source () {
  nm=$1
  fn=$2
  name=_${1}_${2}
  dosubst name '/' '' '\.' ''

  printlabel $nm "source: $fn"

  trc=0
  if [ -f $fn ]; then
    trc=1
  fi
  printyesno $name $trc
  setdata ${_MKCONFIG_PREFIX} ${name} $fn
}

output_item () {
  out=$1
  name=$2
  val=$3

  case $name in
    _source_*)
      echo ". ${val}"
      ;;
    _setint*|_setstr*|_opt_*)
      tname=$name
      dosubst tname '_setint_' '' '_setstr_' '' '_opt_' ''
      echo "${tname}=\"${val}\""
      echo "export ${tname}"
      ;;

    *)
      echo "${name}=\"${val}\""
      echo "export ${name}"
      ;;
  esac
}

check_test_multword () {
  name=$1

  printlabel $name "test: multiword"
  checkcache_val ${_MKCONFIG_PREFIX} $name
  if [ $? -eq 0 ]; then return; fi
  val="word1 word2"
  printyesno_val $name "$val"
  setdata ${_MKCONFIG_PREFIX} $name "$val"
}

new_output_file () {
  return 0
}
