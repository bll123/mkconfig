#!/bin/sh

script=$@

echo ${EN} "cache${EC}" >&3
eval "${script} -C $RUNTESTDIR/cache.dat"
mv -f cache.ctest cache.a
mv -f mkconfig_c.vars cache.a.vars
eval "${script} $RUNTESTDIR/cache.dat"
mv -f cache.ctest cache.b
mv -f mkconfig_c.vars cache.b.vars
grc=0
echo "## diff config.h"
diff -b cache.a cache.b
if [ $? -ne 0 ]; then grc=$rc; fi
echo "## diff vars"
diff -b cache.a.vars cache.b.vars
if [ $? -ne 0 ]; then grc=$rc; fi
exit $grc

