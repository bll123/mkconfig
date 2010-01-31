#!/bin/sh

../mkconfig.sh test_01.dat
diff -b test_01.expected config.h
rc=$?
echo "## config.h"
cat config.h
exit $rc

