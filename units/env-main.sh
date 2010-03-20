#!/bin/sh
#
# Copyright 2010 Brad Lanam Walnut Creek CA USA
#
#

#
# speed at the cost of maintainability...
# File Descriptors:
#    9 - >>$LOG
#    8 - >>$VARSFILE
#    7 - temporary for mkconfig.sh
#    6 - >>$CONFH
#    5 - temporary for c-main.sh
#

_MKCONFIG_PREFIX=env
_MKCONFIG_HASEMPTY=T
_MKCONFIG_EXPORT=T

preconfigfile () {
  pc_configfile=$1
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

output_item () {
  out=$1
  name=$2
  val=$3

  echo "${name}=\"${val}\"" >&6
  echo "export ${name}" >&6
}

output_other () {
  return
}

