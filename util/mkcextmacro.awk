#!/usr/bin/awk

BEGIN {
  macrostart = "^#[ 	]*define[ 	]*" ARGV[2]
  delete ARGV[2];
  ins = 0;
  doend = 0;
#print "macrostart:" macrostart;
}

{
  if (ins == 0 && $0 ~ macrostart) {
#print "start: " $0;
    ins = 1;
    tstr = $0;
    doend = 1;
    if ($0 ~ /\\$/) {
      doend = 0;
    }
  } else if (ins == 1 && $0 ~ /\\$/) {
#print "cont: " $0;
    tstr = tstr + $0;
  } else if (ins == 1) {
    doend = 1;
  }

  if (doend == 1) {
    print tstr;
    exit;
  }
}
