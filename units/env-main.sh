#!/bin/sh
#
# Copyright 2010 Brad Lanam Walnut Creek CA USA
#
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

  echo "${name}=\"${val}\"" >> ${out}
  echo "export ${name}" >> ${out}
}

output_other () {
  return
}

