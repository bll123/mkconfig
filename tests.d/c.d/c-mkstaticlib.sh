#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " create static library${EC}"
  exit 0
fi

stag=$1
shift
script=$@

for i in 1 2 3 4; do
  > t${i}.c echo <<_HERE_
#include <stdio.h>
#include <stdlib.h>

t${i} () { return ${i}; }
_HERE_

  ${CC} -c t${i}.c
done

i=5
  > t${i}.c echo <<_HERE_
#include <stdio.h>
#include <stdlib.h>

t${i} () { t1(); t2(); t3(); t4(); return ${i}; }
_HERE_

${CC} -c t${i}.c

grc=0
${_MKCONFIG_DIR}/mkstaticlib.sh t t[51234].o
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

ar t libt.a
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

exit $rc
