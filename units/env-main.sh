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

  echo "${name}=\"${val}\""
  echo "export ${name}"
}

output_other () {
  return
}

