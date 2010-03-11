#!/bin/sh
#
# $Id$
# $Source$
#
# Copyright 2001-2010 Brad Lanam, Walnut Creek, California, USA
#

TMP=objext$$

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
   echo "object extension is .obj" >&2
   OBJ_EXT=".obj"
else
   echo "object extension is .o" >&2
fi
rm -f $TMP.o $TMP.obj a.out > /dev/null 2>&1

${CC} ${CFLAGS} -o $TMP $TMP.c > /dev/null 2>&1 # don't care about warnings...
EXE_EXT=""
if [ -f "$TMP.exe" ]
then
   echo "executable extension is .exe" >&2
   EXE_EXT=".exe"
else
   echo "executable extension is none" >&2
fi
rm -f $TMP.c $TMP.o $TMP.obj $TMP $TMP.exe a.out > /dev/null 2>&1

echo "OBJ_EXT=${OBJ_EXT}"
echo "export OBJ_EXT"
echo "EXE_EXT=${EXE_EXT}"
echo "export EXE_EXT"
