#!/bin/sh
#
# $Id$
# $Source$
#
# Copyright 2001-2010 Brad Lanam, Walnut Creek, California, USA
#

require_unit env-main

check_objext () {
  name="$1"

  name=OBJ_EXT
  printlabel $name "extension: object"
  checkcache_val ${_MKCONFIG_PREFIX} $name
  if [ $rc -eq 0 ]; then return; fi

  TMP=objext

  CC=${CC:-cc}

  cat > $TMP.c << _HERE_
  #include <stdio.h>
  main ()
  {
    printf ("hello\n");
    return 0;
  }
_HERE_

  ${CC} ${CFLAGS} -c $TMP.c > /dev/null 2>&1 # don't care about warnings...
  OBJ_EXT=".o"
  if [ -f "$TMP.obj" ]; then
     echo "object extension is .obj" >> $LOG
     OBJ_EXT=".obj"
  else
     echo "object extension is .o" >> $LOG
  fi

  printyesno_val $name "${OBJ_EXT}"
  setdata ${_MKCONFIG_PREFIX} $name "${OBJ_EXT}"
}

check_exeext () {
  name="$1"

  name=EXE_EXT
  printlabel $name "extension: executable"
  checkcache_val ${_MKCONFIG_PREFIX} $name
  if [ $rc -eq 0 ]; then return; fi

  TMP=exeext

  CC=${CC:-cc}

  cat > $TMP.c << _HERE_
  #include <stdio.h>
  main ()
  {
    printf ("hello\n");
    return 0;
  }
_HERE_

  ${CC} ${CFLAGS} -o $TMP $TMP.c > /dev/null 2>&1 # don't care about warnings
  EXE_EXT=""
  if [ -f "$TMP.exe" ]
  then
     echo "executable extension is .exe" >> $LOG
     EXE_EXT=".exe"
  else
     echo "executable extension is none" >> $LOG
  fi

  printyesno_val $name "${EXE_EXT}"
  setdata ${_MKCONFIG_PREFIX} $name "${EXE_EXT}"
}

