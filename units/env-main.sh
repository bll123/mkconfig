#!/bin/sh
#
# Copyright 2010-2018 Brad Lanam Walnut Creek CA USA
# Copyright 2020 Brad Lanam Pleasant Hill CA
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

  puts "#!/bin/sh"
  puts "# Created on: `date`"
  puts "#  From: ${configfile}"
  puts "#  Using: mkconfig-${_MKCONFIG_VERSION}"
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

  tfn=$fn
  dosubst tfn '.*/' '' '\.' '' '-' ''
  name=_${nm}_${tfn}

  printlabel $nm "source: $fn"

  trc=0
  val=0
  if [ -f $fn ]; then
    trc=1
    val=$fn
  fi
  printyesno $name $trc
  setdata ${_MKCONFIG_PREFIX} ${name} $val
}

output_item () {
  out=$1
  name=$2
  val=$3

  case $name in
    _source_*)
      if [ $val != "0" ]; then
        puts ". ${val}"
      fi
      ;;
    _setint*|_setstr*|_opt_*)
      tname=$name
      dosubst tname '_setint_' '' '_setstr_' '' '_opt_' ''
      puts "${tname}=\"${val}\""
      puts "export ${tname}"
      ;;

    *)
      puts "${name}=\"${val}\""
      puts "export ${name}"
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
