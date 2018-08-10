#!/bin/sh
#
# Copyright 2010-2018 Brad Lanam Walnut Creek, CA, USA
#

setcflags () {
  CFLAGS=""
  doappend CFLAGS " ${CFLAGS_OPTIMIZE}"
  doappend CFLAGS " ${CFLAGS_DEBUG}"
  doappend CFLAGS " ${CFLAGS_INCLUDE}"
  doappend CFLAGS " ${CFLAGS_USER}"
  doappend CFLAGS " ${CFLAGS_APPLICATION}"
  doappend CFLAGS " ${CFLAGS_COMPILER}"
  doappend CFLAGS " ${CFLAGS_SYSTEM}"
  export CFLAGS
}

setldflags () {
  LDFLAGS=""
  doappend LDFLAGS " ${LDFLAGS_OPTIMIZE}"
  doappend LDFLAGS " ${LDFLAGS_DEBUG}"
  doappend LDFLAGS " ${LDFLAGS_USER}"
  doappend LDFLAGS " ${LDFLAGS_APPLICATION}"
  doappend LDFLAGS " ${LDFLAGS_COMPILER}"
  doappend LDFLAGS " ${LDFLAGS_SYSTEM}"
  export LDFLAGS
}

setlibs () {
  LIBS=""
  doappend LIBS " ${LDFLAGS_LIBS_USER}"
  doappend LIBS " ${LDFLAGS_LIBS_APPLICATION}"
  doappend LIBS " ${LDFLAGS_LIBS_SYSTEM}"
  export LIBS
}

